"use client";
import { FaBuilding } from "react-icons/fa";

export default function BranchesPage() {
    return (
        <div>
            <div className="dashboard-topbar">
                <div>
                    <h1>Filiallar</h1>
                    <p style={{ color: "#94A3B8", fontSize: 14, marginTop: 2 }}>Filiallarni boshqarish tizimi (Tez kunda...)</p>
                </div>
            </div>
            <div className="dash-card" style={{ textAlign: "center", padding: 60, marginTop: 24 }}>
                <FaBuilding size={48} color="#CBD5E1" style={{ margin: "0 auto 16px" }} />
                <h3 style={{ fontSize: 18, color: "#475569", fontWeight: 600 }}>Filiallar moduli ishlab chiqilmoqda</h3>
                <p style={{ color: "#94A3B8", marginTop: 8 }}>Bu yerda siz filiallar kesimida statistika va hisobotlarni kuzatishingiz mumkin bo'ladi.</p>
            </div>
        </div>
    );
}
