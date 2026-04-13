"use client";
import { useState, useEffect } from "react";
import { FaSearch, FaSpinner, FaTrash } from "react-icons/fa";
import { onBookingsSnapshot, formatPrice, deleteBooking } from "@/lib/firestore";

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

export default function BookingsPage() {
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState("all");
    const [search, setSearch] = useState("");

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
            b.service?.toLowerCase().includes(search.toLowerCase());
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
                            placeholder="Bron qidirish..."
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
                                        <td style={{ fontWeight: 600 }}>{b.client}</td>
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
                                                    border: "none",
                                                    color: "#EF4444",
                                                    cursor: "pointer",
                                                    padding: "8px",
                                                    borderRadius: "8px",
                                                    display: "flex",
                                                    alignItems: "center",
                                                    justifyContent: "center"
                                                }}
                                                title="O'chirish"
                                            >
                                                <FaTrash size={14} />
                                            </button>
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
