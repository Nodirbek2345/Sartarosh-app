import { initializeApp } from "firebase/app";
import { getFirestore, collection, getDocs, addDoc, serverTimestamp, setDoc, doc } from "firebase/firestore";

// ⚠️ Firebase config .env.local dan olinadi (xavfsizlik uchun)
// Bu faylni GitHub ga push QILMANG!
const firebaseConfig = {
    apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
    authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
    storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID
};

// Config tekshiruvi
if (!firebaseConfig.apiKey || !firebaseConfig.projectId) {
    console.error("❌ Firebase config topilmadi! .env.local faylini tekshiring.");
    console.error("   Maslahat: dotenv paketini o'rnating yoki env o'zgaruvchilarini qo'lda export qiling.");
    process.exit(1);
}

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const barbersRef = collection(db, "barbers");
const bookingsRef = collection(db, "bookings");

const barbersData = [
    {
        name: "Sardor Karimov",
        rating: 4.9,
        reviewCount: 127,
        experience: 8,
        address: "Toshkent, Chilonzor tumani, 7-mavze",
        phone: "+998 90 111 22 33",
        image: "https://i.pravatar.cc/400?u=sardor",
        about: "Professional sartarosh, 8 yillik tajriba. Zamonaviy va klassik soch turmak uslublarida mutaxassis.",
        workingHours: { open: "09:00", close: "20:00" },
        services: [
            { name: "Soch olish", price: 30000, duration: 30 },
            { name: "Soqol olish", price: 20000, duration: 20 },
            { name: "Soch + Soqol", price: 45000, duration: 45 },
            { name: "Premium styling", price: 60000, duration: 50 },
        ],
        tags: ["Premium", "Top Rated"],
        isActive: true,
        createdAt: serverTimestamp(),
    },
    {
        name: "Bekzod Aliyev",
        rating: 4.7,
        reviewCount: 89,
        experience: 5,
        address: "Toshkent, Yunusobod tumani, 14-mavze",
        phone: "+998 91 222 33 44",
        image: "https://i.pravatar.cc/400?u=bekzod",
        about: "Kreativ soch turmaklari bo'yicha mutaxassis.",
        workingHours: { open: "10:00", close: "21:00" },
        services: [
            { name: "Soch olish", price: 25000, duration: 30 },
            { name: "Soqol olish", price: 15000, duration: 20 },
            { name: "Soch + Soqol", price: 35000, duration: 45 },
        ],
        tags: ["Kreativ", "Zamonaviy"],
        isActive: true,
        createdAt: serverTimestamp(),
    },
    {
        name: "Azizbek Rustamov",
        rating: 4.8,
        reviewCount: 156,
        experience: 10,
        address: "Toshkent, Mirzo Ulug'bek tumani",
        phone: "+998 93 333 44 55",
        image: "https://i.pravatar.cc/400?u=azizbek",
        about: "10 yillik tajribaga ega usta. Klassik va zamonaviy uslublarni mukammal biladi.",
        workingHours: { open: "08:00", close: "19:00" },
        services: [
            { name: "Soch olish", price: 35000, duration: 30 },
            { name: "Soqol olish", price: 25000, duration: 20 },
            { name: "Soch + Soqol", price: 50000, duration: 50 },
            { name: "VIP xizmat", price: 100000, duration: 90 },
        ],
        tags: ["VIP", "Tajribali", "Top Rated"],
        isActive: true,
        createdAt: serverTimestamp(),
    },
];

async function seed() {
    console.log("Seeding started...");

    const snapshot = await getDocs(barbersRef);
    if (!snapshot.empty) {
        console.log("Database is already seeded with", snapshot.size, "barbers.");
        process.exit(0);
        return;
    }

    try {
        for (const b of barbersData) {
            await addDoc(barbersRef, b);
            console.log("✅ Added barber:", b.name);
        }
        console.log("Base data seeded successfully!");
        process.exit(0);
    } catch (e) {
        console.error("❌ Error seeding:", e);
        process.exit(1);
    }
}

seed();
