"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { FaHome, FaCut, FaCalendarCheck, FaWallet, FaCog, FaBars, FaTimes, FaSignOutAlt, FaServer, FaBuilding, FaUserShield, FaComments, FaUsers } from "react-icons/fa";

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
    const [sidebarOpen, setSidebarOpen] = useState(false);

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

                {/* Profile card */}
                <div className="sidebar-profile-card">
                    <div className="profile-avatar">A</div>
                    <div className="profile-info">
                        <h4>Admin</h4>
                        <p>Boshqaruvchi</p>
                    </div>
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
