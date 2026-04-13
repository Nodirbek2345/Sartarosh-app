const { initializeApp } = require("firebase/app");
const { getFirestore, collection, getDocs, addDoc, serverTimestamp, setDoc, doc } = require("firebase/firestore");

const firebaseConfig = {
    apiKey: "dummy",
    authDomain: "sartarosh-app.firebaseapp.com",
    projectId: "sartarosh-app",
    storageBucket: "sartarosh-app.appspot.com",
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
];

async function seed() {
    console.log("Seeding started...");

    // Check if empty
    const snapshot = await getDocs(barbersRef);
    if (!snapshot.empty) {
        console.log("Database is already seeded with", snapshot.size, "barbers.");
        return;
    }

    try {
        for (const b of barbersData) {
            await addDoc(barbersRef, b);
            console.log("Added barber:", b.name);
        }
        console.log("Base data seeded successfully!");
        process.exit(0);
    } catch (e) {
        console.error("Error seeding:", e);
        process.exit(1);
    }
}

seed();
