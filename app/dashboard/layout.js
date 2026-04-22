"use client";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useState, useEffect } from "react";
import { useAuth } from "../../lib/auth";
import { FaHome, FaCut, FaCalendarCheck, FaWallet, FaCog, FaBars, FaTimes, FaSignOutAlt, FaServer, FaBuilding, FaUserShield, FaComments, FaUsers, FaShieldAlt } from "react-icons/fa";

const menuItems = [
    { name: "Bosh sahifa", href: "/dashboard", icon: FaHome },
    { name: "Sartaroshlar", href: "/dashboard/barbers", icon: FaCut },
    { name: "Bronlar", href: "/dashboard/bookings", icon: FaCalendarCheck },
    { name: "Xizmatlar", href: "/dashboard/services", icon: FaServer },
    { name: "Mijozlar", href: "/dashboard/clients", icon: FaUsers },
    { name: "Filiallar", href: "/dashboard/branches", icon: FaBuilding },
    { name: "Daromad", href: "/dashboard/earnings", icon: FaWallet },
    { name: "Murojaatlar", href: "/dashboard/support", icon: FaComments },
    { name: "Sozlamalar", href: "/dashboard/settings", icon: FaCog },
];

export default function DashboardLayout({ children }) {
    const pathname = usePathname();
    const router = useRouter();
    const { user, loading, isAdmin, logout } = useAuth();
    const [sidebarOpen, setSidebarOpen] = useState(false);

    // 🛡️ AUTH GUARD: Login qilmagan yoki admin bo'lmagan foydalanuvchini login sahifasiga yo'naltirish
    useEffect(() => {
        if (!loading && (!user || !isAdmin)) {
            router.replace("/login");
        }
    }, [user, isAdmin, loading, router]);

    // Yuklanish holati
    if (loading) {
        return (
            <div style={{
                minHeight: "100vh",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                background: "#0F172A",
                color: "#94A3B8",
                fontFamily: "'Inter', sans-serif",
                flexDirection: "column",
                gap: "1rem",
            }}>
                <div style={{
                    width: "48px", height: "48px",
                    border: "3px solid rgba(34,197,94,0.2)",
                    borderTopColor: "#22C55E",
                    borderRadius: "50%",
                    animation: "spin 1s linear infinite",
                }} />
                <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
                <p>Tekshirilmoqda...</p>
            </div>
        );
    }

    // Agar user null bo'lsa, redirect yuzaga kelmoqda
    if (!user || !isAdmin) return null;

    const handleLogout = async () => {
        await logout();
        router.replace("/login");
    };

    return (
        <div className="dashboard-layout">
            {/* Mobile overlay */}
            {sidebarOpen && (
                <div
                    className="fixed inset-0 bg-black/30 z-30 md:hidden"
                    onClick={() => setSidebarOpen(false)}
                />
            )}

            {/* Sidebar */}
            <aside className={`dashboard-sidebar ${sidebarOpen ? 'open' : ''}`}>
                <div className="sidebar-logo">
                    <div className="sidebar-logo-icon">
                        <FaCut />
                    </div>
                    <span className="sidebar-logo-text">Sartarosh</span>
                </div>

                <nav style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
                    {menuItems.map((item) => {
                        const Icon = item.icon;
                        const isActive = pathname === item.href;
                        return (
                            <Link
                                key={item.name}
                                href={item.href}
                                className={`sidebar-nav-item ${isActive ? "active" : ""}`}
                                onClick={() => setSidebarOpen(false)}
                            >
                                <Icon className="nav-icon" />
                                {item.name}
                            </Link>
                        );
                    })}
                </nav>

                {/* Profile card with logout */}
                <div className="sidebar-profile-card">
                    <div className="profile-avatar">
                        <FaShieldAlt size={14} />
                    </div>
                    <div className="profile-info">
                        <h4>{user?.email?.split("@")[0] || "Admin"}</h4>
                        <p>Boshqaruvchi</p>
                    </div>
                    <button
                        onClick={handleLogout}
                        title="Chiqish"
                        style={{
                            background: "rgba(239,68,68,0.1)",
                            border: "1px solid rgba(239,68,68,0.2)",
                            borderRadius: "8px",
                            padding: "8px",
                            cursor: "pointer",
                            color: "#EF4444",
                            marginLeft: "auto",
                            display: "flex",
                            alignItems: "center",
                        }}
                    >
                        <FaSignOutAlt size={14} />
                    </button>
                </div>
            </aside>

            {/* Main */}
            <main className="dashboard-main">
                {/* Mobile menu button */}
                <button
                    className="md:hidden fixed top-4 left-4 z-50 p-2 bg-white rounded-xl shadow-lg border border-gray-200"
                    onClick={() => setSidebarOpen(!sidebarOpen)}
                    style={{ display: "none" }}
                >
                    {sidebarOpen ? <FaTimes size={20} /> : <FaBars size={20} />}
                </button>

                {children}
            </main>
        </div>
    );
}
