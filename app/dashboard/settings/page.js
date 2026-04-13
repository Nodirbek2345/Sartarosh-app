"use client";
import { useState, useEffect } from "react";
import { FaSave, FaUser, FaClock, FaBell, FaSpinner } from "react-icons/fa";
import { getSettings, saveSettings } from "@/lib/firestore";
import toast from "react-hot-toast";
import { doc, setDoc, serverTimestamp } from "firebase/firestore";
import { db } from "@/lib/firebase";

export default function SettingsPage() {
    const [form, setForm] = useState({
        name: "", phone: "", email: "", address: "", about: "",
        workingHours: { open: "09:00", close: "20:00" },
        restDay: "sunday",
        notifications: { newBooking: true, cancellation: true, email: false, sms: true },
    });
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);

    useEffect(() => {
        getSettings().then((data) => {
            if (data) setForm(data);
            setLoading(false);
        }).catch(() => setLoading(false));
    }, []);

    const handleSave = async (e) => {
        e.preventDefault();
        setSaving(true);
        try {
            // settings hujjati mavjud bo'lmasa yaratish
            try {
                await saveSettings(form);
            } catch {
                await setDoc(doc(db, "settings", "main"), {
                    ...form,
                    createdAt: serverTimestamp(),
                });
            }
            toast.success("Sozlamalar saqlandi!");
        } catch (err) {
            toast.error("Xatolik: " + err.message);
        }
        setSaving(false);
    };

    const updateField = (field, value) => setForm((p) => ({ ...p, [field]: value }));
    const updateNotif = (field, value) => setForm((p) => ({
        ...p, notifications: { ...p.notifications, [field]: value }
    }));

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
                    <h1>Sozlamalar</h1>
                    <p style={{ color: "#94A3B8", fontSize: 14, marginTop: 2 }}>Hisobingizni boshqaring</p>
                </div>
            </div>

            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(400px, 1fr))", gap: 24 }}>
                {/* Profile */}
                <div className="dash-card">
                    <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 24 }}>
                        <div style={{
                            width: 36, height: 36, borderRadius: 10,
                            background: "#DBEAFE", color: "#3B82F6",
                            display: "flex", alignItems: "center", justifyContent: "center"
                        }}>
                            <FaUser />
                        </div>
                        <h3 style={{ fontSize: 16, fontWeight: 700, color: "#1E293B" }}>Profil ma'lumotlari</h3>
                    </div>

                    <form onSubmit={handleSave}>
                        <div className="dash-form-group">
                            <label>Ism</label>
                            <input value={form.name || ""} onChange={(e) => updateField("name", e.target.value)} />
                        </div>
                        <div className="dash-form-group">
                            <label>Telefon raqami</label>
                            <input value={form.phone || ""} onChange={(e) => updateField("phone", e.target.value)} />
                        </div>
                        <div className="dash-form-group">
                            <label>Email</label>
                            <input value={form.email || ""} onChange={(e) => updateField("email", e.target.value)} />
                        </div>
                        <div className="dash-form-group">
                            <label>Manzil</label>
                            <input value={form.address || ""} onChange={(e) => updateField("address", e.target.value)} />
                        </div>
                        <div className="dash-form-group">
                            <label>Haqida</label>
                            <textarea rows={3} value={form.about || ""} onChange={(e) => updateField("about", e.target.value)} />
                        </div>
                        <button type="submit" disabled={saving} className="dash-btn-primary"
                            style={{ display: "flex", alignItems: "center", gap: 8 }}>
                            {saving ? <FaSpinner className="animate-spin" /> : <FaSave />}
                            {saving ? "Saqlanmoqda..." : "Saqlash"}
                        </button>
                    </form>
                </div>

                <div>
                    {/* Working hours */}
                    <div className="dash-card" style={{ marginBottom: 24 }}>
                        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 24 }}>
                            <div style={{
                                width: 36, height: 36, borderRadius: 10,
                                background: "#DCFCE7", color: "#22C55E",
                                display: "flex", alignItems: "center", justifyContent: "center"
                            }}>
                                <FaClock />
                            </div>
                            <h3 style={{ fontSize: 16, fontWeight: 700, color: "#1E293B" }}>Ish vaqti</h3>
                        </div>

                        <div className="dash-form-group">
                            <label>Ochilish vaqti</label>
                            <input type="time" value={form.workingHours?.open || "09:00"}
                                onChange={(e) => setForm((p) => ({ ...p, workingHours: { ...p.workingHours, open: e.target.value } }))} />
                        </div>
                        <div className="dash-form-group">
                            <label>Yopilish vaqti</label>
                            <input type="time" value={form.workingHours?.close || "20:00"}
                                onChange={(e) => setForm((p) => ({ ...p, workingHours: { ...p.workingHours, close: e.target.value } }))} />
                        </div>
                        <div className="dash-form-group">
                            <label>Dam olish kunlari</label>
                            <select value={form.restDay || "sunday"}
                                onChange={(e) => updateField("restDay", e.target.value)}>
                                <option value="sunday">Yakshanba</option>
                                <option value="saturday">Shanba</option>
                                <option value="none">Dam olish yo'q</option>
                            </select>
                        </div>
                    </div>

                    {/* Notifications */}
                    <div className="dash-card">
                        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 24 }}>
                            <div style={{
                                width: 36, height: 36, borderRadius: 10,
                                background: "#FEF3C7", color: "#F59E0B",
                                display: "flex", alignItems: "center", justifyContent: "center"
                            }}>
                                <FaBell />
                            </div>
                            <h3 style={{ fontSize: 16, fontWeight: 700, color: "#1E293B" }}>Bildirishnomalar</h3>
                        </div>

                        {[
                            { key: "newBooking", label: "Yangi bron bildirishnomalari" },
                            { key: "cancellation", label: "Bekor qilish bildirishnomalari" },
                            { key: "email", label: "Email bildirishnomalar" },
                            { key: "sms", label: "SMS bildirishnomalar" },
                        ].map((item, idx) => (
                            <label key={item.key} style={{
                                display: "flex", alignItems: "center", justifyContent: "space-between",
                                padding: "12px 0",
                                borderBottom: idx < 3 ? "1px solid #F1F5F9" : "none",
                                cursor: "pointer"
                            }}>
                                <span style={{ fontSize: 14, color: "#1E293B" }}>{item.label}</span>
                                <input
                                    type="checkbox"
                                    checked={form.notifications?.[item.key] || false}
                                    onChange={(e) => updateNotif(item.key, e.target.checked)}
                                    style={{ width: 18, height: 18, accentColor: "#3B82F6", cursor: "pointer" }}
                                />
                            </label>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}
