// Mock data for development - replace with Firestore queries when Firebase is configured

export const barbers = [
    {
        id: "1",
        name: "Sardor Karimov",
        photoUrl: "/barbers/barber1.jpg",
        rating: 4.9,
        reviewCount: 127,
        experience: 8,
        address: "Toshkent, Chilonzor tumani, 7-mavze",
        distance: 1.2,
        about: "Professional sartarosh, 8 yillik tajriba. Zamonaviy va klassik soch turmak uslublarida mutaxassis.",
        workingHours: { open: "09:00", close: "20:00" },
        services: [
            { id: "s1", name: "Soch olish", price: 30000, duration: 30 },
            { id: "s2", name: "Soqol olish", price: 20000, duration: 20 },
            { id: "s3", name: "Soch + Soqol", price: 45000, duration: 45 },
            { id: "s4", name: "Bola soch olish", price: 20000, duration: 25 },
            { id: "s5", name: "Premium styling", price: 60000, duration: 50 },
        ],
        photos: ["/barbers/barber1.jpg", "/barbers/work1.jpg", "/barbers/work2.jpg"],
        tags: ["Premium", "Top Rated"],
    },
    {
        id: "2",
        name: "Bekzod Aliyev",
        photoUrl: "/barbers/barber2.jpg",
        rating: 4.7,
        reviewCount: 89,
        experience: 5,
        address: "Toshkent, Yunusobod tumani, 14-mavze",
        distance: 2.5,
        about: "Kreativ soch turmaklari bo'yicha mutaxassis. Zamonaviy trendlarni yaxshi biladi.",
        workingHours: { open: "10:00", close: "21:00" },
        services: [
            { id: "s1", name: "Soch olish", price: 25000, duration: 30 },
            { id: "s2", name: "Soqol olish", price: 15000, duration: 20 },
            { id: "s3", name: "Soch + Soqol", price: 35000, duration: 45 },
            { id: "s4", name: "Rang berish", price: 80000, duration: 60 },
        ],
        photos: ["/barbers/barber2.jpg"],
        tags: ["Kreativ", "Zamonaviy"],
    },
    {
        id: "3",
        name: "Azizbek Rustamov",
        photoUrl: "/barbers/barber3.jpg",
        rating: 4.8,
        reviewCount: 156,
        experience: 10,
        address: "Toshkent, Mirzo Ulug'bek tumani",
        distance: 3.1,
        about: "10 yillik tajribaga ega usta. Klassik va zamonaviy uslublarni mukammal biladi.",
        workingHours: { open: "08:00", close: "19:00" },
        services: [
            { id: "s1", name: "Soch olish", price: 35000, duration: 30 },
            { id: "s2", name: "Soqol olish", price: 25000, duration: 20 },
            { id: "s3", name: "Soch + Soqol", price: 50000, duration: 50 },
            { id: "s4", name: "VIP xizmat", price: 100000, duration: 90 },
            { id: "s5", name: "Bola soch olish", price: 25000, duration: 25 },
        ],
        photos: ["/barbers/barber3.jpg"],
        tags: ["VIP", "Tajribali", "Top Rated"],
    },
    {
        id: "4",
        name: "Otabek Mirzayev",
        photoUrl: "/barbers/barber4.jpg",
        rating: 4.6,
        reviewCount: 64,
        experience: 3,
        address: "Toshkent, Sergeli tumani",
        distance: 5.0,
        about: "Yosh va iqtidorli sartarosh. Yangi trendlar va zamonaviy texnikalar bilan ishlaydi.",
        workingHours: { open: "09:00", close: "20:00" },
        services: [
            { id: "s1", name: "Soch olish", price: 20000, duration: 25 },
            { id: "s2", name: "Soqol olish", price: 12000, duration: 15 },
            { id: "s3", name: "Soch + Soqol", price: 28000, duration: 35 },
        ],
        photos: ["/barbers/barber4.jpg"],
        tags: ["Arzon", "Yosh usta"],
    },
    {
        id: "5",
        name: "Javohir Tursunov",
        photoUrl: "/barbers/barber5.jpg",
        rating: 4.9,
        reviewCount: 203,
        experience: 12,
        address: "Toshkent, Shayxontohur tumani",
        distance: 1.8,
        about: "Shahar bo'ylab eng mashhur sartaroshlardan biri. 12 yillik tajriba va minglab mamnun mijozlar.",
        workingHours: { open: "08:00", close: "21:00" },
        services: [
            { id: "s1", name: "Soch olish", price: 40000, duration: 30 },
            { id: "s2", name: "Soqol olish", price: 25000, duration: 20 },
            { id: "s3", name: "Soch + Soqol", price: 55000, duration: 50 },
            { id: "s4", name: "Premium styling", price: 80000, duration: 60 },
            { id: "s5", name: "VIP to'liq xizmat", price: 150000, duration: 120 },
        ],
        photos: ["/barbers/barber5.jpg"],
        tags: ["Premium", "Top Rated", "Mashhur"],
    },
    {
        id: "6",
        name: "Nodir Xasanov",
        photoUrl: "/barbers/barber6.jpg",
        rating: 4.5,
        reviewCount: 42,
        experience: 2,
        address: "Toshkent, Yashnobod tumani",
        distance: 4.3,
        about: "Yangi ochilgan zamonaviy barbershop. Qulay narxlar va sifatli xizmat.",
        workingHours: { open: "10:00", close: "20:00" },
        services: [
            { id: "s1", name: "Soch olish", price: 18000, duration: 25 },
            { id: "s2", name: "Soqol olish", price: 10000, duration: 15 },
            { id: "s3", name: "Soch + Soqol", price: 25000, duration: 35 },
        ],
        photos: ["/barbers/barber6.jpg"],
        tags: ["Yangi", "Arzon"],
    },
];

export const reviews = [
    {
        id: "r1",
        barberId: "1",
        clientName: "Ulugbek M.",
        rating: 5,
        comment: "Juda yaxshi usta! Har doim shu yerga kelaman. Sifat va xizmat a'lo darajada.",
        createdAt: "2026-03-20",
    },
    {
        id: "r2",
        barberId: "1",
        clientName: "Dilshod K.",
        rating: 5,
        comment: "Professional yondashuv, tez va sifatli ish. Tavsiya qilaman!",
        createdAt: "2026-03-18",
    },
    {
        id: "r3",
        barberId: "1",
        clientName: "Sherzod A.",
        rating: 4,
        comment: "Yaxshi usta, lekin kutish vaqti biroz uzoq. Natija esa a'lo.",
        createdAt: "2026-03-15",
    },
    {
        id: "r4",
        barberId: "2",
        clientName: "Firdavs T.",
        rating: 5,
        comment: "Eng yaxshi barbershop! Zamonaviy dizayn va a'lo xizmat.",
        createdAt: "2026-03-19",
    },
    {
        id: "r5",
        barberId: "2",
        clientName: "Bobur N.",
        rating: 4,
        comment: "Yaxshi ish, narxlar ham qulay. Yana kelaman.",
        createdAt: "2026-03-17",
    },
    {
        id: "r6",
        barberId: "3",
        clientName: "Jasur R.",
        rating: 5,
        comment: "10 yillik tajriba o'zini ko'rsatadi. Eng yaxshi sartarosh!",
        createdAt: "2026-03-21",
    },
    {
        id: "r7",
        barberId: "5",
        clientName: "Mansur B.",
        rating: 5,
        comment: "VIP xizmat darajasi. Har bir tafsilotga e'tibor beriladi.",
        createdAt: "2026-03-22",
    },
    {
        id: "r8",
        barberId: "5",
        clientName: "Akbar S.",
        rating: 5,
        comment: "Eng zo'r sartarosh! Premium sifat va mukammal natija.",
        createdAt: "2026-03-20",
    },
];

export const bookings = [
    {
        id: "b1",
        barberId: "1",
        clientId: "user1",
        service: "Soch olish",
        date: "2026-03-25",
        time: "10:00",
        status: "confirmed",
    },
    {
        id: "b2",
        barberId: "1",
        clientId: "user2",
        service: "Soch + Soqol",
        date: "2026-03-25",
        time: "11:00",
        status: "confirmed",
    },
    {
        id: "b3",
        barberId: "1",
        clientId: "user3",
        service: "Premium styling",
        date: "2026-03-25",
        time: "14:00",
        status: "pending",
    },
];

// Utility functions for data operations
export function getBarberById(id) {
    return barbers.find((b) => b.id === id) || null;
}

export function getReviewsByBarberId(barberId) {
    return reviews.filter((r) => r.barberId === barberId);
}

export function searchBarbers(query) {
    const q = query.toLowerCase();
    return barbers.filter(
        (b) =>
            b.name.toLowerCase().includes(q) ||
            b.address.toLowerCase().includes(q) ||
            b.services.some((s) => s.name.toLowerCase().includes(q)) ||
            b.tags.some((t) => t.toLowerCase().includes(q))
    );
}

export function filterBarbers({ minRating, maxDistance, maxPrice, sortBy }) {
    let result = [...barbers];

    if (minRating) result = result.filter((b) => b.rating >= minRating);
    if (maxDistance) result = result.filter((b) => b.distance <= maxDistance);
    if (maxPrice)
        result = result.filter((b) =>
            b.services.some((s) => s.price <= maxPrice)
        );

    if (sortBy === "rating") result.sort((a, b) => b.rating - a.rating);
    if (sortBy === "distance") result.sort((a, b) => a.distance - b.distance);
    if (sortBy === "price")
        result.sort(
            (a, b) =>
                Math.min(...a.services.map((s) => s.price)) -
                Math.min(...b.services.map((s) => s.price))
        );

    return result;
}

export function getAvailableSlots(barberId, date) {
    const barber = getBarberById(barberId);
    if (!barber) return [];

    const bookedSlots = bookings
        .filter((b) => b.barberId === barberId && b.date === date && b.status !== "cancelled")
        .map((b) => b.time);

    const slots = [];
    const [openH] = barber.workingHours.open.split(":").map(Number);
    const [closeH] = barber.workingHours.close.split(":").map(Number);

    for (let h = openH; h < closeH; h++) {
        const time = `${h.toString().padStart(2, "0")}:00`;
        slots.push({
            time,
            available: !bookedSlots.includes(time),
        });
        if (h < closeH - 1 || closeH - h > 1) {
            const halfTime = `${h.toString().padStart(2, "0")}:30`;
            slots.push({
                time: halfTime,
                available: !bookedSlots.includes(halfTime),
            });
        }
    }

    return slots;
}

export function formatPrice(price) {
    return new Intl.NumberFormat("uz-UZ").format(price) + " so'm";
}
