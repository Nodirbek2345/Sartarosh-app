"use client";
import { useState, useEffect } from "react";
import { FaSearch, FaSpinner, FaTrash, FaPhone, FaUser, FaEye, FaTimes } from "react-icons/fa";
import { onBookingsSnapshot, formatPrice, deleteBooking } from "@/lib/firestore";
import { db } from "@/lib/firebase";
import { doc, getDoc } from "firebase/firestore";

const statusFilters = [
    { key: "all", label: "Barchasi" },
    { key: "pending", label: "Kutilmoqda" },
    { key: "confirmed", label: "Tasdiqlangan" },
    { key: "in-progress", label: "Jarayonda" },
    { key: "completed", label: "Tugallangan" },
    { key: "cancelled", label: "Bekor qilingan" },
    { key: "no-show", label: "Kelmagan" }
];

const statusMap = {
    "pending": { label: "Kutilmoqda", class: "badge-warning" },
    "confirmed": { label: "Tasdiqlangan", class: "badge-info" },
    "in-progress": { label: "Jarayonda", class: "badge-primary" },
    "completed": { label: "Tugallangan", class: "badge-success" },
    "cancelled": { label: "Bekor qilingan", class: "badge-danger" },
    "no-show": { label: "Kelmadi", class: "badge-dark" }
};

// Premium Client Details Modal
function ClientModal({ booking, onClose }) {
    const [clientData, setClientData] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function fetchClient() {
            if (!booking?.clientUid) {
                setLoading(false);
                return;
            }
            try {
                const userDoc = await getDoc(doc(db, "users", booking.clientUid));
                if (userDoc.exists()) {
                    setClientData({ id: userDoc.id, ...userDoc.data() });
                }
            } catch (e) {
                console.error("Client fetch error:", e);
            }
            setLoading(false);
        }
        fetchClient();
    }, [booking?.clientUid]);

    if (!booking) return null;

    return (
        <div style={{
            position: "fixed", top: 0, left: 0, right: 0, bottom: 0,
            background: "rgba(0,0,0,0.5)", backdropFilter: "blur(4px)",
            display: "flex", alignItems: "center", justifyContent: "center",
            zIndex: 9999, padding: "20px"
        }} onClick={onClose}>
            <div style={{
                background: "white", borderRadius: "20px", padding: "28px",
                maxWidth: "440px", width: "100%", boxShadow: "0 20px 60px rgba(0,0,0,0.15)",
                position: "relative"
            }} onClick={(e) => e.stopPropagation()}>
                {/* Close */}
                <button onClick={onClose} style={{
                    position: "absolute", top: 16, right: 16,
                    background: "#F1F5F9", border: "none", borderRadius: "10px",
                    padding: "8px", cursor: "pointer", color: "#64748B"
                }}><FaTimes size={14} /></button>

                {/* Header */}
                <div style={{ textAlign: "center", marginBottom: "24px" }}>
                    <div style={{
                        width: 56, height: 56, borderRadius: "50%",
                        background: "linear-gradient(135deg, #D4A853, #C9963C)",
                        display: "flex", alignItems: "center", justifyContent: "center",
                        margin: "0 auto 12px", fontSize: 22, color: "white"
                    }}>
                        <FaUser />
                    </div>
                    <h3 style={{ margin: 0, fontSize: 18, color: "#1E293B", fontWeight: 700 }}>
                        {booking.client || "Noma'lum"}
                    </h3>
                    <p style={{ color: "#94A3B8", fontSize: 13, margin: "4px 0 0" }}>
                        Mijoz ma'lumotlari
                    </p>
                </div>

                {loading ? (
                    <div style={{ textAlign: "center", padding: 20 }}>
                        <FaSpinner className="animate-spin" style={{ color: "#D4A853" }} />
                    </div>
                ) : (
                    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                        {/* Phone */}
                        <div style={{
                            background: "#F8FAFC", borderRadius: 12, padding: "12px 16px",
                            display: "flex", alignItems: "center", gap: 12
                        }}>
                            <FaPhone size={14} color="#D4A853" />
                            <div>
                                <div style={{ fontSize: 11, color: "#94A3B8", fontWeight: 600 }}>Telefon</div>
                                <div style={{ fontSize: 14, color: "#1E293B", fontWeight: 600 }}>
                                    {booking.clientPhone || clientData?.phone || "Kiritilmagan"}
                                </div>
                            </div>
                        </div>

                        {/* Gender */}
                        {clientData?.gender && (
                            <div style={{
                                background: "#F8FAFC", borderRadius: 12, padding: "12px 16px",
                                display: "flex", alignItems: "center", gap: 12
                            }}>
                                <span style={{ fontSize: 16 }}>{clientData.gender === "female" ? "👩" : "👨"}</span>
                                <div>
                                    <div style={{ fontSize: 11, color: "#94A3B8", fontWeight: 600 }}>Jinsi</div>
                                    <div style={{ fontSize: 14, color: "#1E293B", fontWeight: 600 }}>
                                        {clientData.gender === "female" ? "Ayol" : "Erkak"}
                                    </div>
                                </div>
                            </div>
                        )}

                        {/* Booking Info */}
                        <div style={{
                            background: "linear-gradient(135deg, #FFF8E8, #FFF5E0)",
                            borderRadius: 12, padding: "14px 16px",
                            border: "1px solid rgba(212,168,83,0.2)"
                        }}>
                            <div style={{ fontSize: 12, color: "#B8912E", fontWeight: 700, marginBottom: 8 }}>
                                📋 Bron ma'lumotlari
                            </div>
                            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, fontSize: 13 }}>
                                <div>
                                    <span style={{ color: "#94A3B8" }}>Xizmat:</span>
                                    <div style={{ fontWeight: 600, color: "#1E293B" }}>{booking.service}</div>
                                </div>
                                <div>
                                    <span style={{ color: "#94A3B8" }}>Narx:</span>
                                    <div style={{ fontWeight: 600, color: "#1E293B" }}>{formatPrice(booking.price || 0)}</div>
                                </div>
                                <div>
                                    <span style={{ color: "#94A3B8" }}>Sana:</span>
                                    <div style={{ fontWeight: 600, color: "#1E293B" }}>{booking.date}</div>
                                </div>
                                <div>
                                    <span style={{ color: "#94A3B8" }}>Vaqt:</span>
                                    <div style={{ fontWeight: 600, color: "#1E293B" }}>{booking.time}</div>
                                </div>
                            </div>
                        </div>

                        {/* Registered date */}
                        {clientData?.createdAt && (
                            <div style={{ fontSize: 12, color: "#94A3B8", textAlign: "center", marginTop: 4 }}>
                                Ro'yxatdan o'tgan: {
                                    (clientData.createdAt.toDate
                                        ? clientData.createdAt.toDate()
                                        : new Date(clientData.createdAt.seconds * 1000)
                                    ).toLocaleDateString('uz-UZ')
                                }
                            </div>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
}

export default function BookingsPage() {
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState("all");
    const [search, setSearch] = useState("");
    const [selectedBooking, setSelectedBooking] = useState(null);

    useEffect(() => {
        const unsub = onBookingsSnapshot((data) => {
            setBookings(data);
            setLoading(false);
        });
        return () => unsub();
    }, []);

    const filtered = bookings.filter((b) => {
        const matchStatus = filter === "all" || b.status === filter;
        const matchSearch =
            b.client?.toLowerCase().includes(search.toLowerCase()) ||
            b.barberName?.toLowerCase().includes(search.toLowerCase()) ||
            b.service?.toLowerCase().includes(search.toLowerCase()) ||
            b.clientPhone?.includes(search);
        return matchStatus && matchSearch;
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
            {/* Client Modal */}
            {selectedBooking && (
                <ClientModal
                    booking={selectedBooking}
                    onClose={() => setSelectedBooking(null)}
                />
            )}

            <div className="dashboard-topbar">
                <div>
                    <h1>Bronlar</h1>
                    <p style={{ color: "#94A3B8", fontSize: 14, marginTop: 2 }}>
                        Jami {bookings.length} ta bron
                    </p>
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <div className="dashboard-search">
                        <FaSearch className="search-icon" />
                        <input
                            placeholder="Bron, mijoz yoki telefon qidirish..."
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                    </div>
                </div>
            </div>

            <div className="filter-pills">
                {statusFilters.map((s) => (
                    <button
                        key={s.key}
                        className={`filter-pill ${filter === s.key ? "active" : ""}`}
                        onClick={() => setFilter(s.key)}
                    >
                        {s.label}
                    </button>
                ))}
            </div>

            <div className="dash-card">
                {filtered.length === 0 ? (
                    <div style={{ textAlign: "center", padding: 40, color: "#94A3B8", fontSize: 14 }}>
                        Hech qanday bron topilmadi
                    </div>
                ) : (
                    <div style={{ overflowX: "auto" }}>
                        <table className="dash-table">
                            <thead>
                                <tr>
                                    <th>Mijoz</th>
                                    <th>Telefon</th>
                                    <th>Sartarosh</th>
                                    <th>Xizmat</th>
                                    <th>Narx</th>
                                    <th>Sana</th>
                                    <th>Vaqt</th>
                                    <th>Holat</th>
                                    <th>Amallar</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filtered.map((b) => (
                                    <tr key={b.id}>
                                        <td>
                                            <button
                                                onClick={() => setSelectedBooking(b)}
                                                style={{
                                                    background: "none", border: "none", cursor: "pointer",
                                                    fontWeight: 600, color: "#D4A853", padding: 0,
                                                    display: "flex", alignItems: "center", gap: 6,
                                                    textDecoration: "none"
                                                }}
                                                title="Mijoz haqida ma'lumot"
                                            >
                                                <FaUser size={11} />
                                                {b.client}
                                            </button>
                                        </td>
                                        <td style={{ color: "#475569", fontSize: 13 }}>
                                            {b.clientPhone ? (
                                                <span style={{ display: "flex", alignItems: "center", gap: 4 }}>
                                                    <FaPhone size={10} color="#94A3B8" />
                                                    {b.clientPhone}
                                                </span>
                                            ) : (
                                                <span style={{ color: "#CBD5E1" }}>—</span>
                                            )}
                                        </td>
                                        <td>{b.barberName}</td>
                                        <td>{b.service}</td>
                                        <td style={{ fontWeight: 600 }}>{formatPrice(b.price || 0)}</td>
                                        <td>{b.date}</td>
                                        <td>{b.time}</td>
                                        <td>
                                            <span className={`badge ${statusMap[b.status]?.class || "badge-info"}`}>
                                                {statusMap[b.status]?.label || b.status}
                                            </span>
                                        </td>
                                        <td>
                                            <div style={{ display: "flex", gap: 6 }}>
                                                <button
                                                    onClick={() => setSelectedBooking(b)}
                                                    style={{
                                                        background: "rgba(212,168,83,0.1)",
                                                        border: "none", color: "#D4A853",
                                                        cursor: "pointer", padding: "8px",
                                                        borderRadius: "8px", display: "flex",
                                                        alignItems: "center", justifyContent: "center"
                                                    }}
                                                    title="Ko'rish"
                                                >
                                                    <FaEye size={14} />
                                                </button>
                                                <button
                                                    onClick={async () => {
                                                        if (window.confirm("Haqiqatan ham bu bronni o'chirmoqchimisiz?")) {
                                                            try {
                                                                await deleteBooking(b.id);
                                                            } catch (error) {
                                                                console.error("Xatolik:", error);
                                                                alert("Xatolik yuz berdi");
                                                            }
                                                        }
                                                    }}
                                                    style={{
                                                        background: "rgba(239, 68, 68, 0.1)",
                                                        border: "none", color: "#EF4444",
                                                        cursor: "pointer", padding: "8px",
                                                        borderRadius: "8px", display: "flex",
                                                        alignItems: "center", justifyContent: "center"
                                                    }}
                                                    title="O'chirish"
                                                >
                                                    <FaTrash size={14} />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </div>
    );
}
