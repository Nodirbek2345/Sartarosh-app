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
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: 24, marginBottom: 32 }}>
                <div style={{ background: "linear-gradient(135deg, #1E293B, #0F172A)", padding: 24, borderRadius: 20, color: "white", boxShadow: "0 10px 25px rgba(15, 23, 42, 0.2)", position: "relative", overflow: "hidden" }}>
                    <div style={{ position: "absolute", right: -20, top: -20, opacity: 0.1, fontSize: 120 }}><FaWallet /></div>
                    <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
                        <div style={{ background: "rgba(255,255,255,0.1)", padding: 12, borderRadius: 12 }}>
                            <FaWallet size={20} color="#D4AF37" />
                        </div>
                        <span style={{ fontSize: 15, fontWeight: 500, color: "#94A3B8" }}>Umumiy Oborot</span>
                    </div>
                    <div style={{ fontSize: 32, fontWeight: 700, color: "white", letterSpacing: 0.5 }}>{formatPrice(totalEarnings)}</div>
                    <div style={{ fontSize: 13, color: "#94A3B8", marginTop: 8 }}>Tizimdagi barcha to'lovlar</div>
                </div>

                <div style={{ background: "linear-gradient(135deg, #D4AF37, #B49020)", padding: 24, borderRadius: 20, color: "white", boxShadow: "0 10px 25px rgba(212, 175, 55, 0.3)", position: "relative", overflow: "hidden" }}>
                    <div style={{ position: "absolute", right: -20, top: -20, opacity: 0.15, fontSize: 120 }}><FaChartLine /></div>
                    <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
                        <div style={{ background: "rgba(255,255,255,0.2)", padding: 12, borderRadius: 12 }}>
                            <FaChartLine size={20} color="white" />
                        </div>
                        <span style={{ fontSize: 15, fontWeight: 500, color: "rgba(255,255,255,0.9)" }}>Sof Daromad</span>
                    </div>
                    <div style={{ fontSize: 32, fontWeight: 700, color: "white", letterSpacing: 0.5 }}>{formatPrice(totalAdminEarnings)}</div>
                    <div style={{ fontSize: 13, color: "rgba(255,255,255,0.8)", marginTop: 8 }}>Admin komissiyasi ehtimoli</div>
                </div>

                <div style={{ background: "white", padding: 24, borderRadius: 20, boxShadow: "0 10px 25px rgba(0, 0, 0, 0.05)", position: "relative", overflow: "hidden", border: "1px solid #F1F5F9" }}>
                    <div style={{ position: "absolute", right: -20, top: -20, opacity: 0.05, fontSize: 120 }}><FaMoneyBillWave /></div>
                    <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
                        <div style={{ background: "#F8FAFC", padding: 12, borderRadius: 12 }}>
                            <FaMoneyBillWave size={20} color="#3B82F6" />
                        </div>
                        <span style={{ fontSize: 15, fontWeight: 600, color: "#64748B" }}>Sartaroshlar Ulushi</span>
                    </div>
                    <div style={{ fontSize: 32, fontWeight: 700, color: "#1E293B", letterSpacing: 0.5 }}>{formatPrice(totalBarberEarnings)}</div>
                    <div style={{ fontSize: 13, color: "#94A3B8", marginTop: 8 }}>Ustalarga tegishli tushum</div>
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
                <div style={{ background: "white", padding: 32, borderRadius: 24, boxShadow: "0 10px 30px rgba(0,0,0,0.03)", marginBottom: 32, border: "1px solid #F1F5F9" }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 32 }}>
                        <div>
                            <h3 style={{ fontSize: 18, fontWeight: 700, color: "#1E293B", margin: 0 }}>Oylik tushumlar dinamikasi</h3>
                            <p style={{ color: "#94A3B8", fontSize: 13, margin: "4px 0 0" }}>Oborot va Admin foizi o'sishi</p>
                        </div>
                        <div style={{ display: "flex", gap: 16 }}>
                            <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                                <div style={{ width: 10, height: 10, borderRadius: 3, background: "#E2E8F0" }}></div>
                                <span style={{ fontSize: 12, color: "#64748B", fontWeight: 500 }}>Oborot</span>
                            </div>
                            <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                                <div style={{ width: 10, height: 10, borderRadius: 3, background: "#D4AF37" }}></div>
                                <span style={{ fontSize: 12, color: "#64748B", fontWeight: 500 }}>Daromad</span>
                            </div>
                        </div>
                    </div>

                    <div style={{ display: "flex", alignItems: "flex-end", gap: 20, height: 260, paddingBottom: 10, borderBottom: "1px dashed #E2E8F0" }}>
                        {monthlyData.map((m, idx) => {
                            const barHeight = Math.max((m.amount / maxAmount) * 200, 10);
                            const adminRatio = m.amount > 0 ? m.adminAmount / m.amount : 0;
                            const adminHeight = barHeight * adminRatio;

                            return (
                                <div key={idx} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 10, position: "relative", group: "true" }}>

                                    <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
                                        <span style={{ fontSize: 11, fontWeight: 700, color: "#1E293B", opacity: 0.8 }}>
                                            {formatPrice(m.amount)}
                                        </span>
                                    </div>

                                    <div style={{
                                        width: "100%", maxWidth: 45, height: barHeight,
                                        borderRadius: "8px 8px 0 0",
                                        background: "#F1F5F9",
                                        position: "relative", overflow: "hidden",
                                        transition: "height 0.4s ease-out"
                                    }}>
                                        {/* Admin daromad qismi oltin rangda ichidan o'sadigan qilib */}
                                        <div style={{
                                            position: "absolute", bottom: 0, left: 0, right: 0,
                                            height: adminHeight,
                                            background: "linear-gradient(180deg, #D4AF37, #B49020)",
                                            boxShadow: "inset 0 2px 4px rgba(255,255,255,0.2)",
                                            transition: "height 0.5s ease-out 0.2s",
                                            borderRadius: adminHeight >= barHeight ? "8px 8px 0 0" : "0",
                                        }} />
                                    </div>

                                    <span style={{ fontSize: 13, color: "#64748B", fontWeight: 600 }}>{m.month}</span>
                                </div>
                            );
                        })}
                    </div>
                </div>
            )}

            {/* Transactions */}
            <div style={{ background: "white", padding: 24, borderRadius: 24, boxShadow: "0 10px 30px rgba(0,0,0,0.03)", border: "1px solid #F1F5F9" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
                    <h3 style={{ fontSize: 18, fontWeight: 700, color: "#1E293B", margin: 0 }}>So'nggi Tranzaksiyalar</h3>
                    <div style={{ padding: "6px 12px", background: "#F8FAFC", borderRadius: 8, fontSize: 12, fontWeight: 600, color: "#64748B" }}>Oxirgi 10 ta tolov</div>
                </div>

                {transactions.length === 0 ? (
                    <div style={{ textAlign: "center", padding: 40 }}>
                        <div style={{ width: 64, height: 64, borderRadius: "50%", background: "#F1F5F9", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 16px" }}>
                            <FaMoneyBillWave size={24} color="#94A3B8" />
                        </div>
                        <p style={{ color: "#94A3B8", fontSize: 14, fontWeight: 500 }}>Hozircha tranzaksiyalar yo'q</p>
                    </div>
                ) : (
                    <div style={{ overflowX: "auto" }}>
                        <table style={{ width: "100%", borderCollapse: "separate", borderSpacing: "0 8px" }}>
                            <thead>
                                <tr style={{ textAlign: "left" }}>
                                    <th style={{ padding: "0 16px 12px", color: "#94A3B8", fontSize: 13, fontWeight: 600 }}>SANA</th>
                                    <th style={{ padding: "0 16px 12px", color: "#94A3B8", fontSize: 13, fontWeight: 600 }}>MIJOZ</th>
                                    <th style={{ padding: "0 16px 12px", color: "#94A3B8", fontSize: 13, fontWeight: 600 }}>XIZMAT</th>
                                    <th style={{ padding: "0 16px 12px", color: "#94A3B8", fontSize: 13, fontWeight: 600 }}>SUMMA</th>
                                    <th style={{ padding: "0 16px 12px", color: "#94A3B8", fontSize: 13, fontWeight: 600, textAlign: "right" }}>HOLAT</th>
                                </tr>
                            </thead>
                            <tbody>
                                {transactions.map((b) => (
                                    <tr key={b.id} style={{ transition: "all 0.2s" }}>
                                        <td style={{ padding: "16px", background: "#F8FAFC", borderRadius: "12px 0 0 12px", fontSize: 14, color: "#64748B", fontWeight: 500 }}>
                                            {b.date}
                                        </td>
                                        <td style={{ padding: "16px", background: "#F8FAFC", fontWeight: 600, color: "#1E293B", fontSize: 14 }}>
                                            {b.client}
                                        </td>
                                        <td style={{ padding: "16px", background: "#F8FAFC", color: "#475569", fontSize: 14 }}>
                                            {b.service}
                                        </td>
                                        <td style={{ padding: "16px", background: "#F8FAFC", fontWeight: 700, color: "#1E293B", fontSize: 15 }}>
                                            {formatPrice(b.price || 0)}
                                        </td>
                                        <td style={{ padding: "16px", background: "#F8FAFC", borderRadius: "0 12px 12px 0", textAlign: "right" }}>
                                            <span style={{
                                                display: "inline-block", padding: "6px 12px", borderRadius: 8,
                                                background: "rgba(212, 175, 55, 0.1)", color: "#B49020",
                                                fontSize: 12, fontWeight: 700, letterSpacing: 0.5
                                            }}>
                                                MUVAFFAQIYATLI
                                            </span>
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
