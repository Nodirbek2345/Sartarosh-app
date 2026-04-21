"use client";
import { useState, useEffect } from "react";
import { FaSearch, FaUserAlt, FaPhoneAlt, FaVenusMars, FaSpinner, FaTrash, FaFileCsv } from "react-icons/fa";
import { onUsersSnapshot, deleteUser } from "@/lib/firestore";
import toast from "react-hot-toast";

export default function ClientsPage() {
    const [clients, setClients] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState("");
    const [filterGender, setFilterGender] = useState("all");

    useEffect(() => {
        const unsubscribe = onUsersSnapshot((data) => {
            // Firestore'dagi users kolleksiyasini yuklaymiz
            setClients(data);
            setLoading(false);
        });
        return () => unsubscribe();
    }, []);

    const handleDelete = async (id, name) => {
        if (!window.confirm(`${name} isimli foydalanuvchini rostdan ham o'chirib tashlamoqchimisiz?`)) return;
        try {
            await deleteUser(id);
            toast.success(`${name} muvaffaqiyatli o'chirildi!`, { icon: "✅" });
        } catch (error) {
            console.error("Xatolik:", error);
            toast.error("O'chirishda xatolik yuz berdi", { icon: "❌" });
        }
    };

    // Filterlash: ism, telefon raqam va jins bo'yicha
    const filtered = clients.filter((client) => {
        const query = search.toLowerCase();
        const matchesSearch =
            (client.firstName?.toLowerCase() || "").includes(query) ||
            (client.name?.toLowerCase() || "").includes(query) ||
            (client.phone || "").includes(query);

        let matchesGender = true;
        if (filterGender !== "all") {
            matchesGender = client.gender === filterGender;
        }

        return matchesSearch && matchesGender;
    });

    const exportToCSV = () => {
        if (filtered.length === 0) {
            toast.error("Eksport qilish uchun ma'lumot yo'q!");
            return;
        }

        const headers = ["Ism", "Telefon", "Jinsi", "Ro'yxatdan o'tgan sana", "Rol"];
        const csvRows = [headers.join(",")];

        for (const client of filtered) {
            const name = (client.firstName || client.name || "Ismsiz mijoz").replace(/,/g, " ");
            const phone = client.phone || "";
            const gender = client.gender === "female" ? "Ayol" : (client.gender === "male" ? "Erkak" : "Noma'lum");

            let date = "Noma'lum";
            if (client.createdAt) {
                const d = client.createdAt.toDate ? client.createdAt.toDate() : new Date(client.createdAt.seconds * 1000);
                date = d.toLocaleDateString('uz-UZ');
            }

            const role = client.role === "barber" ? "Sartarosh" : "Mijoz";

            csvRows.push(`${name},${phone},${gender},${date},${role}`);
        }

        const csvContent = "data:text/csv;charset=utf-8," + "\uFEFF" + csvRows.join("\n");
        const encodedUri = encodeURI(csvContent);
        const link = document.createElement("a");
        link.setAttribute("href", encodedUri);
        link.setAttribute("download", `Sartarosh_Mijozlar_${new Date().toISOString().split('T')[0]}.csv`);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        toast.success("CSV fayl yuklab olindi!");
    };

    if (loading) {
        return (
            <div style={{ textAlign: "center", padding: 60, color: "#94A3B8" }}>
                <FaSpinner size={32} className="animate-spin" style={{ margin: "0 auto 16px" }} />
                <p>Mijozlar ro'yxati yuklanmoqda...</p>
            </div>
        );
    }

    return (
        <div>
            {/* Top bar */}
            <div className="dashboard-topbar">
                <div>
                    <h1>Mijozlar</h1>
                    <p style={{ color: "#94A3B8", fontSize: 14, margin: "4px 0 0" }}>
                        Jami {clients.length} nafar ro'yxatdan o'tgan foydalanuvchi
                    </p>
                </div>

                {/* Qidiruv va Filtr */}
                <div style={{ display: "flex", gap: "12px", alignItems: "center", flexWrap: "wrap" }}>
                    {/* Jins filteri */}
                    <div style={{ display: "flex", background: "#F1F5F9", borderRadius: "10px", padding: "4px" }}>
                        <button
                            onClick={() => setFilterGender("all")}
                            style={{
                                padding: "8px 16px", borderRadius: "8px", border: "none", fontSize: "14px", fontWeight: "600", cursor: "pointer",
                                background: filterGender === "all" ? "white" : "transparent",
                                color: filterGender === "all" ? "#3B82F6" : "#64748B",
                                boxShadow: filterGender === "all" ? "0 1px 3px rgba(0,0,0,0.1)" : "none"
                            }}
                        >Barchasi</button>
                        <button
                            onClick={() => setFilterGender("male")}
                            style={{
                                padding: "8px 16px", borderRadius: "8px", border: "none", fontSize: "14px", fontWeight: "600", cursor: "pointer",
                                background: filterGender === "male" ? "white" : "transparent",
                                color: filterGender === "male" ? "#D4A853" : "#64748B",
                                boxShadow: filterGender === "male" ? "0 1px 3px rgba(0,0,0,0.1)" : "none"
                            }}
                        >Erkaklar</button>
                        <button
                            onClick={() => setFilterGender("female")}
                            style={{
                                padding: "8px 16px", borderRadius: "8px", border: "none", fontSize: "14px", fontWeight: "600", cursor: "pointer",
                                background: filterGender === "female" ? "white" : "transparent",
                                color: filterGender === "female" ? "#D63384" : "#64748B",
                                boxShadow: filterGender === "female" ? "0 1px 3px rgba(0,0,0,0.1)" : "none"
                            }}
                        >Ayollar</button>
                    </div>

                    <div className="dashboard-search">
                        <FaSearch className="search-icon" />
                        <input
                            placeholder="Ism yoki telefon qidirish..."
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                    </div>

                    {/* Excel/CSV Export Button */}
                    <button
                        onClick={exportToCSV}
                        style={{
                            display: "flex", alignItems: "center", gap: "8px",
                            background: "#10B981", color: "white", border: "none",
                            padding: "8px 16px", borderRadius: "10px", fontWeight: "600",
                            cursor: "pointer", fontSize: "14px", height: "42px",
                            boxShadow: "0 2px 4px rgba(16, 185, 129, 0.2)"
                        }}
                    >
                        <FaFileCsv size={18} /> Export
                    </button>
                </div>
            </div>

            {/* List View */}
            <div className="dash-card">
                <div style={{ overflowX: "auto" }}>
                    <table className="dash-table" style={{ width: "100%" }}>
                        <thead>
                            <tr>
                                <th>Mijoz</th>
                                <th>Telefon raqam</th>
                                <th>Jinsi</th>
                                <th>Ro'yxatdan o'tgan sana</th>
                                <th>Rol</th>
                                <th>Amallar</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filtered.length > 0 ? filtered.map((client) => {
                                const displayName = client.firstName || client.name || "Ismsiz mijoz";
                                const isFemale = client.gender === "female";
                                const isMale = client.gender === "male";

                                // Sana formatlash
                                let joinedDate = "—";
                                if (client.createdAt) {
                                    // Timestamp object from Firebase
                                    const date = client.createdAt.toDate ? client.createdAt.toDate() : new Date(client.createdAt.seconds * 1000);
                                    joinedDate = new Intl.DateTimeFormat('uz-UZ', { day: 'numeric', month: 'long', year: 'numeric' }).format(date);
                                }

                                return (
                                    <tr key={client.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                                        <td style={{ padding: "16px" }}>
                                            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                                                <div style={{
                                                    width: 40, height: 40, borderRadius: "50%",
                                                    background: isFemale ? "#FFF0F5" : (isMale ? "#F8F5F0" : "#F1F5F9"),
                                                    display: "flex", alignItems: "center", justifyContent: "center",
                                                    color: isFemale ? "#D63384" : (isMale ? "#D4A853" : "#94A3B8"),
                                                    fontSize: 16
                                                }}>
                                                    {client.avatar ? (
                                                        <img src={`data:image/jpeg;base64,${client.avatar}`} alt="Avatar" style={{ width: 40, height: 40, borderRadius: "50%", objectFit: "cover" }} />
                                                    ) : (
                                                        <FaUserAlt />
                                                    )}
                                                </div>
                                                <span style={{ fontWeight: 600, color: "#1E293B" }}>{displayName}</span>
                                            </div>
                                        </td>
                                        <td style={{ padding: "16px", color: "#475569" }}>
                                            <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                                                <FaPhoneAlt size={12} color="#94A3B8" /> {client.phone || "Kiritilmagan"}
                                            </div>
                                        </td>
                                        <td style={{ padding: "16px" }}>
                                            {isFemale ? (
                                                <span style={{ color: '#D63384', background: '#FFF0F5', padding: '4px 10px', borderRadius: 6, fontSize: 13, fontWeight: 600 }}>Ayol</span>
                                            ) : isMale ? (
                                                <span style={{ color: '#D4A853', background: '#F8F5F0', padding: '4px 10px', borderRadius: 6, fontSize: 13, fontWeight: 600 }}>Erkak</span>
                                            ) : (
                                                <span style={{ color: '#94A3B8', fontSize: 13 }}>Noma'lum</span>
                                            )}
                                        </td>
                                        <td style={{ padding: "16px", color: "#64748B", fontSize: 14 }}>
                                            {joinedDate}
                                        </td>
                                        <td style={{ padding: "16px" }}>
                                            {client.role === 'barber' ? (
                                                <span style={{ color: '#059669', background: '#D1FAE5', padding: '4px 10px', borderRadius: 6, fontSize: 13, fontWeight: 600 }}>Sartarosh</span>
                                            ) : (
                                                <span style={{ color: '#3B82F6', background: '#DBEAFE', padding: '4px 10px', borderRadius: 6, fontSize: 13, fontWeight: 600 }}>Mijoz</span>
                                            )}
                                        </td>
                                        <td style={{ padding: "16px" }}>
                                            <button
                                                onClick={() => handleDelete(client.id, displayName)}
                                                style={{ background: "#FEE2E2", color: "#DC2626", border: "none", padding: "8px 12px", borderRadius: 8, cursor: "pointer", fontSize: 13, fontWeight: "600", display: "flex", alignItems: "center", gap: "6px" }}>
                                                <FaTrash size={12} /> O'chirish
                                            </button>
                                        </td>
                                    </tr>
                                );
                            }) : (
                                <tr>
                                    <td colSpan={6} style={{ textAlign: "center", padding: "40px", color: "#94A3B8" }}>
                                        Hech qanday ma'lumot topilmadi...
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

        </div>
    );
}
