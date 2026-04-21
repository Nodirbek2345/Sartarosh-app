"use client";
import { useState, useEffect } from "react";
import { FaBuilding, FaPlus, FaEdit, FaTrash, FaSpinner, FaMapMarkerAlt, FaPhone, FaUserTie } from "react-icons/fa";
import { onBranchesSnapshot, addBranch, updateBranch, deleteBranch } from "@/lib/firestore";
import toast from "react-hot-toast";

export default function BranchesPage() {
    const [branches, setBranches] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingId, setEditingId] = useState(null);
    const [saving, setSaving] = useState(false);

    const [form, setForm] = useState({
        name: "",
        address: "",
        phone: "",
        manager: "",
    });

    useEffect(() => {
        const unsub = onBranchesSnapshot((data) => {
            setBranches(data);
            setLoading(false);
        });
        return () => unsub();
    }, []);

    const handleOpenAdd = () => {
        setForm({ name: "", address: "", phone: "", manager: "" });
        setEditingId(null);
        setShowModal(true);
    };

    const handleOpenEdit = (branch) => {
        setForm({
            name: branch.name || "",
            address: branch.address || "",
            phone: branch.phone || "",
            manager: branch.manager || "",
        });
        setEditingId(branch.id);
        setShowModal(true);
    };

    const handleDelete = async (id) => {
        if (!confirm("Ushbu filialni o'chirishni xohlaysizmi?")) return;
        try {
            await deleteBranch(id);
            toast.success("Filial o'chirildi");
        } catch (e) {
            toast.error("Xatolik yuz berdi");
        }
    };

    const handleSave = async (e) => {
        e.preventDefault();
        setSaving(true);
        try {
            if (editingId) {
                await updateBranch(editingId, form);
                toast.success("Filial yangilandi");
            } else {
                await addBranch(form);
                toast.success("Yangi filial qo'shildi");
            }
            setShowModal(false);
        } catch (e) {
            toast.error("Xatolik yuz berdi: " + e.message);
        }
        setSaving(false);
    };

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
                    <h1>Filiallar</h1>
                    <p style={{ color: "#94A3B8", fontSize: 14, marginTop: 2 }}>Biznesingizning barcha nuqtalarini boshqaring</p>
                </div>
                <button className="dash-btn-primary" onClick={handleOpenAdd} style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <FaPlus /> Filial qo'shish
                </button>
            </div>

            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))", gap: 20 }}>
                {branches.length === 0 ? (
                    <div style={{ gridColumn: "1 / -1", textAlign: "center", padding: 40, color: "#94A3B8" }}>
                        <FaBuilding size={48} color="#E2E8F0" style={{ margin: "0 auto 16px" }} />
                        <p>Hozircha filiallar qo'shilmagan</p>
                    </div>
                ) : (
                    branches.map(branch => (
                        <div key={branch.id} className="dash-card" style={{ position: "relative", padding: 24 }}>
                            <div style={{ position: "absolute", top: 20, right: 20, display: "flex", gap: 8 }}>
                                <button onClick={() => handleOpenEdit(branch)} style={{ color: "#3B82F6", background: "none", border: "none", cursor: "pointer", padding: 4 }}>
                                    <FaEdit size={16} />
                                </button>
                                <button onClick={() => handleDelete(branch.id)} style={{ color: "#EF4444", background: "none", border: "none", cursor: "pointer", padding: 4 }}>
                                    <FaTrash size={16} />
                                </button>
                            </div>

                            <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
                                <div style={{ width: 44, height: 44, borderRadius: 12, background: "#F1F5F9", color: "#64748B", display: "flex", alignItems: "center", justifyContent: "center" }}>
                                    <FaBuilding size={20} />
                                </div>
                                <div>
                                    <h3 style={{ fontSize: 18, fontWeight: 700, color: "#1E293B" }}>{branch.name || "Nomsiz filial"}</h3>
                                    <span style={{ fontSize: 12, color: "#10B981", background: "#D1FAE5", padding: "2px 8px", borderRadius: 12, fontWeight: 600 }}>Faol</span>
                                </div>
                            </div>

                            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                                <div style={{ display: "flex", alignItems: "flex-start", gap: 10, color: "#64748B", fontSize: 14 }}>
                                    <FaMapMarkerAlt style={{ marginTop: 3, flexShrink: 0, color: "#94A3B8" }} />
                                    <span>{branch.address || "Ko'rsatilmagan"}</span>
                                </div>
                                <div style={{ display: "flex", alignItems: "center", gap: 10, color: "#64748B", fontSize: 14 }}>
                                    <FaPhone style={{ flexShrink: 0, color: "#94A3B8" }} />
                                    <span>{branch.phone || "Ko'rsatilmagan"}</span>
                                </div>
                                <div style={{ display: "flex", alignItems: "center", gap: 10, color: "#64748B", fontSize: 14 }}>
                                    <FaUserTie style={{ flexShrink: 0, color: "#94A3B8" }} />
                                    <span>{branch.manager || "Menejer belgilanmagan"}</span>
                                </div>
                            </div>
                        </div>
                    ))
                )}
            </div>

            {/* Modal */}
            {showModal && (
                <div style={{
                    position: "fixed", inset: 0, zIndex: 50,
                    display: "flex", alignItems: "center", justifyContent: "center",
                    padding: 20
                }}>
                    <div style={{ position: "absolute", inset: 0, background: "rgba(15,23,42,0.3)", backdropFilter: "blur(4px)" }} onClick={() => setShowModal(false)} />

                    <div style={{
                        position: "relative", background: "white", borderRadius: 20,
                        width: "100%", maxWidth: 500, padding: 30,
                        boxShadow: "0 20px 25px -5px rgba(0,0,0,0.1), 0 10px 10px -5px rgba(0,0,0,0.04)"
                    }}>
                        <h2 style={{ fontSize: 20, fontWeight: 700, color: "#1E293B", marginBottom: 24 }}>
                            {editingId ? "Filialni tahrirlash" : "Yangi filial qo'shish"}
                        </h2>

                        <form onSubmit={handleSave} style={{ display: "flex", flexDirection: "column", gap: 16 }}>
                            <div className="dash-form-group" style={{ marginBottom: 0 }}>
                                <label>Filial nomi</label>
                                <input required value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} placeholder="Masalan: Chilonzor filial" />
                            </div>
                            <div className="dash-form-group" style={{ marginBottom: 0 }}>
                                <label>Manzil</label>
                                <input required value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} placeholder="To'liq manzil" />
                            </div>
                            <div className="dash-form-group" style={{ marginBottom: 0 }}>
                                <label>Aloqa uchun telefon</label>
                                <input required value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} placeholder="+998 90 123 45 67" />
                            </div>
                            <div className="dash-form-group" style={{ marginBottom: 0 }}>
                                <label>Mas'ul menejer (Ixtiyoriy)</label>
                                <input value={form.manager} onChange={e => setForm({ ...form, manager: e.target.value })} placeholder="Ism familiya" />
                            </div>

                            <div style={{ display: "flex", gap: 12, marginTop: 16 }}>
                                <button type="button" onClick={() => setShowModal(false)} className="dash-btn-secondary" style={{ flex: 1, padding: "12px 0", background: "#F1F5F9", color: "#475569", border: "none" }}>
                                    Bekor qilish
                                </button>
                                <button type="submit" disabled={saving} className="dash-btn-primary" style={{ flex: 1, padding: "12px 0", display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}>
                                    {saving && <FaSpinner className="animate-spin" />}
                                    {editingId ? "Saqlash" : "Qo'shish"}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
