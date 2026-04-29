"use client";
import { useState, useEffect } from "react";
import { FaComments, FaSearch, FaSpinner, FaUser, FaRobot, FaCheck, FaClock, FaExclamationTriangle, FaTrash } from "react-icons/fa";
import { db } from "@/lib/firebase";
import { collection, query, orderBy, onSnapshot, deleteDoc, doc, updateDoc, serverTimestamp } from "firebase/firestore";
import toast from "react-hot-toast";

const statusColors = {
    new: { bg: "#FEF3C7", color: "#D97706", label: "Yangi" },
    answered: { bg: "#DCFCE7", color: "#16A34A", label: "Javob berilgan" },
    resolved: { bg: "#DBEAFE", color: "#2563EB", label: "Hal qilingan" },
};

export default function SupportPage() {
    const [messages, setMessages] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState("");
    const [filter, setFilter] = useState("all"); // all, new, answered

    useEffect(() => {
        const q = query(
            collection(db, "app_feedbacks"),
            orderBy("createdAt", "desc")
        );
        const unsub = onSnapshot(q, (snap) => {
            const data = snap.docs.map((d) => ({
                id: d.id,
                status: "new", // default if not set
                ...d.data(),
                createdAt: d.data().createdAt?.toDate?.() || new Date(),
            }));
            setMessages(data);
            setLoading(false);
        });
        return () => unsub();
    }, []);

    const handleDelete = async (id) => {
        if (!window.confirm("Bu murojaatni o'chirmoqchimisiz?")) return;
        try {
            await deleteDoc(doc(db, "app_feedbacks", id));
            toast.success("Murojaat o'chirildi");
        } catch (e) {
            toast.error("Xatolik yuz berdi");
        }
    };

    const handleResolve = async (id) => {
        try {
            await updateDoc(doc(db, "app_feedbacks", id), {
                status: "resolved",
                resolvedAt: serverTimestamp(),
            });
            toast.success("Hal qilingan deb belgilandi ✅");
        } catch (e) {
            toast.error("Xatolik yuz berdi");
        }
    };

    const filtered = messages.filter((m) => {
        const matchSearch =
            m.message?.toLowerCase().includes(search.toLowerCase()) ||
            m.name?.toLowerCase().includes(search.toLowerCase());
        if (filter === "all") return matchSearch;
        return matchSearch && m.status === filter;
    });

    const newCount = messages.filter((m) => m.status === "new").length;

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
            {/* Header */}
            <div className="dashboard-topbar">
                <div>
                    <h1 style={{ display: "flex", alignItems: "center", gap: 12 }}>
                        <FaComments style={{ color: "#4F6BED" }} />
                        Murojaatlar
                        {newCount > 0 && (
                            <span style={{
                                background: "#EF4444",
                                color: "white",
                                fontSize: 13,
                                padding: "2px 10px",
                                borderRadius: 20,
                                fontWeight: 600,
                            }}>
                                {newCount} ta yangi
                            </span>
                        )}
                    </h1>
                    <p style={{ color: "#94A3B8", fontSize: 14, marginTop: 2 }}>
                        Jami {messages.length} ta foydalanuvchi qoldirgan taklif/shikoyatlar
                    </p>
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <div className="dashboard-search">
                        <FaSearch className="search-icon" />
                        <input
                            placeholder="Qidirish..."
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                    </div>
                </div>
            </div>

            {/* Filters */}
            <div style={{ display: "flex", gap: 8, marginBottom: 20, flexWrap: "wrap" }}>
                {[
                    { key: "all", label: "Hammasi" },
                    { key: "new", label: "Yangilar" },
                    { key: "answered", label: "Javob berilgan" },
                    { key: "resolved", label: "Hal qilingan" },
                ].map((f) => (
                    <button
                        key={f.key}
                        onClick={() => setFilter(f.key)}
                        style={{
                            padding: "8px 20px",
                            borderRadius: 20,
                            border: "none",
                            cursor: "pointer",
                            fontWeight: 600,
                            fontSize: 14,
                            background: filter === f.key ? "#4F6BED" : "#F1F5F9",
                            color: filter === f.key ? "white" : "#64748B",
                            transition: "all 0.2s",
                        }}
                    >
                        {f.label}
                    </button>
                ))}
            </div>

            {/* Messages list */}
            {filtered.length === 0 ? (
                <div style={{
                    textAlign: "center",
                    padding: 60,
                    color: "#94A3B8",
                    background: "white",
                    borderRadius: 16,
                }}>
                    <FaComments size={40} style={{ margin: "0 auto 16px", opacity: 0.3 }} />
                    <p>Hozircha murojaatlar yo&apos;q</p>
                </div>
            ) : (
                <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                    {filtered.map((m) => {
                        const status = statusColors[m.status] || statusColors.new;
                        return (
                            <div
                                key={m.id}
                                style={{
                                    background: "white",
                                    borderRadius: 16,
                                    padding: 20,
                                    border: "1px solid #F1F5F9",
                                    boxShadow: "0 1px 3px rgba(0,0,0,0.04)",
                                    transition: "all 0.2s",
                                }}
                            >
                                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 12 }}>
                                    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                                        <div style={{
                                            width: 40,
                                            height: 40,
                                            borderRadius: 12,
                                            background: "#EEF2FF",
                                            display: "flex",
                                            alignItems: "center",
                                            justifyContent: "center",
                                        }}>
                                            <FaUser style={{ color: "#4F6BED" }} />
                                        </div>
                                        <div>
                                            <div style={{ fontWeight: 600, color: "#1E293B", fontSize: 15, display: "flex", alignItems: "center", gap: 8 }}>
                                                {m.name || "Noma'lum"}
                                                {m.role === "barber" ? (
                                                    <span style={{ fontSize: 10, background: "#FEF3C7", color: "#D97706", padding: "2px 6px", borderRadius: 4 }}>Usta</span>
                                                ) : m.role === "client" ? (
                                                    <span style={{ fontSize: 10, background: "#EEF2FF", color: "#4F6BED", padding: "2px 6px", borderRadius: 4 }}>Mijoz</span>
                                                ) : null}
                                            </div>
                                            <div style={{ color: "#94A3B8", fontSize: 12 }}>
                                                {m.phone || m.uid} • {m.createdAt.toLocaleString("uz-UZ")}
                                            </div>
                                        </div>
                                    </div>
                                    <span style={{
                                        background: status.bg,
                                        color: status.color,
                                        padding: "4px 12px",
                                        borderRadius: 20,
                                        fontSize: 12,
                                        fontWeight: 600,
                                    }}>
                                        {status.label}
                                    </span>
                                </div>

                                <div style={{
                                    background: "#F8FAFC",
                                    borderRadius: 12,
                                    padding: 16,
                                    marginBottom: 12,
                                    fontSize: 14,
                                    color: "#334155",
                                    lineHeight: 1.6,
                                    whiteSpace: "pre-wrap",
                                }}>
                                    {m.message}
                                </div>

                                <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
                                    {m.status !== "resolved" && (
                                        <button
                                            onClick={() => handleResolve(m.id)}
                                            style={{
                                                padding: "6px 16px",
                                                borderRadius: 10,
                                                border: "none",
                                                cursor: "pointer",
                                                fontWeight: 600,
                                                fontSize: 13,
                                                background: "#DCFCE7",
                                                color: "#16A34A",
                                                display: "flex",
                                                alignItems: "center",
                                                gap: 6,
                                            }}
                                        >
                                            <FaCheck size={12} /> Hal qilindi
                                        </button>
                                    )}
                                    <button
                                        onClick={() => handleDelete(m.id)}
                                        style={{
                                            padding: "6px 16px",
                                            borderRadius: 10,
                                            border: "none",
                                            cursor: "pointer",
                                            fontWeight: 600,
                                            fontSize: 13,
                                            background: "#FEE2E2",
                                            color: "#DC2626",
                                            display: "flex",
                                            alignItems: "center",
                                            gap: 6,
                                        }}
                                    >
                                        <FaTrash size={12} /> O&apos;chirish
                                    </button>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
}
