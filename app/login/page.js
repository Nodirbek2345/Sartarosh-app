"use client";
import { useState } from "react";
import { useAuth } from "../../lib/auth";
import { FaCut, FaLock, FaEnvelope, FaEye, FaEyeSlash, FaShieldAlt } from "react-icons/fa";

export default function LoginPage() {
    const { login } = useAuth();
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [error, setError] = useState("");
    const [loading, setLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError("");
        setLoading(true);
        try {
            await login(email.trim().toLowerCase(), password);
        } catch (err) {
            if (err.message.includes("admin sifatida")) {
                setError(err.message);
            } else if (err.code === "auth/invalid-credential" || err.code === "auth/wrong-password") {
                setError("Email yoki parol noto'g'ri!");
            } else if (err.code === "auth/too-many-requests") {
                setError("Juda ko'p urinish! Biroz kutib turing.");
            } else {
                setError("Tizimga kirishda xatolik yuz berdi.");
            }
        }
        setLoading(false);
    };

    return (
        <div style={{
            minHeight: "100vh",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            background: "linear-gradient(135deg, #0F172A 0%, #1E293B 50%, #0F172A 100%)",
            fontFamily: "'Inter', sans-serif",
            padding: "1rem",
        }}>
            <div style={{
                width: "100%",
                maxWidth: "420px",
                background: "rgba(255,255,255,0.03)",
                border: "1px solid rgba(255,255,255,0.08)",
                borderRadius: "24px",
                padding: "2.5rem",
                backdropFilter: "blur(20px)",
                boxShadow: "0 20px 60px -15px rgba(0,0,0,0.5)",
            }}>
                {/* Logo */}
                <div style={{ textAlign: "center", marginBottom: "2rem" }}>
                    <div style={{
                        width: "64px", height: "64px",
                        background: "linear-gradient(135deg, #22C55E, #16A34A)",
                        borderRadius: "16px", display: "flex",
                        alignItems: "center", justifyContent: "center",
                        margin: "0 auto 1rem",
                        boxShadow: "0 8px 24px -4px rgba(34,197,94,0.4)",
                    }}>
                        <FaCut size={28} color="white" />
                    </div>
                    <h1 style={{ color: "#F8FAFC", fontSize: "24px", fontWeight: 700, margin: 0 }}>
                        Sartarosh Admin
                    </h1>
                    <p style={{ color: "#94A3B8", fontSize: "14px", marginTop: "6px" }}>
                        <FaShieldAlt style={{ marginRight: "6px", verticalAlign: "middle" }} />
                        Himoyalangan boshqaruv paneli
                    </p>
                </div>

                {/* Error */}
                {error && (
                    <div style={{
                        background: "rgba(239,68,68,0.1)",
                        border: "1px solid rgba(239,68,68,0.3)",
                        borderRadius: "12px", padding: "12px 16px",
                        color: "#FCA5A5", fontSize: "13px",
                        marginBottom: "1rem", textAlign: "center",
                    }}>
                        ⚠️ {error}
                    </div>
                )}

                {/* Form */}
                <form onSubmit={handleSubmit}>
                    <div style={{ marginBottom: "1rem" }}>
                        <label style={{ color: "#94A3B8", fontSize: "13px", fontWeight: 500, display: "block", marginBottom: "6px" }}>
                            Email
                        </label>
                        <div style={{ position: "relative" }}>
                            <FaEnvelope style={{ position: "absolute", left: "14px", top: "50%", transform: "translateY(-50%)", color: "#64748B" }} />
                            <input
                                type="email"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                placeholder="admin@sartarosh.uz"
                                required
                                style={{
                                    width: "100%", padding: "14px 14px 14px 40px",
                                    background: "rgba(255,255,255,0.05)",
                                    border: "1px solid rgba(255,255,255,0.1)",
                                    borderRadius: "12px", color: "#F8FAFC",
                                    fontSize: "14px", outline: "none",
                                    transition: "border-color 0.2s",
                                    boxSizing: "border-box",
                                }}
                                onFocus={(e) => e.target.style.borderColor = "#22C55E"}
                                onBlur={(e) => e.target.style.borderColor = "rgba(255,255,255,0.1)"}
                            />
                        </div>
                    </div>

                    <div style={{ marginBottom: "1.5rem" }}>
                        <label style={{ color: "#94A3B8", fontSize: "13px", fontWeight: 500, display: "block", marginBottom: "6px" }}>
                            Parol
                        </label>
                        <div style={{ position: "relative" }}>
                            <FaLock style={{ position: "absolute", left: "14px", top: "50%", transform: "translateY(-50%)", color: "#64748B" }} />
                            <input
                                type={showPassword ? "text" : "password"}
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                placeholder="••••••••"
                                required
                                minLength={6}
                                style={{
                                    width: "100%", padding: "14px 44px 14px 40px",
                                    background: "rgba(255,255,255,0.05)",
                                    border: "1px solid rgba(255,255,255,0.1)",
                                    borderRadius: "12px", color: "#F8FAFC",
                                    fontSize: "14px", outline: "none",
                                    transition: "border-color 0.2s",
                                    boxSizing: "border-box",
                                }}
                                onFocus={(e) => e.target.style.borderColor = "#22C55E"}
                                onBlur={(e) => e.target.style.borderColor = "rgba(255,255,255,0.1)"}
                            />
                            <button
                                type="button"
                                onClick={() => setShowPassword(!showPassword)}
                                style={{
                                    position: "absolute", right: "14px", top: "50%",
                                    transform: "translateY(-50%)", background: "none",
                                    border: "none", cursor: "pointer", color: "#64748B",
                                    padding: 0,
                                }}
                            >
                                {showPassword ? <FaEyeSlash /> : <FaEye />}
                            </button>
                        </div>
                    </div>

                    <button
                        type="submit"
                        disabled={loading}
                        style={{
                            width: "100%", padding: "16px",
                            background: loading ? "#64748B" : "linear-gradient(135deg, #22C55E, #16A34A)",
                            border: "none", borderRadius: "14px",
                            color: "white", fontSize: "15px",
                            fontWeight: 700, cursor: loading ? "not-allowed" : "pointer",
                            display: "flex", alignItems: "center", justifyContent: "center",
                            gap: "8px", transition: "all 0.3s",
                            boxShadow: loading ? "none" : "0 8px 24px -4px rgba(34,197,94,0.4)",
                        }}
                    >
                        {loading ? (
                            <span>Tekshirilmoqda...</span>
                        ) : (
                            <>
                                <FaLock size={14} />
                                Kirish
                            </>
                        )}
                    </button>
                </form>

                <p style={{ textAlign: "center", color: "#475569", fontSize: "12px", marginTop: "1.5rem" }}>
                    🔒 Faqat ruxsat etilgan adminlar kirishi mumkin
                </p>
            </div>
        </div>
    );
}
