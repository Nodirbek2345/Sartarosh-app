"use client";
import { useState, useEffect } from "react";
import { FaStar, FaSearch, FaPhone, FaTh, FaList, FaCut, FaSpinner, FaPowerOff, FaCheckCircle, FaEdit, FaTrash } from "react-icons/fa";
import { onBarbersSnapshot, onBookingsSnapshot, formatPrice, deleteBarber } from "@/lib/firestore";
import toast from "react-hot-toast";

const categories = [
    { key: "all", label: "Hammasi" },
    { key: "erkaklar", label: "Erkaklar" },
    { key: "ayollar", label: "Ayollar" },
    { key: "premium", label: "Premium" },
    { key: "vip", label: "VIP" },
    { key: "top", label: "Top Rated" },
    { key: "arzon", label: "Arzon" },
    { key: "kreativ", label: "Kreativ" },
];

const tagColors = {
    "Premium": { bg: "#DBEAFE", color: "#2563EB" },
    "Top Rated": { bg: "#DCFCE7", color: "#16A34A" },
    "VIP": { bg: "#FEF3C7", color: "#D97706" },
    "Arzon": { bg: "#E0E7FF", color: "#4F46E5" },
    "Kreativ": { bg: "#FCE7F3", color: "#DB2777" },
    "Zamonaviy": { bg: "#CFFAFE", color: "#0891B2" },
    "Tajribali": { bg: "#FEF3C7", color: "#D97706" },
    "Mashhur": { bg: "#FEE2E2", color: "#DC2626" },
    "Yosh usta": { bg: "#E0E7FF", color: "#4F46E5" },
    "Yangi": { bg: "#DCFCE7", color: "#16A34A" },
};

export default function BarbersPage() {
    const [barbers, setBarbers] = useState([]);
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState("");
    const [activeCategory, setActiveCategory] = useState("all");
    const [selectedBarber, setSelectedBarber] = useState(null);
    const [view, setView] = useState("grid");

    const openEditModal = (barber) => {
        toast("Tahrirlash menyusi tez orada ishga tushadi", { icon: "🚧" });
    };

    const handleDelete = async (id, name) => {
        if (!window.confirm(`${name} ismli sartaroshni rostdan ham o'chirib tashlamoqchimisiz?`)) return;
        try {
            await deleteBarber(id);
            toast.success(`${name} muvaffaqiyatli o'chirildi!`, { icon: "✅" });
        } catch (error) {
            console.error("Xatolik:", error);
            toast.error("O'chirishda xatolik yuz berdi", { icon: "❌" });
        }
    };

    useEffect(() => {
        let itemsLoaded = 0;
        const checkDone = () => { if (++itemsLoaded === 2) setLoading(false); };

        const unsub1 = onBarbersSnapshot((data) => {
            setBarbers(data);
            checkDone();
        });
        const unsub2 = onBookingsSnapshot((data) => {
            setBookings(data);
            checkDone();
        });
        return () => { unsub1(); unsub2(); };
    }, []);

    const filtered = barbers.filter((b) => {
        const matchSearch =
            b.name?.toLowerCase().includes(search.toLowerCase()) ||
            b.address?.toLowerCase().includes(search.toLowerCase());

        if (activeCategory === "all") return matchSearch;

        if (activeCategory === "erkaklar") return matchSearch && b.gender === "male";
        if (activeCategory === "ayollar") return matchSearch && b.gender === "female";

        return matchSearch && b.tags?.some((t) => t.toLowerCase().includes(activeCategory));
    });

    if (loading) {
        return (
            <div style={{ textAlign: "center", padding: 60, color: "#94A3B8" }}>
                <FaSpinner size={32} className="animate-spin" style={{ margin: "0 auto 16px" }} />
                <p>Yuklanmoqda...</p>
            </div>
        );
    }

    return (
        <div>
            {/* Top bar */}
            <div className="dashboard-topbar">
                <div>
                    <h1>Sartaroshlar</h1>
                    <p style={{ color: "#94A3B8", fontSize: 14, marginTop: 2 }}>
                        Jami {barbers.length} ta sartarosh
                    </p>
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <div className="dashboard-search">
                        <FaSearch className="search-icon" />
                        <input
                            placeholder="Sartarosh qidirish..."
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                    </div>

                    <div className="view-toggle">
                        <button className={view === "grid" ? "active" : ""} onClick={() => setView("grid")}>
                            <FaTh />
                        </button>
                        <button className={view === "list" ? "active" : ""} onClick={() => setView("list")}>
                            <FaList />
                        </button>
                    </div>
                </div>
            </div>

            {/* Category filters */}
            <div className="filter-pills">
                {categories.map((cat) => (
                    <button
                        key={cat.key}
                        className={`filter-pill ${activeCategory === cat.key ? "active" : ""}`}
                        onClick={() => setActiveCategory(cat.key)}
                    >
                        {cat.label}
                    </button>
                ))}
            </div>

            <div style={{ display: "flex", gap: 24 }}>
                {/* Main grid/list */}
                <div style={{ flex: 1 }}>
                    {view === "grid" ? (
                        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(220px, 1fr))", gap: 20 }}>
                            {filtered.map((barber) => (
                                <div
                                    key={barber.id}
                                    className="barber-grid-card"
                                    onClick={() => setSelectedBarber(barber)}
                                    style={{ borderColor: selectedBarber?.id === barber.id ? "#3B82F6" : undefined }}
                                >
                                    <div className="barber-avatar">
                                        <FaCut />
                                        <div className="barber-rating">
                                            <FaStar size={9} /> {barber.rating || 0}
                                        </div>
                                    </div>
                                    <div className="barber-name">{barber.name}</div>
                                    <div className="barber-address">{barber.address}</div>
                                    {barber.location && (
                                        <div style={{ fontSize: 10, color: '#6366F1', marginTop: 2 }}>📍 {barber.location}</div>
                                    )}
                                    <div style={{ display: "flex", gap: "6px", flexWrap: "wrap", justifyContent: "center", marginTop: "4px" }}>
                                        {barber.gender === 'female' ? (
                                            <span style={{ color: '#D63384', background: '#FFF0F5', padding: '2px 6px', borderRadius: 4, fontSize: 10, fontWeight: 600 }}>
                                                Ayol
                                            </span>
                                        ) : barber.gender === 'male' ? (
                                            <span style={{ color: '#D4A853', background: '#F8F5F0', padding: '2px 6px', borderRadius: 4, fontSize: 10, fontWeight: 600 }}>
                                                Erkak
                                            </span>
                                        ) : null}
                                        {barber.tags?.[0] && (
                                            <span
                                                className="barber-tag"
                                                style={{
                                                    background: tagColors[barber.tags[0]]?.bg || "#F1F5F9",
                                                    color: tagColors[barber.tags[0]]?.color || "#64748B",
                                                    margin: 0
                                                }}
                                            >
                                                {barber.tags[0]}
                                            </span>
                                        )}
                                    </div>
                                    <div className="card-actions">
                                        <span className="card-action-btn" onClick={(e) => { e.stopPropagation(); openEditModal(barber); }}>
                                            <FaEdit size={12} /> Tahrirlash
                                        </span>
                                        <span className="card-action-btn" onClick={(e) => { e.stopPropagation(); handleDelete(barber.id, barber.name); }}
                                            style={{ color: "#EF4444" }}>
                                            <FaTrash size={12} /> O'chirish
                                        </span>
                                    </div>
                                </div>
                            ))}
                        </div>
                    ) : (
                        <div className="dash-card">
                            <table className="dash-table">
                                <thead>
                                    <tr>
                                        <th>Sartarosh</th>
                                        <th>Jinsi</th>
                                        <th>Viloyat</th>
                                        <th>Manzil</th>
                                        <th>Reyting</th>
                                        <th>Tajriba</th>
                                        <th>Narx</th>
                                        <th>Amallar</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {filtered.map((b) => (
                                        <tr key={b.id} onClick={() => setSelectedBarber(b)} style={{ cursor: "pointer" }}>
                                            <td>
                                                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                                                    <div style={{
                                                        width: 36, height: 36, borderRadius: "50%",
                                                        background: "linear-gradient(135deg, #DBEAFE, #93C5FD)",
                                                        display: "flex", alignItems: "center", justifyContent: "center",
                                                        color: "#3B82F6", fontSize: 14
                                                    }}>
                                                        <FaCut />
                                                    </div>
                                                    <span style={{ fontWeight: 600 }}>{b.name}</span>
                                                </div>
                                            </td>
                                            <td>
                                                {b.gender === 'female' ? (
                                                    <span style={{ color: '#D63384', background: '#FFF0F5', padding: '4px 8px', borderRadius: 4, fontSize: 12, fontWeight: 600 }}>
                                                        Ayol
                                                    </span>
                                                ) : (
                                                    <span style={{ color: '#D4A853', background: '#F8F5F0', padding: '4px 8px', borderRadius: 4, fontSize: 12, fontWeight: 600 }}>
                                                        Erkak
                                                    </span>
                                                )}
                                            </td>
                                            <td>
                                                <span style={{ color: '#6366F1', fontSize: 12, fontWeight: 500 }}>
                                                    {b.location ? `📍 ${b.location}` : '—'}
                                                </span>
                                            </td>
                                            <td style={{ color: "#64748B" }}>{b.address}</td>
                                            <td>
                                                <span style={{ display: "flex", alignItems: "center", gap: 4, color: "#F59E0B", fontWeight: 600 }}>
                                                    <FaStar size={12} /> {b.rating || 0}
                                                </span>
                                            </td>
                                            <td>{b.experience} yil</td>
                                            <td>{b.services?.[0] ? formatPrice(b.services[0].price) : "-"}</td>
                                            <td>
                                                <div style={{ display: "flex", gap: 8 }}>
                                                    <button onClick={(e) => { e.stopPropagation(); openEditModal(b); }}
                                                        style={{ background: "#EFF6FF", color: "#3B82F6", border: "none", padding: "6px 10px", borderRadius: 8, cursor: "pointer", fontSize: 12 }}>
                                                        <FaEdit />
                                                    </button>
                                                    <button onClick={(e) => { e.stopPropagation(); handleDelete(b.id, b.name); }}
                                                        style={{ background: "#FEE2E2", color: "#DC2626", border: "none", padding: "6px 10px", borderRadius: 8, cursor: "pointer", fontSize: 12 }}>
                                                        <FaTrash />
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}

                    {filtered.length === 0 && !loading && (
                        <div style={{ textAlign: "center", padding: 60, color: "#94A3B8", fontSize: 14 }}>
                            Hech qanday sartarosh topilmadi
                        </div>
                    )}
                </div>

                {/* Detail panel */}
                {selectedBarber && (() => {
                    const bBookings = bookings.filter((b) => b.barberName === selectedBarber.name && b.status !== "cancelled" && b.status !== "no-show");
                    const today = new Date().toISOString().split("T")[0];
                    const todayBookings = bBookings.filter(b => b.date === today);
                    const completedBookings = bBookings.filter(b => b.status === "completed" || b.status === "confirmed");
                    const totalBarberEarnings = completedBookings.reduce((sum, b) => sum + (b.barberEarnings || (b.price || 0)), 0);
                    const isActive = selectedBarber.isActive !== false;

                    return (
                        <div style={{ width: 280, flexShrink: 0 }}>
                            <div className="detail-panel">
                                <div className="detail-avatar">
                                    <FaCut />
                                </div>
                                <div style={{ textAlign: "center", marginBottom: 16 }}>
                                    <div style={{
                                        display: "inline-flex", alignItems: "center", gap: 4,
                                        background: "#FEF3C7", color: "#D97706",
                                        padding: "4px 10px", borderRadius: 8,
                                        fontSize: 13, fontWeight: 700, marginBottom: 8
                                    }}>
                                        <FaStar size={11} /> {selectedBarber.rating || 0}
                                    </div>
                                    <h3 style={{ fontSize: 18, fontWeight: 700, color: "#1E293B" }}>{selectedBarber.name}</h3>
                                    <div style={{ display: "flex", justifyContent: "center", gap: 10, marginTop: 4 }}>
                                        <span style={{ fontSize: 12, color: isActive ? "#16A34A" : "#DC2626", fontWeight: 600, display: "flex", alignItems: "center", gap: 4 }}>
                                            {isActive ? <FaCheckCircle size={10} /> : <FaPowerOff size={10} />}
                                            {isActive ? "Faol (Ochiq)" : "Band (Yopiq)"}
                                        </span>
                                    </div>
                                    <p style={{ fontSize: 13, color: "#94A3B8", marginTop: 4 }}>{selectedBarber.address}</p>
                                    {selectedBarber.location && (
                                        <p style={{ fontSize: 12, color: '#6366F1', marginTop: 4, fontWeight: 600 }}>📍 {selectedBarber.location}</p>
                                    )}
                                    {selectedBarber.phone && (
                                        <p style={{ fontSize: 13, color: "#3B82F6", marginTop: 4 }}>{selectedBarber.phone}</p>
                                    )}
                                    <div style={{ marginTop: 8 }}>
                                        {selectedBarber.gender === 'female' ? (
                                            <span style={{ color: '#D63384', background: '#FFF0F5', padding: '4px 10px', borderRadius: 6, fontSize: 13, fontWeight: 700 }}>
                                                Ayollar ustasi
                                            </span>
                                        ) : selectedBarber.gender === 'male' ? (
                                            <span style={{ color: '#D4A853', background: '#F8F5F0', padding: '4px 10px', borderRadius: 6, fontSize: 13, fontWeight: 700 }}>
                                                Erkaklar ustasi
                                            </span>
                                        ) : null}
                                    </div>
                                </div>

                                {/* Stats Cards */}
                                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 16 }}>
                                    <div style={{ background: "#F1F5F9", padding: 12, borderRadius: 10, textAlign: "center" }}>
                                        <div style={{ fontSize: 11, color: "#64748B", fontWeight: 600 }}>Daromadi</div>
                                        <div style={{ fontSize: 14, color: "#1E293B", fontWeight: 700, marginTop: 4 }}>{formatPrice(totalBarberEarnings)}</div>
                                    </div>
                                    <div style={{ background: "#F1F5F9", padding: 12, borderRadius: 10, textAlign: "center" }}>
                                        <div style={{ fontSize: 11, color: "#64748B", fontWeight: 600 }}>Bugun / Jami</div>
                                        <div style={{ fontSize: 14, color: "#1E293B", fontWeight: 700, marginTop: 4 }}>{todayBookings.length} / {completedBookings.length}</div>
                                    </div>
                                </div>

                                {selectedBarber.tags?.map((tag) => (
                                    <span key={tag} style={{
                                        display: "inline-block", padding: "3px 10px", borderRadius: 8,
                                        background: tagColors[tag]?.bg || "#F1F5F9",
                                        color: tagColors[tag]?.color || "#64748B",
                                        fontSize: 11, fontWeight: 700, marginRight: 6, marginBottom: 12,
                                        textTransform: "uppercase"
                                    }}>
                                        {tag}
                                    </span>
                                ))}

                                <div style={{ display: "flex", gap: 12 }}>
                                    <a href={`tel:${selectedBarber.phone}`} style={{
                                        flex: 1, padding: "10px 0", borderRadius: 10, border: "none",
                                        display: "flex", alignItems: "center", justifyContent: "center", gap: 6,
                                        fontSize: 13, cursor: "pointer", background: "#DCFCE7", color: "#16A34A", fontWeight: 600,
                                        textDecoration: "none"
                                    }}>
                                        <FaPhone size={13} /> Qo'ng'iroq
                                    </a>
                                </div>
                            </div>

                            <div style={{ borderTop: "1px solid #F1F5F9", paddingTop: 16, marginTop: 16 }}>
                                <h4 style={{ fontSize: 13, fontWeight: 600, color: "#475569", marginBottom: 10 }}>Xizmatlar</h4>
                                {selectedBarber.services?.map((s, idx) => (
                                    <div key={idx} style={{
                                        display: "flex", justifyContent: "space-between", alignItems: "center",
                                        padding: "8px 0", borderBottom: "1px solid #F8FAFC"
                                    }}>
                                        <span style={{ fontSize: 13, color: "#1E293B" }}>{s.name}</span>
                                        <span style={{ fontSize: 13, fontWeight: 700, color: "#3B82F6" }}>{formatPrice(s.price)}</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    );
                })()}
            </div>

        </div>
    );
}
