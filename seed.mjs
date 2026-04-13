import { initializeApp } from "firebase/app";
import { getFirestore, collection, getDocs, addDoc, serverTimestamp, setDoc, doc } from "firebase/firestore";

const firebaseConfig = {
    apiKey: "AIzaSyAzt8n0nHnj_JdoC3ZN5xjEXFX2yO4yWvY",
    authDomain: "sartarosh-eaf90.firebaseapp.com",
    projectId: "sartarosh-eaf90",
    storageBucket: "sartarosh-eaf90.firebasestorage.app",
    messagingSenderId: "328525443303",
    appId: "1:328525443303:web:cf3bb05758bed9cc25f242"
};

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
        createdAt: serverTimestamp(),
    },
];

const bookingsData = [
    { client: "Aziz Mahmudov", barberName: "Sardor Karimov", service: "Soch olish", price: 30000, time: "14:00", date: new Date().toISOString().split("T")[0], status: "confirmed", createdAt: serverTimestamp() },
    { client: "Doston Aliyev", barberName: "Bekzod Aliyev", service: "Soqol olish", price: 15000, time: "15:30", date: new Date().toISOString().split("T")[0], status: "pending", createdAt: serverTimestamp() },
    { client: "Jamshid V.", barberName: "Azizbek Rustamov", service: "Soch + Soqol", price: 50000, time: "17:00", date: new Date().toISOString().split("T")[0], status: "confirmed", createdAt: serverTimestamp() },
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
            console.log("Added barber:", b.name);
        }
        for (const b of bookingsData) {
            await addDoc(bookingsRef, b);
            console.log("Added booking for:", b.client);
        }
        console.log("Base data seeded successfully!");
        process.exit(0);
    } catch (e) {
        console.error("Error seeding:", e);
        process.exit(1);
    }
}

seed();
