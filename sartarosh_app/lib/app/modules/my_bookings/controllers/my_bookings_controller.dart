import 'package:sartarosh_app/core/theme/app_theme.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/booking_slot_lock.dart';

class MyBookingsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final activeBookings = <Map<String, dynamic>>[].obs;
  final pastBookings = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;

  // Queue position map: bookingId -> queue position
  final queuePositions = <String, int>{}.obs;

  // Total waiting for same barber/date
  final queueTotals = <String, int>{}.obs;

  // Real source of truth for UI toggle
  final hasBarberProfile = false.obs;

  // Barber states
  bool get isBarberMode => Get.find<UserService>().isBarberMode.value;
  void toggleBarberMode(bool val) {
    Get.find<UserService>().isBarberMode.value = val;
  }

  final barberPending = <Map<String, dynamic>>[].obs;
  final barberConfirmed = <Map<String, dynamic>>[].obs;
  final barberInProgress = <Map<String, dynamic>>[].obs;
  final barberCompleted = <Map<String, dynamic>>[].obs;

  // Dashboard Stats
  final todayClientsCount = 0.obs;
  final completedCount = 0.obs;
  final todayEarnings = 0.obs;
  final weeklyEarnings = 0.obs;
  final monthlyEarnings = 0.obs;

  StreamSubscription? _bookingsSub;

  // Track queue subscriptions per barber/date pair
  final Map<String, StreamSubscription> _queueSubs = {};

  @override
  void onInit() {
    super.onInit();
    _fetchBookings();
    _checkIfBarber();
  }

  Future<void> _checkIfBarber() async {
    final uid = Get.find<UserService>().currentUid;
    if (uid.isEmpty) return;
    final docs = await _firestore
        .collection('barbers')
        .where('uid', isEqualTo: uid)
        .get();
    if (docs.docs.isNotEmpty) {
      hasBarberProfile.value = true;
      _barberDocRef = docs.docs.first.reference;

      _listenBarberBookings();
      _listenBarberStatus();
      _listenQueues();
    }
  }

  void _fetchBookings() {
    final userService = Get.find<UserService>();
    final uid = userService.currentUid;

    // Use UID for secure queries, fallback to name for backward compat
    final query = uid.isNotEmpty
        ? _firestore.collection('bookings').where('clientUid', isEqualTo: uid)
        : _firestore
              .collection('bookings')
              .where('client', isEqualTo: userService.name.value);

    _bookingsSub = query.snapshots().listen((snap) {
      final docs = snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();

      docs.sort((a, b) {
        final dateA = '${a['date'] ?? ''} ${a['time'] ?? ''}';
        final dateB = '${b['date'] ?? ''} ${b['time'] ?? ''}';
        return dateB.compareTo(dateA);
      });

      activeBookings.value = docs.where((b) {
        final s = b['status'];
        return s == 'pending' || s == 'confirmed' || s == 'in-progress';
      }).toList();

      pastBookings.value = docs.where((b) {
        final s = b['status'];
        final clientDeleted = b['clientDeleted'] ?? false;
        if (clientDeleted) return false;

        return s == 'completed' ||
            s == 'cancelled' ||
            s == 'no-show' ||
            s == 'penalty';
      }).toList();

      isLoading.value = false;

      // Calculate queue positions for all active bookings
      _updateQueuePositions();
    });
  }

  /// Real-time queue position: listen to all bookings for same barber & date
  void _updateQueuePositions() {
    // Cancel old queue subscriptions
    for (var sub in _queueSubs.values) {
      sub.cancel();
    }
    _queueSubs.clear();

    // Group active bookings by barber+date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var b in activeBookings) {
      final key = '${b['barberId'] ?? ''}_${b['date'] ?? ''}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(b);
    }

    for (var entry in grouped.entries) {
      final parts = entry.key.split('_');
      if (parts.length < 2) continue;
      final barberId = parts[0];
      final date = parts.sublist(1).join('_');
      if (barberId.isEmpty || date.isEmpty) continue;

      final sub = _firestore
          .collection('bookings')
          .where('barberId', isEqualTo: barberId)
          .where('date', isEqualTo: date)
          .where('status', whereIn: ['confirmed', 'pending', 'in-progress'])
          .snapshots()
          .listen((snap) {
            final allBookings = snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList();

            // Sort by time
            allBookings.sort(
              (a, b) => (a['time'] ?? '').compareTo(b['time'] ?? ''),
            );

            final total = allBookings.length;

            for (var myBooking in entry.value) {
              final myId = myBooking['id'];
              int myPos = -1;
              for (int i = 0; i < allBookings.length; i++) {
                if (allBookings[i]['id'] == myId) {
                  myPos = i + 1;
                  break;
                }
              }
              if (myPos > 0) {
                queuePositions[myId] = myPos;
                queueTotals[myId] = total;
              }
            }
          });
      _queueSubs[entry.key] = sub;
    }
  }

  /// Get estimated wait time for a booking based on queue position
  String getEstimatedWait(Map<String, dynamic> booking) {
    final id = booking['id'] as String? ?? '';
    final pos = queuePositions[id] ?? 0;
    if (pos <= 1) return "Sizning navbatingiz!";
    final waitMinutes = (pos - 1) * (booking['durationMinutes'] ?? 30);
    if (waitMinutes < 60) return "~$waitMinutes daqiqa";
    final hours = waitMinutes ~/ 60;
    final mins = waitMinutes % 60;
    if (mins == 0) return "~$hours soat";
    return "~$hours soat $mins daqiqa";
  }

  Future<void> cancelBooking(String id, String dateStr, String timeStr) async {
    try {
      final bookingSnap = await _firestore.collection('bookings').doc(id).get();
      final before = bookingSnap.data();

      String newStatus = 'cancelled';
      try {
        final bookingTime = DateFormat(
          'yyyy-MM-dd HH:mm',
        ).parse('$dateStr $timeStr');
        final now = DateTime.now();
        // If cancellation is less than 30 mins before, it's late cancellation -> penalty
        if (bookingTime.difference(now).inMinutes < 30) {
          newStatus = 'penalty';
        }
      } catch (_) {}

      await _firestore.collection('bookings').doc(id).update({
        'status': newStatus,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      if (before != null) {
        await BookingSlotLock.releaseFromBookingData(_firestore, before);
      }

      // Send notification to barber
      try {
        final bookingDoc = await _firestore
            .collection('bookings')
            .doc(id)
            .get();
        final barberUid = bookingDoc.data()?['barberUid'] ?? '';
        final date = bookingDoc.data()?['date'] ?? '';
        final time = bookingDoc.data()?['time'] ?? '';
        final clientName = bookingDoc.data()?['client'] ?? 'Mijoz';
        if (barberUid.isNotEmpty) {
          await _firestore.collection('notifications').add({
            'userId': barberUid,
            'title': 'Bron bekor qilindi',
            'message': '$clientName $date $time dagi bronni bekor qildi.',
            'type': 'booking_cancelled',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}

      if (newStatus == 'penalty') {
        Get.snackbar(
          "Ogohlantirish",
          "Bron kech bekor qilingani sababli tizimda qayd etildi.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Muvaffaqiyatli",
          "Bron bekor qilindi!",
          backgroundColor: AppTheme.success,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar("Xatolik", "Bekor qilishda xatolik yuz berdi");
    }
  }

  void rebook(Map<String, dynamic> b) {
    final barberId = b['barberId'] as String?;
    if (barberId == null || barberId.isEmpty) {
      Get.snackbar("Xatolik", "Usta ma'lumotlari topilmadi.");
      return;
    }
    _firestore.collection('barbers').doc(barberId).get().then((doc) {
      if (doc.exists) {
        final barber = doc.data()!;
        barber['id'] = doc.id;
        Get.toNamed(
          '/booking',
          arguments: {
            'barber': barber,
            'service': b['service'] ?? 'Soch olish',
            'price': b['price'] ?? 30000,
            'duration': b['durationMinutes'] ?? 30,
          },
        );
      } else {
        Get.snackbar("Xatolik", "Usta tizimdan topilmadi.");
      }
    });
  }

  // ============== BARBER STATUS & QUEUE CONTROLS ==============
  final isActive = true.obs;
  final queueLimit = 1.obs;
  final currentClient = Rxn<Map<String, dynamic>>();
  final nextClient = Rxn<Map<String, dynamic>>();
  DocumentReference? _barberDocRef;
  StreamSubscription? _barberBookingsSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _queuesSub;
  final todayQueues = <Map<String, dynamic>>[].obs;

  void _listenBarberStatus() {
    if (_barberDocRef == null) return;
    _statusSub = _barberDocRef!.snapshots().listen((snap) {
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        if (data != null) {
          isActive.value = data['isActive'] ?? true;
          queueLimit.value = data['queueLimit'] ?? 1;
        }
      }
    });
  }

  void _listenQueues() {
    final uid = Get.find<UserService>().currentUid;
    if (uid.isEmpty) return;

    _queuesSub = _firestore
        .collection('queues')
        .where('barberId', isEqualTo: uid)
        .where('status', whereIn: ['waiting', 'in_progress'])
        .snapshots()
        .listen((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['docId'] = doc.id;
            data['id'] = doc.id;
            data['isQueue'] = true;
            return data;
          }).toList();

          list.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return aTime.compareTo(bTime);
          });
          todayQueues.value = list;
          _updateCombinedQueue();
        });
  }

  void _updateCombinedQueue() {
    final activeBooking = barberInProgress.isNotEmpty
        ? barberInProgress.first
        : null;
    final activeQueue = todayQueues.firstWhereOrNull(
      (q) => q['status'] == 'in_progress',
    );

    if (activeBooking != null) {
      currentClient.value = activeBooking;
    } else if (activeQueue != null) {
      currentClient.value = activeQueue;
    } else {
      currentClient.value = null;
    }

    final nextBooking = barberConfirmed.isNotEmpty
        ? barberConfirmed.first
        : null;
    final pendingBooking = barberPending.isNotEmpty
        ? barberPending.first
        : null;

    if (nextBooking != null) {
      nextClient.value = nextBooking;
    } else if (todayQueues.isNotEmpty &&
        todayQueues.first['status'] == 'waiting') {
      nextClient.value = todayQueues.first;
    } else if (pendingBooking != null) {
      nextClient.value = pendingBooking;
    } else {
      nextClient.value = null;
    }
  }

  Future<void> toggleActiveStatus() async {
    if (!isActive.value && todayQueues.length >= queueLimit.value) {
      Get.snackbar(
        "Navbat to'la",
        "Sizda navbat limiti to'lgan. Limitni oshiring yoki ishlarni yakunlang.",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
      return;
    }
    if (_barberDocRef != null) {
      await _barberDocRef!.update({'isActive': !isActive.value});
    }
  }

  void incrementLimit() {
    if (queueLimit.value < 99) {
      queueLimit.value++;
      if (_barberDocRef != null) {
        _barberDocRef!.update({'queueLimit': queueLimit.value});
      }
    }
  }

  void decrementLimit() {
    if (queueLimit.value > 1) {
      queueLimit.value--;
      if (_barberDocRef != null) {
        _barberDocRef!.update({'queueLimit': queueLimit.value});
      }
    }
  }

  // ---- BARBER STATE ----

  void _listenBarberBookings() {
    final userService = Get.find<UserService>();
    final uid = userService.currentUid;
    if (uid.isEmpty) return;

    // Usta statusidagi bronlarni olish
    _barberBookingsSub?.cancel();
    _barberBookingsSub = _firestore
        .collection('bookings')
        .where('barberId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
          final docs = snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id; // docId
            return data;
          }).toList();

          docs.sort((a, b) {
            final dateA = '${a['date'] ?? ''} ${a['time'] ?? ''}';
            final dateB = '${b['date'] ?? ''} ${b['time'] ?? ''}';
            return dateB.compareTo(dateA);
          });

          barberPending.value = docs
              .where((b) => b['status'] == 'pending')
              .toList();
          barberConfirmed.value = docs
              .where((b) => b['status'] == 'confirmed')
              .toList();
          barberInProgress.value = docs
              .where((b) => b['status'] == 'in-progress')
              .toList();
          barberCompleted.value = docs
              .where((b) => b['status'] == 'completed')
              .toList();

          // ── 🔥 Stats Computation ──
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final now = DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final monthStart = DateTime(now.year, now.month, 1);

          final todayDocs = docs.where((b) => b['date'] == today).toList();
          todayClientsCount.value = todayDocs.length;
          completedCount.value = todayDocs
              .where((b) => b['status'] == 'completed')
              .length;
          todayEarnings.value = todayDocs
              .where((b) => b['status'] == 'completed')
              .fold<int>(0, (t, b) => t + ((b['price'] as num?)?.toInt() ?? 0));

          final completedDocs = docs
              .where((b) => b['status'] == 'completed')
              .toList();
          weeklyEarnings.value = completedDocs
              .where((b) {
                try {
                  final d = DateTime.parse(b['date'] ?? '');
                  return d.isAfter(weekStart.subtract(const Duration(days: 1)));
                } catch (_) {
                  return false;
                }
              })
              .fold<int>(0, (t, b) => t + ((b['price'] as num?)?.toInt() ?? 0));

          monthlyEarnings.value = completedDocs
              .where((b) {
                try {
                  final d = DateTime.parse(b['date'] ?? '');
                  return d.isAfter(
                    monthStart.subtract(const Duration(days: 1)),
                  );
                } catch (_) {
                  return false;
                }
              })
              .fold<int>(0, (t, b) => t + ((b['price'] as num?)?.toInt() ?? 0));

          _updateCombinedQueue();
        });
  }

  // ============== STATE MACHINE HELPERS ==============
  static const _allowedTransitions = {
    'pending': ['confirmed', 'cancelled'],
    'confirmed': ['in-progress', 'cancelled', 'no-show'],
    'in-progress': ['completed'],
  };

  bool _canTransition(String from, String to) {
    return _allowedTransitions[from]?.contains(to) ?? false;
  }

  Future<void> acceptBooking(String docId) async {
    try {
      final snapshot = await _firestore.collection('bookings').doc(docId).get();
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      if (!_canTransition(data['status'] ?? '', 'confirmed')) {
        Get.snackbar(
          "Xatolik",
          "Holatini o'zgartirish mumkin emas",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      // Smart Accept: Auto-reject overlapping bookings
      final overlaps = await _firestore
          .collection('bookings')
          .where('barberId', isEqualTo: Get.find<UserService>().currentUid)
          .where('date', isEqualTo: data['date'])
          .where('time', isEqualTo: data['time'])
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in overlaps.docs) {
        if (doc.id != docId) {
          await doc.reference.update({'status': 'cancelled'});
          await BookingSlotLock.releaseFromBookingData(_firestore, doc.data());
        }
      }

      await _firestore.collection('bookings').doc(docId).update({
        'status': 'confirmed',
      });
      final clientUid = data['clientUid'] ?? '';
      if (clientUid.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': clientUid,
          'title': 'Bron tasdiqlandi!',
          'message': 'Usta broningizni tasdiqladi.',
          'type': 'booking_confirmed',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      Get.snackbar(
        "Zo'r",
        "Bron qabul qilindi",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Xato", "Xatolik yuz berdi");
    }
  }

  Future<void> rejectBooking(String docId) async {
    try {
      final snapshot = await _firestore.collection('bookings').doc(docId).get();
      if (!snapshot.exists) return;
      if (!_canTransition(snapshot.data()!['status'] ?? '', 'cancelled')) {
        return;
      }

      await _firestore.collection('bookings').doc(docId).update({
        'status': 'cancelled',
      });
      await BookingSlotLock.releaseFromBookingData(
        _firestore,
        snapshot.data()!,
      );
      final clientUid = snapshot.data()!['clientUid'] ?? '';
      if (clientUid.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': clientUid,
          'title': 'Bron bekor qilindi',
          'message': 'Usta bronni bekor qildi.',
          'type': 'booking_cancelled',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      Get.snackbar(
        "Rad etildi",
        "Bron rad etildi",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Xato", "Xatolik yuz berdi");
    }
  }

  Future<void> startClient(String docId) async {
    try {
      final snapshot = await _firestore.collection('bookings').doc(docId).get();
      if (!snapshot.exists) return;
      if (!_canTransition(snapshot.data()!['status'] ?? '', 'in-progress')) {
        return;
      }

      await _firestore.collection('bookings').doc(docId).update({
        'status': 'in-progress',
        'startedAt': FieldValue.serverTimestamp(),
      });
      final clientUid = snapshot.data()!['clientUid'] ?? '';
      if (clientUid.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': clientUid,
          'title': 'Sizning navbatingiz! 🔥',
          'message': 'Xizmatingiz boshlandi.',
          'type': 'your_turn',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      Get.snackbar(
        "Boshlandi",
        "Xizmat boshlandi",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Xato", "Xatolik yuz berdi");
    }
  }

  Future<void> completeClient(String docId) async {
    try {
      final snapshot = await _firestore.collection('bookings').doc(docId).get();
      if (!snapshot.exists) return;
      if (!_canTransition(snapshot.data()!['status'] ?? '', 'completed')) {
        return;
      }

      await _firestore.collection('bookings').doc(docId).update({
        'status': 'completed',
        'paymentStatus': 'paid',
        'completedAt': FieldValue.serverTimestamp(),
      });
      await BookingSlotLock.releaseFromBookingData(
        _firestore,
        snapshot.data()!,
      );
      final clientUid = snapshot.data()!['clientUid'] ?? '';
      if (clientUid.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': clientUid,
          'title': 'Xizmat yakunlandi ✅',
          'message': 'Rahmat!',
          'type': 'service_completed',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      Get.snackbar(
        "Tugallandi",
        "Xizmat yakunlandi",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Xato", "Xatolik yuz berdi");
    }
  }

  Future<void> deleteHistoryItem(String id) async {
    try {
      await _firestore.collection('bookings').doc(id).update({
        'clientDeleted': true,
      });
      Get.snackbar(
        "O'chirildi",
        "Bron tarixdan o'chirildi.",
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Xatolik", "O'chirishda xatolik yuz berdi");
    }
  }

  @override
  void onClose() {
    _bookingsSub?.cancel();
    _barberBookingsSub?.cancel();
    _statusSub?.cancel();
    _queuesSub?.cancel();
    for (var sub in _queueSubs.values) {
      sub.cancel();
    }
    _queueSubs.clear();
    super.onClose();
  }
}
