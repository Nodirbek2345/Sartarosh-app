"use client";
import { useState, useEffect } from "react";
import { FaServer, FaPlus, FaEdit, FaTrash, FaSpinner, FaTimes } from "react-icons/fa";
import { onServicesSnapshot, addService, updateService, deleteService } from "@/lib/firestore";
import toast from "react-hot-toast";

export default function ServicesPage() {
    const [services, setServices] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editMode, setEditMode] = useState(false);
    const [saving, setSaving] = useState(false);
    const [activeTab, setActiveTab] = useState("male");

    const emptyForm = { name: "", category: "Soch olish", gender: "male" };
    const [form, setForm] = useState({ ...emptyForm });

    useEffect(() => {
        const unsub = onServicesSnapshot((data) => {
            setServices(data);
            setLoading(false);
        });
        return () => unsub();
    }, []);

    const openAddModal = () => {
        setForm({ ...emptyForm, gender: activeTab });
        setEditMode(false);
        setShowModal(true);
    };

    const openEditModal = (service) => {
        setForm({ ...emptyForm, ...service });
        setEditMode(true);
        setShowModal(true);
    };

    const handleSave = async () => {
        if (!form.name.trim()) {
            toast.error("Nomini to'g'ri kiriting!");
            return;
        }
        setSaving(true);
        try {
            const dataToSave = { name: form.name.trim(), category: form.category, gender: form.gender };
            if (editMode && form.id) {
                await updateService(form.id, dataToSave);
                toast.success("Xizmat yangilandi!");
            } else {
                await addService(dataToSave);
                toast.success("Yangi xizmat qo'shildi!");
            }
            setShowModal(false);
        } catch (err) {
            toast.error("Xatolik: " + err.message);
        }
        setSaving(false);
    };

    const handleDelete = async (id, name) => {
        if (!confirm(`"${name}" xizmatini o'chirishni xohlaysizmi?`)) return;
        try {
            await deleteService(id);
            toast.success("O'chirildi!");
        } catch (err) {
            toast.error("Xatolik: " + err.message);
        }
    };

    if (loading) {
        return (
            <div style={{ textAlign: "center", padding: 60, color: "#94A3B8" }}>
                <FaSpinner size={32} className="animate-spin" style={{ margin: "0 auto 16px" }} />
                <p>Yuklanmoqda...</p>
            </div>
        );
    }

    const filteredServices = services.filter((s) => {
        const gen = s.gender || "male";
        if (activeTab === "all") return true;
        return gen === activeTab;
    });

    return (
        <div>
            <div className="dashboard-topbar">
                <div>
                    <h1>Xizmatlar</h1>
                    <p style={{ color: "#94A3B8", fontSize: 14, marginTop: 2 }}>Jami {services.length} ta xizmat</p>
                </div>
                <button onClick={openAddModal} className="dash-btn-primary" style={{ display: "flex", alignItems: "center", gap: 6 }}>
                    <FaPlus /> Yangi xizmat
                </button>
            </div>

            {/* TABS */}
            <div style={{ display: 'flex', gap: 16, marginBottom: 20, borderBottom: '1px solid #E2E8F0' }}>
                <button
                    onClick={() => setActiveTab('male')}
                    style={{
                        padding: '12px 16px', background: 'none', border: 'none',
                        borderBottom: activeTab === 'male' ? '3px solid #3B82F6' : '3px solid transparent',
                        color: activeTab === 'male' ? '#3B82F6' : '#64748B',
                        fontWeight: activeTab === 'male' ? 700 : 500, cursor: 'pointer', fontSize: 15
                    }}>
                    Erkaklar u-n
                </button>
                <button
                    onClick={() => setActiveTab('female')}
                    style={{
                        padding: '12px 16px', background: 'none', border: 'none',
                        borderBottom: activeTab === 'female' ? '3px solid #EC4899' : '3px solid transparent', // Pink for female
                        color: activeTab === 'female' ? '#EC4899' : '#64748B',
                        fontWeight: activeTab === 'female' ? 700 : 500, cursor: 'pointer', fontSize: 15
                    }}>
                    Ayollar u-n
                </button>
            </div>

            <div className="dash-card">
                {filteredServices.length === 0 ? (
                    <div style={{ textAlign: "center", padding: 40, color: "#94A3B8", fontSize: 14 }}>
                        Bu turga oid xizmat topilmadi
                    </div>
                ) : (
                    <table className="dash-table">
                        <thead>
                            <tr>
                                <th>Nomi</th>
                                <th>Kategoriya</th>
                                <th>Amallar</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredServices.map((s) => (
                                <tr key={s.id}>
                                    <td style={{ fontWeight: 600 }}>{s.name}</td>
                                    <td>
                                        <span className="badge badge-info" style={{ background: activeTab === 'female' ? '#FCE7F3' : '#EFF6FF', color: activeTab === 'female' ? '#BE185D' : '#1D4ED8' }}>{s.category || 'Umumiy'}</span>
                                    </td>
                                    <td>
                                        <div style={{ display: "flex", gap: 8 }}>
                                            <button onClick={() => openEditModal(s)}
                                                style={{ background: "#EFF6FF", color: "#3B82F6", border: "none", padding: "6px 10px", borderRadius: 8, cursor: "pointer", fontSize: 12 }}>
                                                <FaEdit />
                                            </button>
                                            <button onClick={() => handleDelete(s.id, s.name)}
                                                style={{ background: "#FEE2E2", color: "#DC2626", border: "none", padding: "6px 10px", borderRadius: 8, cursor: "pointer", fontSize: 12 }}>
                                                <FaTrash />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>

            {/* Modal */}
            {showModal && (
                <div style={{
                    position: "fixed", inset: 0, background: "rgba(0,0,0,0.4)",
                    display: "flex", alignItems: "center", justifyContent: "center", zIndex: 100
                }} onClick={() => setShowModal(false)}>
                    <div style={{
                        background: "white", borderRadius: 20, padding: 32,
                        width: "90%", maxWidth: 480
                    }} onClick={(e) => e.stopPropagation()}>
                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
                            <h2 style={{ fontSize: 20, fontWeight: 700, color: "#1E293B" }}>
                                {editMode ? "Xizmatni tahrirlash" : "Yangi xizmat"}
                            </h2>
                            <button onClick={() => setShowModal(false)} style={{ background: "#F1F5F9", border: "none", borderRadius: 8, padding: 8, cursor: "pointer", color: "#64748B" }}>
                                <FaTimes />
                            </button>
                        </div>

                        <div className="dash-form-group">
                            <label>Xizmat nomi</label>
                            <input value={form.name} onChange={(e) => setForm(p => ({ ...p, name: e.target.value }))} placeholder="Masalan: Soch olish" />
                        </div>
                        <div className="dash-form-group">
                            <label>Kategoriya</label>
                            <input
                                list="categories-list"
                                value={form.category}
                                onChange={(e) => setForm(p => ({ ...p, category: e.target.value }))}
                                placeholder="O'zingiz kiriting yoki tanlang"
                            />
                            <datalist id="categories-list">
                                <option value="Soch olish" />
                                <option value="Soqol olish" />
                                <option value="Kompleks" />
                                <option value="Maxsus" />
                                <option value="Soch turmak" />
                                <option value="Makiyaj" />
                                <option value="Manikyur" />
                            </datalist>
                        </div>
// Jinsi formdan olib tashlandi, chunki avtomatik aktiv tabga qarab belgilanadi

                        <div style={{ display: "flex", gap: 12, justifyContent: "flex-end", marginTop: 24 }}>
                            <button onClick={() => setShowModal(false)} style={{
                                padding: "10px 24px", borderRadius: 10, border: "none", background: "#F1F5F9", color: "#475569", fontWeight: 600, cursor: "pointer"
                            }}>Bekor qilish</button>
                            <button onClick={handleSave} disabled={saving} className="dash-btn-primary" style={{ display: "flex", alignItems: "center", gap: 8 }}>
                                {saving ? <FaSpinner className="animate-spin" /> : null}
                                Saqlash
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
