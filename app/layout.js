"use client";
import "./globals.css";
import { Toaster } from "react-hot-toast";
import { AuthProvider } from "../lib/auth";

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <head>
        <title>Sartarosh | Admin Dashboard</title>
        <meta name="description" content="Sartarosh backend management portal." />
        <meta name="robots" content="noindex, nofollow" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="antialiased selection:bg-[#22C55E] selection:text-[#0F172A]">
        <AuthProvider>
          <Toaster
            position="top-center"
            toastOptions={{
              duration: 3000,
              style: {
                background: "rgba(255, 255, 255, 0.05)",
                backdropFilter: "blur(10px)",
                color: "#F8FAFC",
                border: "1px solid rgba(255, 255, 255, 0.1)",
                borderRadius: "1rem",
                boxShadow: "0 10px 30px -10px rgba(0, 0, 0, 0.5)",
              },
            }}
          />
          <main>{children}</main>
        </AuthProvider>
      </body>
    </html>
  );
}
