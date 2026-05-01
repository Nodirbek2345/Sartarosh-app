import 'package:sartarosh_app/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/user_service.dart';
import 'package:flutter/material.dart';

class BarberDashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final todayBookings = <Map<String, dynamic>>[].obs;
  final allBookings = <Map<String, dynamic>>[].obs; // Barcha kunlar uchun
  final todayQueues = <Map<String, dynamic>>[].obs;
  final isActive = true.obs;
  final isLoading = true.obs;
  final queueLimit = 1.obs;
  final portfolioImages = <String>[].obs;

  // Stats
  final todayEarnings = 0.obs;
  final weeklyEarnings = 0.obs;
  final monthlyEarnings = 0.obs;
  final todayClientsCount = 0.obs;
  final completedCount = 0.obs;
  final pendingCount = 0.obs; // Kutilmoqda bronlar soni

  // Queue system
  final currentClient = Rxn<Map<String, dynamic>>();
  final nextClient = Rxn<Map<String, dynamic>>();

  // Stream subscriptions for proper cleanup
  StreamSubscription? _bookingsSub;
  StreamSubscription? _allBookingsSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _queuesSub;

  // Cached barber document reference
  DocumentReference? _barberDocRef;
  String _barberId = ''; // barber document ID

  String get currentUid => Get.find<UserService>().currentUid;
  String get barberName => Get.find<UserService>().name.value;
  String get todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    _initAndListen();
  }

  Future<void> _initAndListen() async {
    // Security: verify barber role
    final userService = Get.find<UserService>();
    if (userService.userRole.value != 'barber') {
      Get.snackbar(
        "Ruxsat yo'q",
        "Faqat ustalar uchun",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
      Get.offAllNamed('/home');
      return;
    }

    await _initBarberRef();
    _listenTodayBookings();
    _listenAllBookings();
    _listenBarberStatus();
    _listenQueues();
  }

  /// Cache the barber document reference using UID
  Future<void> _initBarberRef() async {
    final snapshot = await _firestore
        .collection('barbers')
        .where('uid', isEqualTo: currentUid)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      _barberDocRef = snapshot.docs.first.reference;
      _barberId = snapshot.docs.first.id;
    }
  }

  void _listenTodayBookings() {
    if (_barberId.isEmpty) {
      isLoading.value = false;
      return;
    }
    _bookingsSub = _firestore
        .collection('bookings')
        .where('barberId', isEqualTo: _barberId)
        .where('date', isEqualTo: todayDate)
        .snapshots()
        .listen((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['docId'] = doc.id;
            return data;
          }).toList();

          // Sort by time
          list.sort((a, b) => (a['time'] ?? '').compareTo(b['time'] ?? ''));
          todayBookings.value = list;

          // Stats
          todayClientsCount.value = list.length;
          completedCount.value = list
              .where((b) => b['status'] == 'completed')
              .length;
          todayEarnings.value = list
              .where((b) => b['status'] == 'completed')
              .fold<int>(
                0,
                (total, b) => total + ((b['price'] as num?)?.toInt() ?? 0),
              );

          // Queue system logic is now handled in _updateCombinedQueue()
          _updateCombinedQueue();

          isLoading.value = false;
          _checkAutoTurnOff();
        });
  }

  void _listenQueues() {
    if (_barberId.isEmpty) return;
    _queuesSub = _firestore
        .collection('queues')
        .where('barberId', isEqualTo: _barberId)
        .where('status', whereIn: ['waiting', 'in_progress'])
        .snapshots()
        .listen((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['docId'] = doc.id;
            data['isQueue'] =
                true; // Use this flag to distinguish from regular bookings
            return data;
          }).toList();

          // Sort by creation time (queue position implicitly based on arrival)
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
    // Find one in-progress from EITHER bookings OR queues
    final activeBooking = todayBookings.firstWhereOrNull(
      (b) => b['status'] == 'in-progress',
    );
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

    // Find the next client. Prioritize confirmed booking with earliest time, then earliest waiting queue
    final nextBooking = todayBookings
        .where((b) => b['status'] == 'confirmed')
        .toList();
    final pendingBooking = todayBookings
        .where((b) => b['status'] == 'pending')
        .toList();

    if (nextBooking.isNotEmpty) {
      nextClient.value = nextBooking.first;
    } else if (todayQueues.isNotEmpty &&
        todayQueues.first['status'] == 'waiting') {
      nextClient.value = todayQueues.first;
    } else if (pendingBooking.isNotEmpty) {
      nextClient.value = pendingBooking.first;
    } else {
      nextClient.value = null;
    }
  }

  /// Barcha kunlar uchun bronlarni tinglash (Bronlar tab uchun)
  void _listenAllBookings() {
    if (_barberId.isEmpty) return;
    _allBookingsSub = _firestore
        .collection('bookings')
        .where('barberId', isEqualTo: _barberId)
        // Removed .orderBy('createdAt') and .limit(100) to avoid missing composite index requirement
        .snapshots()
        .listen((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['docId'] = doc.id;
            return data;
          }).toList();

          // Client-side sort to bypass Firestore index crash
          list.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending
          });

          allBookings.value = list;
          pendingCount.value = list
              .where((b) => b['status'] == 'pending')
              .length;

          // Calculate Financials (Weekly/Monthly)
          int wEarnings = 0;
          int mEarnings = 0;
          final now = DateTime.now();
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfMonth = DateTime(now.year, now.month, 1);
          final startOfWeekNorm = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );

          for (var b in list) {
            if (b['status'] == 'completed') {
              try {
                DateTime bDate = DateFormat(
                  'yyyy-MM-dd',
                ).parse(b['date'] ?? '');
                int price = (b['price'] as num?)?.toInt() ?? 0;

                if (!bDate.isBefore(startOfMonth)) {
                  mEarnings += price;
                }
                if (!bDate.isBefore(startOfWeekNorm)) {
                  wEarnings += price;
                }
              } catch (_) {}
            }
          }
          weeklyEarnings.value = wEarnings;
          monthlyEarnings.value = mEarnings;
        });
  }

  void _listenBarberStatus() {
    _statusSub = _firestore
        .collection('barbers')
        .where('uid', isEqualTo: currentUid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final data = snapshot.docs.first.data();
            isActive.value = data['isActive'] ?? true;
            if (data.containsKey('queueLimit')) {
              queueLimit.value = data['queueLimit'] as int;
            }
            if (data.containsKey('portfolioImages')) {
              portfolioImages.value = List<String>.from(
                data['portfolioImages'] ?? [],
              );
            }
            // Cache reference if not already cached
            _barberDocRef ??= snapshot.docs.first.reference;
            if (_barberId.isEmpty) {
              _barberId = snapshot.docs.first.id;
            }
            _checkAutoTurnOff();
          }
        });
  }

  Future<void> _checkAutoTurnOff() async {
    if (isActive.value &&
        todayClientsCount.value >= queueLimit.value &&
        queueLimit.value > 0) {
      isActive.value = false;
      if (_barberDocRef != null) {
        await _barberDocRef!.update({'isActive': false});
      }
    }
  }

  Future<void> toggleActiveStatus() async {
    if (_barberDocRef != null) {
      await _barberDocRef!.update({'isActive': !isActive.value});
    } else {
      // Fallback: find and update
      final snapshot = await _firestore
          .collection('barbers')
          .where('uid', isEqualTo: currentUid)
          .get();
      if (snapshot.docs.isNotEmpty) {
        _barberDocRef = snapshot.docs.first.reference;
        await _barberDocRef!.update({'isActive': !isActive.value});
      }
    }
  }

  void incrementLimit() {
    if (queueLimit.value < 99) {
      queueLimit.value++;
      _syncQueueLimit(queueLimit.value);
      _checkAutoTurnOff();
    }
  }

  void decrementLimit() {
    if (queueLimit.value > 1) {
      queueLimit.value--;
      _syncQueueLimit(queueLimit.value);
      _checkAutoTurnOff();
    }
  }

  Future<void> _syncQueueLimit(int val) async {
    if (_barberDocRef != null) {
      await _barberDocRef!.update({'queueLimit': val});
    } else {
      final snapshot = await _firestore
          .collection('barbers')
          .where('uid', isEqualTo: currentUid)
          .get();
      if (snapshot.docs.isNotEmpty) {
        _barberDocRef = snapshot.docs.first.reference;
        await _barberDocRef!.update({'queueLimit': val});
      }
    }
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
      // State guard: only pending → confirmed
      final snapshot = await _firestore.collection('bookings').doc(docId).get();
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      if (!_canTransition(data['status'] ?? '', 'confirmed')) {
        Get.snackbar(
          "Xatolik",
          "Bu bron holatini o'zgartirish mumkin emas",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        return;
      }

      final date = data['date'];
      final time = data['time'];

      // Smart Accept: Auto-reject overlapping bookings
      final overlaps = await _firestore
          .collection('bookings')
          .where('barberId', isEqualTo: _barberId)
          .where('date', isEqualTo: date)
          .where('time', isEqualTo: time)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in overlaps.docs) {
        if (doc.id != docId) {
          await doc.reference.update({'status': 'cancelled'});
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
          'message': 'Usta sizning $date $time dagi broningizni tasdiqladi.',
          'type': 'booking_confirmed',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      Get.snackbar(
        "Muvaffaqiyatli",
        "Bron qabul qilindi",
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
      );
      HapticFeedback.lightImpact();
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Xatolik yuz berdi",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    }
  }

  Future<void> rejectBooking(String docId) async {
    try {
      final snapshot = await _firestore.collection('bookings').doc(docId).get();
      if (!snapshot.exists) return;
      final currentStatus = snapshot.data()!['status'] ?? '';
      if (!_canTransition(currentStatus, 'cancelled')) {
        Get.snackbar(
          "Xatolik",
          "Bu bronni bekor qilish mumkin emas",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        return;
      }
      await _firestore.collection('bookings').doc(docId).update({
        'status': 'cancelled',
      });

      final clientUid = snapshot.data()!['clientUid'] ?? '';
      final date = snapshot.data()!['date'] ?? '';
      final time = snapshot.data()!['time'] ?? '';
      if (clientUid.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': clientUid,
          'title': 'Bron bekor qilindi',
          'message': 'Usta sizning $date $time dagi broningizni bekor qildi.',
          'type': 'booking_cancelled',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      Get.snackbar(
        "Bekor qilindi",
        "Bron rad etildi",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Xatolik yuz berdi",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    }
  }

  /// Checks if Start button should be enabled for a booking
  bool canStartBooking(Map<String, dynamic> booking) {
    if (booking['status'] != 'confirmed') return false;
    if (booking['date'] != todayDate) return false;
    try {
      final parts = (booking['time'] as String).split(':');
      final now = DateTime.now();
      final bookingTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      final diffMin = bookingTime.difference(now).inMinutes;
      // Allow start from 15 mins before up to 30 mins after
      return diffMin <= 15 && diffMin >= -30;
    } catch (_) {
      return false;
    }
  }

  Future<void> startClient(String docId) async {
    try {
      // State guard: only confirmed → in-progress
      final snapshot = await _firestore.collection('bookings').doc(docId).get();
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      if (!_canTransition(data['status'] ?? '', 'in-progress')) {
        Get.snackbar(
          "Xatolik",
          "Faqat tasdiqlangan bronni boshlash mumkin",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        return;
      }

      // Time gate: booking must be today and within 15 min window
      if (!canStartBooking(data)) {
        Get.snackbar(
          "Vaqt emas",
          "Xizmatni boshlash vaqti hali kelmadi yoki o'tib ketdi",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Prevent multiple in-progress
      final inProgressSnap = await _firestore
          .collection('bookings')
          .where('barberId', isEqualTo: _barberId)
          .where('date', isEqualTo: todayDate)
          .where('status', isEqualTo: 'in-progress')
          .get();

      if (inProgressSnap.docs.isNotEmpty) {
        Get.snackbar(
          "Xatolik",
          "Avval boshlangan mijozni yakunlang!",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        return;
      }

      await _firestore.collection('bookings').doc(docId).update({
        'status': 'in-progress',
        'startedAt': FieldValue.serverTimestamp(),
      });

      final clientUid = data['clientUid'] as String?;
      if (clientUid != null && clientUid.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': clientUid,
          'title': 'Sizning navbatingiz! 🔥',
          'message': 'Usta sizining xizmatingizni boshladi.',
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
      HapticFeedback.lightImpact();
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Xizmatni boshlashda xatolik yuz berdi",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    }
  }

  Future<void> completeClient(String docId) async {
    try {
      // State guard: only in-progress → completed
      final snapshot = await _firestore.collection('bookings').doc(docId).get();
      if (!snapshot.exists) return;
      if (!_canTransition(snapshot.data()!['status'] ?? '', 'completed')) {
        Get.snackbar(
          "Xatolik",
          "Faqat jarayondagi xizmatni tugatish mumkin",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        return;
      }
      await _firestore.collection('bookings').doc(docId).update({
        'status': 'completed',
        'paymentStatus': 'paid',
        'completedAt': FieldValue.serverTimestamp(),
      });

      final clientUid = snapshot.data()?['clientUid'] as String?;
      if (clientUid != null && clientUid.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': clientUid,
          'title': 'Xizmat yakunlandi ✅',
          'message': 'Xizmatingiz yakunlandi. Tashrifingiz uchun rahmat!',
          'type': 'service_completed',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      Get.snackbar(
        "Tugallandi",
        "Xizmat muvaffaqiyatli yakunlandi",
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
      );
      HapticFeedback.heavyImpact();
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Xizmatni tugatishda xatolik yuz berdi",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    }
  }

  Future<void> markNoShow(String docId) async {
    try {
      // State guard: only confirmed → no-show
      final snapshot = await _firestore.collection('bookings').doc(docId).get();
      if (!snapshot.exists) return;
      if (!_canTransition(snapshot.data()!['status'] ?? '', 'no-show')) {
        Get.snackbar(
          "Xatolik",
          "Faqat tasdiqlangan bronni 'Kelmadi' deb belgilash mumkin",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        return;
      }
      await _firestore.collection('bookings').doc(docId).update({
        'status': 'no-show',
        'noShowAt': FieldValue.serverTimestamp(),
      });

      final clientUid = snapshot.data()?['clientUid'] as String?;
      if (clientUid != null && clientUid.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': clientUid,
          'title': 'Kelmadi deb belgilandi ❌',
          'message':
              'Usta sizni tashrif buyurmadi deb belgiladi. Bu hisobingizga salbiy ta\'sir qilishi mumkin.',
          'type': 'no_show',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      Get.snackbar(
        "Mijoz kelmadi",
        "Mijoz qatnashmaganligi tasdiqlandi",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Xatolik yuz berdi",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    }
  }

  // ============== QUEUE SYSTEM ACTIONS ==============

  Future<void> startQueueClient(String docId) async {
    try {
      if (currentClient.value != null) {
        Get.snackbar(
          "Xatolik",
          "Avval boshlangan mijozni yakunlang!",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        return;
      }
      await _firestore.collection('queues').doc(docId).update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
      });

      final queueDoc = await _firestore.collection('queues').doc(docId).get();
      final clientUid = queueDoc.data()?['clientUid'] as String?;
      if (clientUid != null && clientUid.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': clientUid,
          'title': 'Sizning navbatingiz! 🔥',
          'message': 'Usta sizning xizmatingizni boshladi.',
          'type': 'your_turn',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      Get.snackbar(
        "Boshlandi",
        "Jonli navbat xizmati boshlandi",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      HapticFeedback.lightImpact();
    } catch (e) {
      Get.snackbar("Xato", "Navbatni boshlashda xatolik");
    }
  }

  Future<void> completeQueueClient(String docId) async {
    try {
      await _firestore.collection('queues').doc(docId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Update global earnings or stats manually if needed (queues earnings aren't in bookings listener)
      final snap = await _firestore.collection('queues').doc(docId).get();
      if (snap.exists) {
        final data = snap.data()!;
        final price = (data['price'] as num?)?.toInt() ?? 0;
        todayEarnings.value += price;
        weeklyEarnings.value += price;
        monthlyEarnings.value += price;
        completedCount.value++;

        final clientUid = data['clientUid'] as String?;
        if (clientUid != null && clientUid.isNotEmpty) {
          await _firestore.collection('notifications').add({
            'userId': clientUid,
            'title': 'Xizmat yakunlandi ✅',
            'message': 'Xizmatingiz yakunlandi. Tashrifingiz uchun rahmat!',
            'type': 'service_completed',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      Get.snackbar(
        "Tugallandi",
        "Mijozga xizmat ko'rsatildi",
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
      );
      HapticFeedback.heavyImpact();
    } catch (e) {
      Get.snackbar("Xato", "Tugatishda xatolik");
    }
  }

  Future<void> skipQueueClient(String docId) async {
    try {
      await _firestore.collection('queues').doc(docId).update({
        'status': 'skipped',
        'skippedAt': FieldValue.serverTimestamp(),
      });

      final queueDoc = await _firestore.collection('queues').doc(docId).get();
      final clientUid = queueDoc.data()?['clientUid'] as String?;
      if (clientUid != null && clientUid.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': clientUid,
          'title': 'Navbat o\'tkazib yuborildi ⚠️',
          'message':
              'Usta sizning navbatingizni kelmaganligingiz sababli o\'tkazib yubordi.',
          'type': 'no_show',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      Get.snackbar(
        "O'tkazildi",
        "Mijoz kelmagani sababli navbatdan o'tkazildi",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Xato", "O'tkazishda xatolik");
    }
  }

  // ============== PHOTO COMPRESSION & UPLOAD ==============
  final isUploadingPhoto = false.obs;

  Future<void> uploadProfileImage() async {
    isUploadingPhoto.value = true;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        isUploadingPhoto.value = false;
        return; // User cancelled
      }

      File nativeFile = File(pickedFile.path);

      // Security: pre-check file size (max 5MB raw)
      final fileSize = await nativeFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        Get.snackbar(
          "Fayl juda katta",
          "Rasm hajmi 5MB dan oshmasligi kerak",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        isUploadingPhoto.value = false;
        return;
      }

      // Compress Image (Pro optimization)
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
            nativeFile.absolute.path,
            targetPath,
            quality: 60,
            minWidth: 800,
            minHeight: 800,
          );

      if (compressedFile == null) {
        Get.snackbar("Xato", "Rasmni tayyorlashda xatolik");
        isUploadingPhoto.value = false;
        return;
      }

      final fileToUpload = File(compressedFile.path);

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('barbers')
          .child('${Get.find<UserService>().currentUid}.jpg');

      await storageRef.putFile(fileToUpload);
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore Barber Collection
      if (_barberDocRef != null) {
        await _barberDocRef!.update({'image': downloadUrl});
      } else {
        final snapshot = await _firestore
            .collection('barbers')
            .where('uid', isEqualTo: currentUid)
            .get();
        if (snapshot.docs.isNotEmpty) {
          _barberDocRef = snapshot.docs.first.reference;
          await _barberDocRef!.update({'image': downloadUrl});
        }
      }

      // Update Global User Service
      Get.find<UserService>().updatePhotoUrl(downloadUrl);

      Get.snackbar(
        "Muvaffaqiyatli",
        "Rasm yuklandi va SIQILDI",
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Rasm yuklashda xatolik yuz berdi",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  // ============== WORKING HOURS ==============
  Future<Map<String, String>> getWorkingHours() async {
    try {
      if (_barberDocRef != null) {
        final doc = await _barberDocRef!.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('workingHours')) {
            return {
              'open': data['workingHours']['open'] ?? '09:00',
              'close': data['workingHours']['close'] ?? '21:00',
            };
          }
        }
      } else {
        final snapshot = await _firestore
            .collection('barbers')
            .where('uid', isEqualTo: currentUid)
            .get();
        if (snapshot.docs.isNotEmpty) {
          _barberDocRef = snapshot.docs.first.reference;
          final data = snapshot.docs.first.data();
          if (data.containsKey('workingHours')) {
            return {
              'open': data['workingHours']['open'] ?? '09:00',
              'close': data['workingHours']['close'] ?? '21:00',
            };
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching working hours: $e");
    }
    return {'open': '09:00', 'close': '21:00'};
  }

  Future<void> updateWorkingHours(String open, String close) async {
    // Validate time format
    if (!_isValidTime(open) || !_isValidTime(close)) {
      Get.snackbar(
        "Xatolik",
        "Vaqt formati noto'g'ri (HH:mm)",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
      return;
    }

    // Validate open < close
    final openParts = open.split(':');
    final closeParts = close.split(':');
    final openMin = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
    final closeMin = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
    if (openMin >= closeMin) {
      Get.snackbar(
        "Xatolik",
        "Ochilish vaqti yopilish vaqtidan oldin bo'lishi kerak",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
      return;
    }

    try {
      if (_barberDocRef != null) {
        await _barberDocRef!.update({
          'workingHours': {'open': open, 'close': close},
        });
        Get.back();
        Get.snackbar(
          "Muvaffaqiyatli",
          "Ish vaqtingiz yangilandi",
          backgroundColor: AppTheme.success,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Ish vaqtini saqlashda xato",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    }
  }

  bool _isValidTime(String time) {
    if (time.length != 5) return false;
    final parts = time.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return false;
    return h >= 0 && h <= 23 && m >= 0 && m <= 59;
  }

  // ============== PORTFOLIO COMPRESSION & UPLOAD ==============
  final isUploadingPortfolio = false.obs;

  Future<void> uploadPortfolioImage() async {
    isUploadingPortfolio.value = true;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        isUploadingPortfolio.value = false;
        return;
      }

      File nativeFile = File(pickedFile.path);

      // Security: pre-check file size (max 5MB raw)
      final fileSize = await nativeFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        Get.snackbar(
          "Fayl juda katta",
          "Rasm hajmi 5MB dan oshmasligi kerak",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        isUploadingPortfolio.value = false;
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/portfolio_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
            nativeFile.absolute.path,
            targetPath,
            quality: 65,
            minWidth: 1080,
            minHeight: 1080,
          );

      if (compressedFile == null) {
        Get.snackbar("Xato", "Rasmni tayyorlashda xatolik");
        isUploadingPortfolio.value = false;
        return;
      }

      final fileToUpload = File(compressedFile.path);
      final fileName = 'portfolio_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('barbers')
          .child(Get.find<UserService>().currentUid)
          .child('portfolio')
          .child(fileName);

      await storageRef.putFile(fileToUpload);
      final downloadUrl = await storageRef.getDownloadURL();

      if (_barberDocRef != null) {
        await _barberDocRef!.update({
          'portfolioImages': FieldValue.arrayUnion([downloadUrl]),
        });
      }

      Get.snackbar(
        "Muvaffaqiyatli",
        "Portfolio rasm yuklandi",
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Portfolio rasm yuklashda xatolik yuz berdi",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    } finally {
      isUploadingPortfolio.value = false;
    }
  }

  Future<void> deletePortfolioImage(String url) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Attempt to delete from storage. Ignore if fails (e.g. wrong url struct)
      try {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
      } catch (_) {}

      // Remove from firestore
      if (_barberDocRef != null) {
        await _barberDocRef!.update({
          'portfolioImages': FieldValue.arrayRemove([url]),
        });
      }

      Get.back(); // close dialog
      Get.snackbar("O'chirildi", "Rasm portfoliodan olib tashlandi");
    } catch (e) {
      Get.back();
      Get.snackbar("Xatolik", "Rasmni o'chirishda xatolik yuz berdi");
    }
  }

  @override
  void onClose() {
    _bookingsSub?.cancel();
    _allBookingsSub?.cancel();
    _statusSub?.cancel();
    _queuesSub?.cancel();
    super.onClose();
  }
}
