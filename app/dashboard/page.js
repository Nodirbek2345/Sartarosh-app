"use client";
import { useState, useEffect } from "react";
import { FaCalendarAlt, FaStar, FaWallet, FaUsers, FaSearch, FaBell, FaArrowUp, FaArrowDown, FaDatabase, FaSpinner, FaUserCheck } from "react-icons/fa";
import { onBarbersSnapshot, onBookingsSnapshot, onUsersSnapshot, getDashboardStats, seedDatabase, formatPrice } from "@/lib/firestore";
import toast from "react-hot-toast";

export default function DashboardHome() {
    const [barbers, setBarbers] = useState([]);
    const [bookings, setBookings] = useState([]);
    const [stats, setStats] = useState(null);
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [seeding, setSeeding] = useState(false);

    useEffect(() => {
        // Real-time listeners
        const unsubBarbers = onBarbersSnapshot(setBarbers);
        const unsubBookings = onBookingsSnapshot(setBookings);
        const unsubUsers = onUsersSnapshot(setUsers);

        // Stats
        getDashboardStats().then((s) => {
            setStats(s);
            setLoading(false);
        }).catch(() => setLoading(false));

        return () => {
            unsubBarbers();
            unsubBookings();
            unsubUsers();
        };
    }, []);

    const handleSeed = async () => {
        setSeeding(true);
        try {
            const result = await seedDatabase();
            if (result.success) {
                toast.success(result.message);
                // Statsni yangilash
                const s = await getDashboardStats();
                setStats(s);
            } else {
                toast.error(result.message);
            }
        } catch (err) {
            toast.error("Xatolik: " + err.message);
        }
        setSeeding(false);
    };

    const today = new Date().toISOString().split("T")[0];
    const todayBookings = bookings.filter((b) => b.date === today);
    const confirmedBookings = bookings.filter((b) => b.status === "confirmed");
    const totalEarnings = confirmedBookings.reduce((sum, b) => sum + (b.price || 0), 0);
    const avgRating = barbers.length > 0
        ? (barbers.reduce((sum, b) => sum + (b.rating || 0), 0) / barbers.length).toFixed(1)
        : "0";

    const statCards = [
        {
            label: "Bugungi bronlar",
            value: todayBookings.length.toString(),
            icon: FaCalendarAlt,
            color: "#3B82F6",
            bg: "#DBEAFE",
        },
        {
            label: "Umumiy daromad",
            value: formatPrice(totalEarnings),
            icon: FaWallet,
            color: "#22C55E",
            bg: "#DCFCE7",
        },
        {
            label: "O'rtacha reyting",
            value: avgRating,
            icon: FaStar,
            color: "#F59E0B",
            bg: "#FEF3C7",
        },
        {
            label: "Sartaroshlar",
            value: barbers.length.toString(),
            icon: FaUsers,
            color: "#8B5CF6",
            bg: "#EDE9FE",
        },
    ];

    const statusMap = {
        confirmed: { label: "Tasdiqlangan", class: "badge-success" },
        pending: { label: "Kutilmoqda", class: "badge-warning" },
        cancelled: { label: "Bekor qilingan", class: "badge-danger" },
    };

    const isEmpty = barbers.length === 0 && bookings.length === 0 && !loading;

    return (
        <div>
            {/* Top bar */}
            <div className="dashboard-topbar">
                <div>
                    <h1>Bosh sahifa</h1>
                    <p style={{ color: "#94A3B8", fontSize: 14, marginTop: 2 }}>Xush kelibsiz! Bugungi natijalar.</p>
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
                    <div className="dashboard-search">
                        <FaSearch className="search-icon" />
                        <input placeholder="Qidirish..." />
                    </div>
                    <button
                        onClick={() => alert("Hozircha yangi bildirishnomalar yo'q")}
                        style={{
                            width: 40, height: 40, borderRadius: 12,
                            background: "white", border: "1px solid #E8EDF5",
                            display: "flex", alignItems: "center", justifyContent: "center",
                            color: "#64748B", cursor: "pointer", position: "relative"
                        }}>
                        <FaBell />
                        {todayBookings.length > 0 && (
                            <span style={{
                                position: "absolute", top: -2, right: -2,
                                width: 8, height: 8, borderRadius: "50%",
                                background: "#EF4444"
                            }} />
                        )}
                    </button>
                    <div
                        onClick={() => window.location.href = '/dashboard/settings'}
                        style={{
                            width: 40, height: 40, borderRadius: "50%",
                            background: "linear-gradient(135deg, #3B82F6, #2563EB)",
                            display: "flex", alignItems: "center", justifyContent: "center",
                            color: "white", fontWeight: 700, fontSize: 14, cursor: "pointer"
                        }}>A</div>
                </div>
            </div>

            {/* Empty state — baza seed qilish */}
            {isEmpty && (
                <div className="dash-card" style={{ textAlign: "center", padding: 60, marginBottom: 24 }}>
                    <FaDatabase size={48} style={{ color: "#94A3B8", margin: "0 auto 16px" }} />
                    <h2 style={{ fontSize: 20, fontWeight: 700, color: "#1E293B", marginBottom: 8 }}>
                        Baza bo'sh
                    </h2>
                    <p style={{ color: "#94A3B8", fontSize: 14, marginBottom: 24, maxWidth: 400, margin: "0 auto 24px" }}>
                        Dashboardda ma'lumot ko'rsatish uchun bazani boshlang'ich ma'lumotlar bilan to'ldiring
                    </p>
                    <button
                        onClick={handleSeed}
                        disabled={seeding}
                        className="dash-btn-primary"
                        style={{ display: "inline-flex", alignItems: "center", gap: 8, padding: "12px 32px", fontSize: 15 }}
                    >
                        {seeding ? <FaSpinner className="animate-spin" /> : <FaDatabase />}
                        {seeding ? "Yuklanmoqda..." : "Bazani to'ldirish"}
                    </button>
                </div>
            )}

            {/* Loading */}
            {loading && (
                <div style={{ textAlign: "center", padding: 60, color: "#94A3B8" }}>
                    <FaSpinner size={32} className="animate-spin" style={{ margin: "0 auto 16px" }} />
                    <p>Yuklanmoqda...</p>
                </div>
            )}

            {!loading && !isEmpty && (
                <>
                    {/* Stats grid */}
                    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: 20, marginBottom: 28 }}>
                        {statCards.map((stat, idx) => {
                            const Icon = stat.icon;
                            return (
                                <div key={idx} className="dash-stat-card">
                                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                                        <div className="stat-icon" style={{ background: stat.bg, color: stat.color }}>
                                            <Icon />
                                        </div>
                                    </div>
                                    <div className="stat-value">{stat.value}</div>
                                    <div className="stat-label">{stat.label}</div>
                                </div>
                            );
                        })}
                    </div>

                    {/* Recent bookings */}
                    <div className="dash-card">
                        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20 }}>
                            <h2 style={{ fontSize: 18, fontWeight: 700, color: "#1E293B" }}>So'nggi bronlar</h2>
                            <a href="/dashboard/bookings" style={{ fontSize: 13, fontWeight: 600, color: "#3B82F6", textDecoration: "none" }}>
                                Hammasini ko'rish →
                            </a>
                        </div>

                        {bookings.length === 0 ? (
                            <p style={{ color: "#94A3B8", fontSize: 14, textAlign: "center", padding: 24 }}>Hozircha bronlar yo'q</p>
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
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {bookings.slice(0, 5).map((b) => (
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
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </div>

                    {/* Bottom cards */}
                    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(300px, 1fr))", gap: 20, marginTop: 24 }}>
                        {/* Top barbers */}
                        <div className="dash-card">
                            <h3 style={{ fontSize: 16, fontWeight: 700, color: "#1E293B", marginBottom: 16 }}>Top sartaroshlar</h3>
                            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                                {barbers
                                    .sort((a, b) => (b.rating || 0) - (a.rating || 0))
                                    .slice(0, 4)
                                    .map((b, idx) => (
                                        <div key={b.id} style={{
                                            display: "flex", alignItems: "center", gap: 12,
                                            padding: "10px 12px", borderRadius: 12,
                                            background: idx === 0 ? "#EFF6FF" : "transparent"
                                        }}>
                                            <div style={{
                                                width: 36, height: 36, borderRadius: "50%",
                                                background: `linear-gradient(135deg, ${idx === 0 ? '#3B82F6' : '#94A3B8'}, ${idx === 0 ? '#2563EB' : '#64748B'})`,
                                                display: "flex", alignItems: "center", justifyContent: "center",
                                                color: "white", fontWeight: 700, fontSize: 13, flexShrink: 0
                                            }}>
                                                {b.name?.charAt(0) || "?"}
                                            </div>
                                            <div style={{ flex: 1 }}>
                                                <div style={{ fontSize: 14, fontWeight: 600, color: "#1E293B" }}>{b.name}</div>
                                                <div style={{ fontSize: 12, color: "#94A3B8" }}>{b.reviewCount || 0} ta sharh</div>
                                            </div>
                                            <div style={{
                                                display: "flex", alignItems: "center", gap: 4,
                                                fontSize: 13, fontWeight: 700, color: "#F59E0B"
                                            }}>
                                                <FaStar size={12} /> {b.rating || 0}
                                            </div>
                                        </div>
                                    ))}
                            </div>
                        </div>

                        {/* Bugungi jadval */}
                        <div className="dash-card">
                            <h3 style={{ fontSize: 16, fontWeight: 700, color: "#1E293B", marginBottom: 16 }}>Bugungi jadval</h3>
                            {todayBookings.length === 0 ? (
                                <p style={{ color: "#94A3B8", fontSize: 14, textAlign: "center", padding: 24 }}>Bugun bronlar yo'q</p>
                            ) : (
                                <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                                    {todayBookings.map((b) => (
                                        <div key={b.id} style={{
                                            display: "flex", alignItems: "center", gap: 12,
                                            padding: "12px 14px", borderRadius: 12,
                                            border: "1px solid #F1F5F9"
                                        }}>
                                            <div style={{
                                                padding: "6px 10px", borderRadius: 8,
                                                background: "#EFF6FF", color: "#3B82F6",
                                                fontWeight: 700, fontSize: 13
                                            }}>
                                                {b.time}
                                            </div>
                                            <div style={{ flex: 1 }}>
                                                <div style={{ fontSize: 14, fontWeight: 600, color: "#1E293B" }}>{b.client}</div>
                                                <div style={{ fontSize: 12, color: "#94A3B8" }}>{b.service}</div>
                                            </div>
                                            <span className={`badge ${statusMap[b.status]?.class || "badge-info"}`}>
                                                {statusMap[b.status]?.label || b.status}
                                            </span>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Ro'yxatdan o'tgan foydalanuvchilar */}
                    <div className="dash-card" style={{ marginTop: 24 }}>
                        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20 }}>
                            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                                <div style={{
                                    width: 36, height: 36, borderRadius: 10,
                                    background: "#DCFCE7", color: "#22C55E",
                                    display: "flex", alignItems: "center", justifyContent: "center"
                                }}>
                                    <FaUserCheck />
                                </div>
                                <h2 style={{ fontSize: 18, fontWeight: 700, color: "#1E293B" }}>Ro'yxatdan o'tganlar</h2>
                            </div>
                            <span style={{
                                padding: "4px 12px", borderRadius: 20,
                                background: "#DCFCE7", color: "#22C55E",
                                fontSize: 13, fontWeight: 700
                            }}>{users.length} ta</span>
                        </div>

                        {users.length === 0 ? (
                            <p style={{ color: "#94A3B8", fontSize: 14, textAlign: "center", padding: 24 }}>Hozircha foydalanuvchilar yo'q</p>
                        ) : (
                            <div style={{ overflowX: "auto" }}>
                                <table className="dash-table">
                                    <thead>
                                        <tr>
                                            <th>Foydalanuvchi</th>
                                            <th>Email</th>
                                            <th>Telefon</th>
                                            <th>Ro'yxatdan o'tgan</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {users.map((u) => (
                                            <tr key={u.id}>
                                                <td>
                                                    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                                                        {u.photoUrl ? (
                                                            <img src={u.photoUrl} alt={u.name} style={{
                                                                width: 32, height: 32, borderRadius: "50%", objectFit: "cover"
                                                            }} />
                                                        ) : (
                                                            <div style={{
                                                                width: 32, height: 32, borderRadius: "50%",
                                                                background: "linear-gradient(135deg, #22C55E, #16A34A)",
                                                                display: "flex", alignItems: "center", justifyContent: "center",
                                                                color: "white", fontWeight: 700, fontSize: 13
                                                            }}>{(u.name || "?").charAt(0)}</div>
                                                        )}
                                                        <span style={{ fontWeight: 600 }}>{u.name || "Noma'lum"}</span>
                                                    </div>
                                                </td>
                                                <td>{u.email || "—"}</td>
                                                <td>{u.phone || "—"}</td>
                                                <td>{u.createdAt?.toDate ? u.createdAt.toDate().toLocaleDateString("uz-UZ") : "—"}</td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </div>
                </>
            )}
        </div>
    );
}
