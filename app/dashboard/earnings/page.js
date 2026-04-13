"use client";
import { useState, useEffect } from "react";
import { FaWallet, FaChartLine, FaMoneyBillWave, FaSpinner } from "react-icons/fa";
import { onBookingsSnapshot, formatPrice } from "@/lib/firestore";

export default function EarningsPage() {
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const unsub = onBookingsSnapshot((data) => {
            setBookings(data);
            setLoading(false);
        });
        return () => unsub();
    }, []);

    const confirmedBookings = bookings.filter((b) => b.status === "completed" || b.status === "confirmed");
    const totalEarnings = confirmedBookings.reduce((sum, b) => sum + (b.price || 0), 0);
    const totalAdminEarnings = confirmedBookings.reduce((sum, b) => sum + (b.adminEarnings || 0), 0);
    const totalBarberEarnings = confirmedBookings.reduce((sum, b) => sum + (b.barberEarnings || 0), 0);

    const today = new Date().toISOString().split("T")[0];
    const yesterdayDate = new Date(Date.now() - 86400000).toISOString().split("T")[0];

    const todayBookingsCount = bookings.filter(b => b.date === today && b.status !== "cancelled").length;
    const yesterdayBookingsCount = bookings.filter(b => b.date === yesterdayDate && b.status !== "cancelled").length;

    // Oylar bo'yicha guruhlash
    const monthlyMap = {};
    confirmedBookings.forEach((b) => {
        if (!b.date) return;
        const month = b.date.substring(0, 7); // "2026-04"
        if (!monthlyMap[month]) monthlyMap[month] = { total: 0, admin: 0, barber: 0 };
        monthlyMap[month].total += (b.price || 0);
        monthlyMap[month].admin += (b.adminEarnings || 0);
        monthlyMap[month].barber += (b.barberEarnings || 0);
    });

    const monthNames = {
        "01": "Yan", "02": "Fev", "03": "Mar", "04": "Apr",
        "05": "May", "06": "Iyun", "07": "Iyul", "08": "Avg",
        "09": "Sen", "10": "Okt", "11": "Noy", "12": "Dek",
    };

    const monthlyData = Object.entries(monthlyMap)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([key, data]) => ({
            month: monthNames[key.split("-")[1]] || key,
            amount: data.total,
            adminAmount: data.admin,
            barberAmount: data.barber
        }));

    const maxAmount = monthlyData.length > 0 ? Math.max(...monthlyData.map((m) => m.amount)) : 1;
    const avgMonthly = monthlyData.length > 0 ? totalEarnings / monthlyData.length : 0;

    // Tranzaksiyalar (oxirgi 10 ta tasdiqlangan bron)
    const transactions = confirmedBookings.slice(0, 10);

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
                    <h1>Daromad</h1>
                    <p style={{ color: "#94A3B8", fontSize: 14, marginTop: 2 }}>Moliyaviy ko'rsatkichlar</p>
                </div>
            </div>

            {/* Stats */}
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: 20, marginBottom: 28 }}>
                <div className="dash-stat-card">
                    <div className="stat-icon" style={{ background: "#DCFCE7", color: "#22C55E" }}>
                        <FaWallet />
                    </div>
                    <div className="stat-value" style={{ fontSize: 24 }}>{formatPrice(totalEarnings)}</div>
                    <div className="stat-label">Umumiy oborot</div>
                </div>
                <div className="dash-stat-card">
                    <div className="stat-icon" style={{ background: "#F3E8FF", color: "#9333EA" }}>
                        <FaChartLine />
                    </div>
                    <div className="stat-value" style={{ fontSize: 24 }}>{formatPrice(totalAdminEarnings)}</div>
                    <div className="stat-label">Sof daromad (Admin komissiyasi)</div>
                </div>
                <div className="dash-stat-card">
                    <div className="stat-icon" style={{ background: "#DBEAFE", color: "#3B82F6" }}>
                        <FaMoneyBillWave />
                    </div>
                    <div className="stat-value" style={{ fontSize: 24 }}>{formatPrice(totalBarberEarnings)}</div>
                    <div className="stat-label">Sartaroshlar daromadi</div>
                </div>
            </div>

            {/* Daily stats summary */}
            <div style={{ display: "flex", gap: 20, marginBottom: 24 }}>
                <div style={{ flex: 1, background: "white", padding: 20, borderRadius: 16, border: "1px solid #E2E8F0" }}>
                    <div style={{ color: "#64748B", fontSize: 13, fontWeight: 600 }}>Bugungi bronlar</div>
                    <div style={{ fontSize: 28, fontWeight: 700, color: "#1E293B", marginTop: 4 }}>{todayBookingsCount} ta</div>
                </div>
                <div style={{ flex: 1, background: "white", padding: 20, borderRadius: 16, border: "1px solid #E2E8F0" }}>
                    <div style={{ color: "#64748B", fontSize: 13, fontWeight: 600 }}>Kechagi bronlar</div>
                    <div style={{ fontSize: 28, fontWeight: 700, color: "#1E293B", marginTop: 4 }}>{yesterdayBookingsCount} ta</div>
                </div>
            </div>

            {/* Monthly chart */}
            {monthlyData.length > 0 && (
                <div className="dash-card" style={{ marginBottom: 24 }}>
                    <h3 style={{ fontSize: 16, fontWeight: 700, color: "#1E293B", marginBottom: 24 }}>Oylik daromad</h3>
                    <div style={{ display: "flex", alignItems: "flex-end", gap: 16, height: 220 }}>
                        {monthlyData.map((m, idx) => {
                            const height = (m.amount / maxAmount) * 180;
                            return (
                                <div key={idx} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 8 }}>
                                    <span style={{ fontSize: 12, fontWeight: 600, color: "#1E293B" }}>
                                        {formatPrice(m.amount)}
                                    </span>
                                    <span style={{ fontSize: 11, fontWeight: 700, color: "#9333EA", marginBottom: 2 }}>
                                        {formatPrice(m.adminAmount)}
                                    </span>
                                    <div style={{
                                        width: "100%", maxWidth: 60, height: Math.max(height, 8),
                                        borderRadius: "6px 6px 4px 4px",
                                        background: idx === monthlyData.length - 1
                                            ? "linear-gradient(180deg, #9333EA, #7E22CE)"
                                            : "linear-gradient(180deg, #D8B4FE, #C084FC)",
                                        transition: "height 0.5s ease"
                                    }} />
                                    <span style={{ fontSize: 12, color: "#94A3B8", fontWeight: 500 }}>{m.month}</span>
                                </div>
                            );
                        })}
                    </div>
                </div>
            )}

            {/* Transactions */}
            <div className="dash-card">
                <h3 style={{ fontSize: 16, fontWeight: 700, color: "#1E293B", marginBottom: 16 }}>So'nggi tranzaksiyalar</h3>
                {transactions.length === 0 ? (
                    <p style={{ color: "#94A3B8", textAlign: "center", padding: 24, fontSize: 14 }}>Tranzaksiyalar yo'q</p>
                ) : (
                    <table className="dash-table">
                        <thead>
                            <tr>
                                <th>Sana</th>
                                <th>Mijoz</th>
                                <th>Xizmat</th>
                                <th>Summa</th>
                                <th>Holat</th>
                            </tr>
                        </thead>
                        <tbody>
                            {transactions.map((b) => (
                                <tr key={b.id}>
                                    <td>{b.date}</td>
                                    <td style={{ fontWeight: 600 }}>{b.client}</td>
                                    <td>{b.service}</td>
                                    <td style={{ fontWeight: 600 }}>{formatPrice(b.price || 0)}</td>
                                    <td><span className="badge badge-success">To'langan</span></td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>
        </div>
    );
}
