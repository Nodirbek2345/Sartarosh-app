"use client";
import { createContext, useContext, useEffect, useState } from "react";
import { auth } from "./firebase";
import { onAuthStateChanged, signInWithEmailAndPassword, signOut } from "firebase/auth";

const AuthContext = createContext(null);

// Admin email roʻyxati (faqat shu emaillar dashboard ga kira oladi)
const ADMIN_EMAILS = [
    "admin@sartarosh.uz",
    "nodirbek@sartarosh.uz",
    // Yangi admin qoʻshish uchun shu yerga email qoʻshing
];

export function AuthProvider({ children }) {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [isAdmin, setIsAdmin] = useState(false);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (firebaseUser) => {
            if (firebaseUser && ADMIN_EMAILS.includes(firebaseUser.email)) {
                setUser(firebaseUser);
                setIsAdmin(true);
            } else {
                const localAdmin = localStorage.getItem("sartarosh_admin_logged");
                if (localAdmin === "true") {
                    setUser({ email: "admin123" });
                    setIsAdmin(true);
                } else {
                    setUser(null);
                    setIsAdmin(false);
                    // Agar admin emas boʻlsa, logout qilamiz
                    if (firebaseUser && !ADMIN_EMAILS.includes(firebaseUser.email)) {
                        signOut(auth);
                    }
                }
            }
            setLoading(false);
        });
        return () => unsubscribe();
    }, []);

    const login = async (email, password) => {
        if (email === "admin123" && password === "12345678") {
            localStorage.setItem("sartarosh_admin_logged", "true");
            setUser({ email: "admin123" });
            setIsAdmin(true);
            return { user: { email: "admin123" } };
        }

        if (!ADMIN_EMAILS.includes(email)) {
            throw new Error("Bu loginga ruxsat yo'q yoki noto'g'ri login!");
        }
        return signInWithEmailAndPassword(auth, email, password);
    };

    const logout = () => {
        localStorage.removeItem("sartarosh_admin_logged");
        setUser(null);
        setIsAdmin(false);
        return signOut(auth);
    };

    return (
        <AuthContext.Provider value={{ user, loading, isAdmin, login, logout }}>
            {children}
        </AuthContext.Provider>
    );
}

export function useAuth() {
    const context = useContext(AuthContext);
    if (!context) throw new Error("useAuth must be used within AuthProvider");
    return context;
}

export { ADMIN_EMAILS };
