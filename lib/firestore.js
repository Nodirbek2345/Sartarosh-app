import { db } from "./firebase";
import {
    collection,
    doc,
    getDocs,
    getDoc,
    addDoc,
    updateDoc,
    deleteDoc,
    query,
    where,
    orderBy,
    onSnapshot,
    serverTimestamp,
    Timestamp,
} from "firebase/firestore";

// ==================== USERS ====================

const usersRef = collection(db, "users");

export function onUsersSnapshot(callback) {
    return onSnapshot(query(usersRef, orderBy("createdAt", "desc")), (snap) => {
        const data = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        callback(data);
    }, (error) => {
        console.log("Users snapshot error:", error);
        callback([]);
    });
}

// ==================== BARBERS ====================

const barbersRef = collection(db, "barbers");

export async function getBarbers() {
    const snap = await getDocs(query(barbersRef, orderBy("name")));
    return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function getBarberById(id) {
    const snap = await getDoc(doc(db, "barbers", id));
    if (!snap.exists()) return null;
    return { id: snap.id, ...snap.data() };
}

export async function addBarber(data) {
    const docRef = await addDoc(barbersRef, {
        ...data,
        createdAt: serverTimestamp(),
    });
    return docRef.id;
}

export async function updateBarber(id, data) {
    await updateDoc(doc(db, "barbers", id), {
        ...data,
        updatedAt: serverTimestamp(),
    });
}

export async function deleteBarber(id) {
    await deleteDoc(doc(db, "barbers", id));
}

// Real-time listener
export function onBarbersSnapshot(callback) {
    return onSnapshot(query(barbersRef, orderBy("name")), (snap) => {
        const data = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        callback(data);
    });
}

// ==================== SERVICES ====================

const servicesRef = collection(db, "services");

export async function getServices() {
    const snap = await getDocs(query(servicesRef, orderBy("name")));
    return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function addService(data) {
    const docRef = await addDoc(servicesRef, {
        ...data,
        createdAt: serverTimestamp(),
    });
    return docRef.id;
}

export async function updateService(id, data) {
    await updateDoc(doc(db, "services", id), {
        ...data,
        updatedAt: serverTimestamp(),
    });
}

export async function deleteService(id) {
    await deleteDoc(doc(db, "services", id));
}

export function onServicesSnapshot(callback) {
    return onSnapshot(query(servicesRef, orderBy("name")), (snap) => {
        const data = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        callback(data);
    });
}

// ==================== BOOKINGS ====================

const bookingsRef = collection(db, "bookings");

export async function getBookings() {
    const snap = await getDocs(query(bookingsRef, orderBy("date", "desc")));
    return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function addBooking(data) {
    // Smart Booking: Prevent double booking
    if (data.barberName && data.date && data.time) {
        const q = query(
            bookingsRef,
            where("barberName", "==", data.barberName),
            where("date", "==", data.date),
            where("time", "==", data.time),
            where("status", "in", ["confirmed", "pending", "in-progress"])
        );
        const snap = await getDocs(q);
        if (!snap.empty) {
            throw new Error("Kechirasiz, bu vaqt allaqachon band qilingan! Iltimos boshqa vaqt tanlang.");
        }
    }

    // Daromadni ajratish (Commission Logic)
    let barberEarnings = 0;
    let adminEarnings = 0;
    if (data.price) {
        const commissionRate = data.commissionRate || 30; // Default 30% admin
        adminEarnings = (data.price * commissionRate) / 100;
        barberEarnings = data.price - adminEarnings;
    }

    const docRef = await addDoc(bookingsRef, {
        ...data,
        barberEarnings,
        adminEarnings,
        status: data.status || "pending",
        createdAt: serverTimestamp(),
    });
    return docRef.id;
}

export async function updateBookingStatus(id, status) {
    await updateDoc(doc(db, "bookings", id), { status });
}

export async function deleteBooking(id) {
    await deleteDoc(doc(db, "bookings", id));
}

export function onBookingsSnapshot(callback) {
    return onSnapshot(query(bookingsRef, orderBy("date", "desc")), (snap) => {
        const data = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        callback(data);
    });
}

// ==================== REVIEWS ====================

const reviewsRef = collection(db, "reviews");

export async function getReviews() {
    const snap = await getDocs(query(reviewsRef, orderBy("createdAt", "desc")));
    return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function getReviewsByBarber(barberId) {
    const snap = await getDocs(
        query(reviewsRef, where("barberId", "==", barberId), orderBy("createdAt", "desc"))
    );
    return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function addReview(data) {
    const docRef = await addDoc(reviewsRef, {
        ...data,
        createdAt: serverTimestamp(),
    });
    return docRef.id;
}

// ==================== SETTINGS ====================

export async function getSettings() {
    const snap = await getDoc(doc(db, "settings", "main"));
    if (!snap.exists()) return null;
    return snap.data();
}

export async function saveSettings(data) {
    await updateDoc(doc(db, "settings", "main"), {
        ...data,
        updatedAt: serverTimestamp(),
    });
}

// ==================== STATS (hisob-kitob) ====================

export async function getDashboardStats() {
    const [barbersSnap, bookingsSnap] = await Promise.all([
        getDocs(barbersRef),
        getDocs(bookingsRef),
    ]);

    const barbersList = barbersSnap.docs.map((d) => d.data());
    const bookingsList = bookingsSnap.docs.map((d) => d.data());

    const today = new Date().toISOString().split("T")[0];
    const todayBookings = bookingsList.filter((b) => b.date === today);
    const confirmedBookings = bookingsList.filter((b) => b.status === "confirmed");

    const totalEarnings = confirmedBookings.reduce((sum, b) => sum + (b.price || 0), 0);
    const avgRating =
        barbersList.length > 0
            ? barbersList.reduce((sum, b) => sum + (b.rating || 0), 0) / barbersList.length
            : 0;

    return {
        totalBarbers: barbersList.length,
        todayBookings: todayBookings.length,
        totalEarnings,
        avgRating: avgRating.toFixed(1),
        totalBookings: bookingsList.length,
    };
}

// ==================== SEED (dastlabki ma'lumot) ====================

export async function seedDatabase() {
    // Barbers mavjudligini tekshirish
    const existing = await getDocs(barbersRef);
    if (existing.size > 0) {
        return { success: false, message: "Baza allaqachon to'ldirilgan!" };
    }

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
                { name: "Bola soch olish", price: 20000, duration: 25 },
                { name: "Premium styling", price: 60000, duration: 50 },
            ],
            tags: ["Premium", "Top Rated"],
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
                { name: "Rang berish", price: 80000, duration: 60 },
            ],
            tags: ["Kreativ", "Zamonaviy"],
        },
        {
            name: "Azizbek Rustamov",
            rating: 4.8,
            reviewCount: 156,
            experience: 10,
            address: "Toshkent, Mirzo Ulug'bek tumani",
            phone: "+998 93 333 44 55",
            about: "10 yillik tajribaga ega usta. Klassik va zamonaviy uslublarni mukammal biladi.",
            workingHours: { open: "08:00", close: "19:00" },
            services: [
                { name: "Soch olish", price: 35000, duration: 30 },
                { name: "Soqol olish", price: 25000, duration: 20 },
                { name: "Soch + Soqol", price: 50000, duration: 50 },
                { name: "VIP xizmat", price: 100000, duration: 90 },
            ],
            tags: ["VIP", "Tajribali", "Top Rated"],
        },
        {
            name: "Otabek Mirzayev",
            rating: 4.6,
            reviewCount: 64,
            experience: 3,
            address: "Toshkent, Sergeli tumani",
            phone: "+998 94 444 55 66",
            about: "Yosh va iqtidorli sartarosh. Yangi trendlar bilan ishlaydi.",
            workingHours: { open: "09:00", close: "20:00" },
            services: [
                { name: "Soch olish", price: 20000, duration: 25 },
                { name: "Soqol olish", price: 12000, duration: 15 },
                { name: "Soch + Soqol", price: 28000, duration: 35 },
            ],
            tags: ["Arzon", "Yosh usta"],
        },
        {
            name: "Javohir Tursunov",
            rating: 4.9,
            reviewCount: 203,
            experience: 12,
            address: "Toshkent, Shayxontohur tumani",
            phone: "+998 95 555 66 77",
            about: "Shahar bo'ylab eng mashhur sartaroshlardan biri. 12 yillik tajriba.",
            workingHours: { open: "08:00", close: "21:00" },
            services: [
                { name: "Soch olish", price: 40000, duration: 30 },
                { name: "Soqol olish", price: 25000, duration: 20 },
                { name: "Soch + Soqol", price: 55000, duration: 50 },
                { name: "Premium styling", price: 80000, duration: 60 },
                { name: "VIP to'liq xizmat", price: 150000, duration: 120 },
            ],
            tags: ["Premium", "Top Rated", "Mashhur"],
        },
        {
            name: "Nodir Xasanov",
            rating: 4.5,
            reviewCount: 42,
            experience: 2,
            address: "Toshkent, Yashnobod tumani",
            phone: "+998 97 666 77 88",
            about: "Yangi ochilgan zamonaviy barbershop. Qulay narxlar va sifatli xizmat.",
            workingHours: { open: "10:00", close: "20:00" },
            services: [
                { name: "Soch olish", price: 18000, duration: 25 },
                { name: "Soqol olish", price: 10000, duration: 15 },
                { name: "Soch + Soqol", price: 25000, duration: 35 },
            ],
            tags: ["Yangi", "Arzon"],
        },
    ];

    const bookingsData = [
        { client: "Aziz Mahmudov", barberName: "Sardor Karimov", service: "Soch olish", price: 30000, time: "14:00", date: new Date().toISOString().split("T")[0], status: "confirmed" },
        { client: "Doston Aliyev", barberName: "Bekzod Aliyev", service: "Soqol olish", price: 15000, time: "15:30", date: new Date().toISOString().split("T")[0], status: "pending" },
        { client: "Jamshid V.", barberName: "Azizbek Rustamov", service: "Soch + Soqol", price: 50000, time: "17:00", date: new Date().toISOString().split("T")[0], status: "confirmed" },
        { client: "Ulugbek M.", barberName: "Javohir Tursunov", service: "Premium styling", price: 80000, time: "10:00", date: "2026-04-07", status: "pending" },
        { client: "Firdavs T.", barberName: "Sardor Karimov", service: "Soch olish", price: 30000, time: "11:30", date: "2026-04-07", status: "cancelled" },
        { client: "Bobur N.", barberName: "Otabek Mirzayev", service: "Soch + Soqol", price: 28000, time: "09:00", date: "2026-04-05", status: "confirmed" },
        { client: "Jasur R.", barberName: "Nodir Xasanov", service: "Soch olish", price: 18000, time: "12:00", date: "2026-04-05", status: "confirmed" },
        { client: "Mansur B.", barberName: "Javohir Tursunov", service: "VIP to'liq xizmat", price: 150000, time: "13:00", date: "2026-04-04", status: "confirmed" },
    ];

    // Barbers qo'shish
    const barberIds = [];
    for (const barber of barbersData) {
        const id = await addBarber(barber);
        barberIds.push(id);
    }

    // Bookings qo'shish
    for (const booking of bookingsData) {
        await addBooking(booking);
    }

    // Settings yaratish
    const { setDoc } = await import("firebase/firestore");
    await setDoc(doc(db, "settings", "main"), {
        name: "Admin",
        phone: "+998 90 123 45 67",
        email: "admin@sartarosh.uz",
        address: "Toshkent, Chilonzor tumani",
        about: "Sartarosh boshqaruv tizimi administratori",
        workingHours: { open: "09:00", close: "20:00" },
        restDay: "sunday",
        notifications: {
            newBooking: true,
            cancellation: true,
            email: false,
            sms: true,
        },
        createdAt: serverTimestamp(),
    });

    return {
        success: true,
        message: `${barberIds.length} ta sartarosh va ${bookingsData.length} ta bron qo'shildi!`,
    };
}

// ==================== HELPERS ====================

export function formatPrice(price) {
    return new Intl.NumberFormat("uz-UZ").format(price) + " so'm";
}
