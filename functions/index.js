const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Trigger: When a booking is updated to 'in-progress'.
 * Action: Finds the next confirmed booking for the same barber on the same day,
 *         and sends an FCM notification "Navbatingiz yaqinlashdi".
 */
exports.onBookingStarted = functions.firestore
    .document("bookings/{bookingId}")
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        // Check if status changed to 'in-progress'
        if (before.status !== "in-progress" && after.status === "in-progress") {
            const barberName = after.barberName;
            const date = after.date;

            // Find the next booking for this barber today
            const nextBookingsSnapshot = await admin.firestore()
                .collection("bookings")
                .where("barberName", "==", barberName)
                .where("date", "==", date)
                .where("status", "==", "confirmed")
                // Firestore requires index if sorting by time with multiple fields, so we sort in memory
                .get();

            if (nextBookingsSnapshot.empty) {
                return null; // No next bookings
            }

            const bookings = [];
            nextBookingsSnapshot.forEach(doc => {
                bookings.push({ id: doc.id, ...doc.data() });
            });

            // Sort by time
            bookings.sort((a, b) => a.time.localeCompare(b.time));
            const nextBooking = bookings[0];

            // Find the client's FCM token
            if (nextBooking.clientId) {
                const clientDoc = await admin.firestore().collection("users").doc(nextBooking.clientId).get();
                if (clientDoc.exists) {
                    const fcmToken = clientDoc.data().fcmToken;
                    if (fcmToken) {
                        // Send FCM
                        const payload = {
                            notification: {
                                title: "Sartarosh",
                                body: "Sizning navbatingiz yaqinlashdi! Tayyorlaning.",
                            },
                            token: fcmToken
                        };
                        try {
                            await admin.messaging().send(payload);
                            console.log("Successfully sent queue push to", nextBooking.clientId);
                        } catch (error) {
                            console.error("Error sending queue push:", error);
                        }
                    }
                } else {
                    // Try comparing names if clientId is not set but name is
                    const usersByName = await admin.firestore().collection("users").where("name", "==", nextBooking.client).get();
                    if (!usersByName.empty) {
                        const fcmToken = usersByName.docs[0].data().fcmToken;
                        if (fcmToken) {
                            const payload = {
                                notification: {
                                    title: "Sartarosh",
                                    body: "Navbatingiz yaqinlashdi! Tayyor turing.",
                                },
                                token: fcmToken
                            };
                            await admin.messaging().send(payload);
                        }
                    }
                }
            }
        }
        return null;
    });

/**
 * Trigger: Cron job runs daily at 20:00.
 * Action: Finds all confirmed bookings for the next day and sends reminders.
 */
exports.notifyTomorrowBookings = functions.pubsub.schedule("0 20 * * *")
    .timeZone("Asia/Tashkent") // Default timezone for Uzbekistan
    .onRun(async (context) => {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);

        const dd = String(tomorrow.getDate()).padStart(2, '0');
        const mm = String(tomorrow.getMonth() + 1).padStart(2, '0');
        const yyyy = tomorrow.getFullYear();
        const tomorrowStr = `${yyyy}-${mm}-${dd}`;

        const bookingsSnapshot = await admin.firestore()
            .collection("bookings")
            .where("date", "==", tomorrowStr)
            .where("status", "==", "confirmed")
            .get();

        if (bookingsSnapshot.empty) {
            console.log("No bookings for tomorrow.");
            return null;
        }

        const promises = [];

        for (const doc of bookingsSnapshot.docs) {
            const booking = doc.data();

            if (booking.clientId) {
                const clientDoc = await admin.firestore().collection("users").doc(booking.clientId).get();
                if (clientDoc.exists) {
                    const fcmToken = clientDoc.data().fcmToken;
                    if (fcmToken) {
                        const payload = {
                            notification: {
                                title: "Eslatma",
                                body: `Ertaga soat ${booking.time} da ustangiz ${booking.barberName} qabuliga broningiz bor!`,
                            },
                            token: fcmToken
                        };
                        promises.push(
                            admin.messaging().send(payload).catch(err => console.error("FCM error:", err))
                        );
                    }
                }
            }
        }

        await Promise.all(promises);
        console.log(`Sent ${promises.length} reminders for tomorrow.`);
        return null;
    });
