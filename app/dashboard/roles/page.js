"use client";
import { FaUserShield } from "react-icons/fa";

export default function RolesPage() {
    return (
        <div>
            <div className="dashboard-topbar">
                <div>
                    <h1>Rollar va Ruxsatlar</h1>
                    <p style={{ color: "#94A3B8", fontSize: 14, marginTop: 2 }}>Admin, Sartarosh va Mijoz rollarini boshqarish</p>
                </div>
            </div>
            <div className="dash-card" style={{ textAlign: "center", padding: 60, marginTop: 24 }}>
                <FaUserShield size={48} color="#CBD5E1" style={{ margin: "0 auto 16px" }} />
                <h3 style={{ fontSize: 18, color: "#475569", fontWeight: 600 }}>Rol boshqaruvi tez kunda</h3>
                <p style={{ color: "#94A3B8", marginTop: 8 }}>Tizimda foydalanuvchilarning huquqlarini (admin panelga kirish, sozlash imkoniyatlari) belgilash xizmati yaralmoqda.</p>
            </div>
        </div>
    );
}
