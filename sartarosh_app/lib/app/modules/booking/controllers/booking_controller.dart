import 'package:sartarosh_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/input_sanitizer.dart';
import '../../../../core/utils/booking_slot_lock.dart';

class BookingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Profil / xizmatdan kelgan usta — filtrdan tashqarida bo'lsa ham ro'yxatda qoladi
  Map<String, dynamic>? _argumentBarber;

  // Step management
  final currentStep = 0.obs;

  // Step 1: Barber
  final selectedBarber = Rxn<Map<String, dynamic>>();
  final barbers = <Map<String, dynamic>>[].obs;
  final suggestedBarbers = <Map<String, dynamic>>[].obs;
  final isRefreshingBarbers = false.obs;

  void refreshBarbers() {
    isRefreshingBarbers.value = true;
    _fetchBarbers();
    Future.delayed(Duration(milliseconds: 800), () {
      isRefreshingBarbers.value = false;
    });
  }

  // Step 2: Date & Time
  final selectedDate = DateTime.now().obs;
  final viewingMonth = DateTime.now().obs; // For calendar UI navigation
  final selectedTime = ''.obs;
  final allTimes = <String>[].obs;
  final availableTimes = <String>[].obs;
  final customTimeController = TextEditingController();

  void onCustomTimeChanged(String val) {
    if (val.length == 5 && val.contains(':')) {
      final parts = val.split(':');
      final hh = int.tryParse(parts[0]);
      final mm = int.tryParse(parts[1]);
      if (hh != null &&
          mm != null &&
          hh >= 8 &&
          hh <= 22 &&
          mm >= 0 &&
          mm <= 59) {
        selectedTime.value = val;
      }
    }
  }

  // Step 3: Payment
  final selectedPaymentMethod = 'cash'.obs;

  StreamSubscription<QuerySnapshot>? _bookingsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _barbersSub;

  // Step 3: Service info (passed from arguments)
  String serviceName = 'Soch olish';
  int servicePrice = 30000;
  int _serviceDuration = 30; // actual duration from barber data

  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args['barber'] != null && args['barber'] is Map) {
      _argumentBarber = Map<String, dynamic>.from(
        args['barber'] as Map<String, dynamic>,
      );
      selectedBarber.value = _argumentBarber;
    }
    _fetchBarbers();

    if (args != null) {
      if (args['service'] != null) {
        serviceName = InputSanitizer.sanitizeText(args['service']);
      }
      if (args['price'] != null) {
        final p = args['price'];
        servicePrice = p is int
            ? p
            : (p is num ? p.toInt() : int.tryParse('$p') ?? servicePrice);
      }
      if (args['duration'] != null) {
        final d = args['duration'];
        _serviceDuration = d is int
            ? d
            : (d is num ? d.toInt() : int.tryParse('$d') ?? _serviceDuration);
      }
    }

    ever(selectedDate, (_) => _updateAvailableTimes());
    ever(selectedBarber, (_) {
      _generateTimeSlots(); // regenerate based on new barber's hours
      _updateAvailableTimes();
    });
    _generateTimeSlots();
    _updateAvailableTimes(); // initial load
  }

  int get serviceDurationMinutes => _serviceDuration;

  ({int openMin, int closeMin}) _workingDayBoundsMinutes() {
    var openMin = 9 * 60;
    var closeMin = 21 * 60;
    try {
      final wh = selectedBarber.value?['workingHours'];
      if (wh != null) {
        final open = wh['open'] as String? ?? '09:00';
        final close = wh['close'] as String? ?? '21:00';
        final op = open.split(':');
        final cl = close.split(':');
        final oh = int.parse(op[0].trim());
        final om = op.length > 1 ? int.parse(op[1].trim()) : 0;
        final ch = int.parse(cl[0].trim());
        final cm = cl.length > 1 ? int.parse(cl[1].trim()) : 0;
        openMin = oh * 60 + om;
        closeMin = ch * 60 + cm;
      }
    } catch (_) {}
    if (closeMin <= openMin) closeMin = openMin + 8 * 60;
    return (openMin: openMin, closeMin: closeMin);
  }

  void _generateTimeSlots() {
    final b = _workingDayBoundsMinutes();
    final slots = <String>[];
    for (var m = b.openMin; m < b.closeMin; m += 30) {
      final h = m ~/ 60;
      final mm = m % 60;
      slots.add(
        '${h.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}',
      );
    }
    allTimes.value = slots;
  }

  @override
  void onClose() {
    _bookingsSub?.cancel();
    _barbersSub?.cancel();
    customTimeController.dispose();
    super.onClose();
  }

  static double _degToRad(double deg) => deg * (math.pi / 180);

  static double _distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  void _fetchBarbers() {
    _barbersSub?.cancel();
    final userService = Get.find<UserService>();
    final userGender = userService.targetGender.value;
    final mode = userService.filterMode.value;
    final targetRegion = userService.selectedRegion.value;

    Query<Map<String, dynamic>> query = _firestore
        .collection('barbers')
        .where('gender', isEqualTo: userGender);

    if (mode == 'REGION') {
      if (targetRegion.isEmpty) {
        barbers.value = [];
        suggestedBarbers.clear();
        return;
      }
      query = query.where('location', isEqualTo: targetRegion);
    }

    _barbersSub = query.snapshots().listen((snapshot) {
      var list = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((b) => b['uid'] != userService.currentUid)
          .toList();

      final hasGps =
          userService.userLat.value != 0.0 && userService.userLng.value != 0.0;

      if (mode == 'GPS') {
        if (!hasGps) {
          list = [];
        } else {
          final myLat = userService.userLat.value;
          final myLng = userService.userLng.value;
          list = list.where((b) {
            final bLat = (b['lat'] as num?)?.toDouble() ?? 0.0;
            final bLng = (b['lng'] as num?)?.toDouble() ?? 0.0;
            if (bLat == 0.0 && bLng == 0.0) return false;
            return _distanceKm(myLat, myLng, bLat, bLng) <= 20.0;
          }).toList();
          list.sort((a, b) {
            final da = _distanceKm(
              myLat,
              myLng,
              (a['lat'] as num?)?.toDouble() ?? 0,
              (a['lng'] as num?)?.toDouble() ?? 0,
            );
            final db = _distanceKm(
              myLat,
              myLng,
              (b['lat'] as num?)?.toDouble() ?? 0,
              (b['lng'] as num?)?.toDouble() ?? 0,
            );
            return da.compareTo(db);
          });
        }
      }

      final pinned = _argumentBarber;
      if (pinned != null) {
        final pid = pinned['id']?.toString();
        if (pid != null &&
            pid.isNotEmpty &&
            !list.any((e) => e['id']?.toString() == pid)) {
          list = [Map<String, dynamic>.from(pinned), ...list];
        }
      }

      barbers.value = list;

      if (list.isEmpty) {
        _fetchSuggestedBarbers(userService);
      } else {
        suggestedBarbers.clear();
        final selId = selectedBarber.value?['id']?.toString();
        if (selectedBarber.value == null ||
            (selId != null && !list.any((b) => b['id']?.toString() == selId))) {
          selectedBarber.value = list.first;
        }
      }
    });
  }

  void _fetchSuggestedBarbers(UserService userService) async {
    try {
      final gender = userService.targetGender.value;
      final mode = userService.filterMode.value;
      final region = userService.selectedRegion.value;
      final hasGps =
          userService.userLat.value != 0.0 && userService.userLng.value != 0.0;

      final snap = await _firestore
          .collection('barbers')
          .where('gender', isEqualTo: gender)
          .limit(40)
          .get();

      var list = snap.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where(
            (b) => b['isActive'] != false && b['uid'] != userService.currentUid,
          )
          .toList();

      if (mode == 'REGION' && region.isNotEmpty) {
        list = list
            .where((b) => (b['location']?.toString() ?? '') == region)
            .toList();
      } else if (mode == 'GPS' && hasGps) {
        final myLat = userService.userLat.value;
        final myLng = userService.userLng.value;
        list = list.where((b) {
          final bLat = (b['lat'] as num?)?.toDouble() ?? 0.0;
          final bLng = (b['lng'] as num?)?.toDouble() ?? 0.0;
          if (bLat == 0.0 && bLng == 0.0) return false;
          return _distanceKm(myLat, myLng, bLat, bLng) <= 25.0;
        }).toList();
      }

      list.sort((a, b) {
        final ra = (a['rating'] as num?)?.toDouble() ?? 0;
        final rb = (b['rating'] as num?)?.toDouble() ?? 0;
        if (rb.compareTo(ra) != 0) return rb.compareTo(ra);
        if (mode == 'GPS' && hasGps) {
          final myLat = userService.userLat.value;
          final myLng = userService.userLng.value;
          final da = _distanceKm(
            myLat,
            myLng,
            (a['lat'] as num?)?.toDouble() ?? 0,
            (a['lng'] as num?)?.toDouble() ?? 0,
          );
          final db = _distanceKm(
            myLat,
            myLng,
            (b['lat'] as num?)?.toDouble() ?? 0,
            (b['lng'] as num?)?.toDouble() ?? 0,
          );
          return da.compareTo(db);
        }
        return 0;
      });

      suggestedBarbers.value = list.take(8).toList();
    } catch (_) {}
  }

  void _updateAvailableTimes() {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    final barberId = selectedBarber.value?['id'];

    if (barberId == null) {
      availableTimes.value = List.from(allTimes);
      return;
    }

    _bookingsSub?.cancel();
    _bookingsSub = _firestore
        .collection('bookings')
        .where('barberId', isEqualTo: barberId)
        .where('date', isEqualTo: dateStr)
        .where('status', whereIn: ['confirmed', 'pending', 'in-progress'])
        .snapshots()
        .listen((bookingsSnap) {
          Set<String> blockedTimes = {};

          for (var doc in bookingsSnap.docs) {
            final data = doc.data();
            final t = data['time']?.toString() ?? '';
            if (t.length < 4) continue;
            final dur = (data['durationMinutes'] is num)
                ? (data['durationMinutes'] as num).toInt()
                : int.tryParse('${data['durationMinutes'] ?? 30}') ?? 30;

            try {
              DateTime baseTime = DateFormat('HH:mm').parse(t);
              int slotsToBlock = (dur / 30).ceil();
              if (slotsToBlock < 1) slotsToBlock = 1;

              for (int i = 0; i < slotsToBlock; i++) {
                final blocked = baseTime.add(Duration(minutes: i * 30));
                blockedTimes.add(DateFormat('HH:mm').format(blocked));
              }
            } catch (_) {}
          }

          final now = DateTime.now();
          final isToday =
              selectedDate.value.year == now.year &&
              selectedDate.value.month == now.month &&
              selectedDate.value.day == now.day;

          availableTimes.value = allTimes.where((t) {
            // 1) Filter past times on current day
            if (isToday) {
              final parts = t.split(':');
              if (parts.length == 2) {
                final hr = int.parse(parts[0]);
                final min = int.parse(parts[1]);
                final slotTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  hr,
                  min,
                );
                if (slotTime.isBefore(now)) return false;
              }
            }

            // 2) Check overlaps client-side dynamically
            int requiredSlots = (serviceDurationMinutes / 30).ceil();
            if (requiredSlots < 1) requiredSlots = 1;

            try {
              DateTime candidateTime = DateFormat('HH:mm').parse(t);
              for (int i = 0; i < requiredSlots; i++) {
                final forwardSlot = candidateTime.add(
                  Duration(minutes: i * 30),
                );
                if (blockedTimes.contains(
                  DateFormat('HH:mm').format(forwardSlot),
                )) {
                  return false; // Intersection found!
                }
              }
            } catch (_) {}

            return true;
          }).toList();

          if (!availableTimes.contains(selectedTime.value)) {
            selectedTime.value = '';
          }
        });
  }

  void nextStep() {
    if (currentStep.value == 0 && selectedBarber.value == null) {
      Get.snackbar(
        "Usta tanlang",
        "Davom etish uchun ro'yxatdan ustani tanlang.",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
      return;
    }
    if (currentStep.value < 2) {
      currentStep.value++;
    }
  }

  /// GPS yo'q bo'lganda (bron sahifasida) joylashuvni bir martalik olish
  Future<void> enableGpsForBooking() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            "Ruxsat yo'q",
            "Yaqin ustalarni ko'rish uchun joylashuv ruxsatini bering.",
            backgroundColor: AppTheme.danger,
            colorText: Colors.white,
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          "GPS bloklangan",
          "Sozlamalardan ilova uchun joylashuvni yoqing.",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final userService = Get.find<UserService>();
      userService.setGpsMode(position.latitude, position.longitude);
      refreshBarbers();
      Get.snackbar(
        "GPS yoqildi",
        "Endi yaqin ustalarni ko'rasiz.",
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        "Xatolik",
        "Joylashuvni aniqlab bo'lmadi. Internet va GPSni tekshiring.",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    }
  }

  void prevStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  void nextMonth() {
    viewingMonth.value = DateTime(
      viewingMonth.value.year,
      viewingMonth.value.month + 1,
      1,
    );
  }

  void prevMonth() {
    final now = DateTime.now();
    final newMonth = DateTime(
      viewingMonth.value.year,
      viewingMonth.value.month - 1,
      1,
    );

    // Do not allow viewing months entirely in the past (before current month)
    if (newMonth.year > now.year ||
        (newMonth.year == now.year && newMonth.month >= now.month)) {
      viewingMonth.value = newMonth;
    }
  }

  void selectBarber(Map<String, dynamic> barber) {
    selectedBarber.value = barber;
  }

  void selectDate(DateTime date) {
    // Block past dates
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    if (date.isBefore(todayNorm)) return;
    selectedDate.value = date;
  }

  void selectTime(String time) {
    selectedTime.value = time;
  }

  void selectNearestAvailableTime() {
    if (availableTimes.isNotEmpty) {
      selectedTime.value = availableTimes.first;
    } else {
      Get.snackbar(
        "Kechirasiz",
        "Bugun uchun bo'sh vaqt qolmadi",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    }
  }

  String get formattedDate =>
      DateFormat('dd.MM.yyyy').format(selectedDate.value);

  Future<void> confirmBooking() async {
    // Rate limiting - prevent spam
    if (!InputSanitizer.canPerformAction(cooldown: Duration(seconds: 5))) {
      Get.snackbar(
        "Biroz kuting",
        "Iltimos, qayta urinishdan oldin 5 soniya kuting",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Validate time format
    if (!InputSanitizer.isValidTimeFormat(selectedTime.value)) {
      Get.snackbar(
        "Xatolik",
        "Vaqt formati noto'g'ri",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
      return;
    }

    // Validate date range (max 30 days ahead)
    final maxDate = DateTime.now().add(const Duration(days: 30));
    if (selectedDate.value.isAfter(maxDate)) {
      Get.snackbar(
        "Xatolik",
        "Bronni faqat 30 kun oldindan qilish mumkin",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final userService = Get.find<UserService>();

      // Security: verify user is authenticated
      if (!userService.isAuthenticated) {
        Get.snackbar(
          "Xatolik",
          "Iltimos, avval tizimga kiring",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        Get.offAllNamed('/phone-login');
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
      final barberName = selectedBarber.value?['name'] ?? 'Noma\'lum';
      final uid = userService.currentUid;

      // Validate time is selected
      if (selectedTime.value.isEmpty) {
        Get.snackbar(
          "Xatolik",
          "Iltimos, vaqtni tanlang",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        isSubmitting.value = false;
        return;
      }

      // We already checked overlaps client-side in the StreamSubscription
      // But verify strictly!
      if (!availableTimes.contains(selectedTime.value)) {
        Get.snackbar(
          "Vaqt band!",
          "Kechirasiz, ustaning bu vaqti allaqachon band. Boshqa vaqt tanlang.",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        isSubmitting.value = false;
        return;
      }

      // Anti-abuse: Check no-shows limit (Max 2)
      final pastNoShows = await _firestore
          .collection('bookings')
          .where('clientUid', isEqualTo: uid)
          .where('status', isEqualTo: 'no-show')
          .get();

      if (pastNoShows.docs.length >= 2) {
        Get.snackbar(
          "Bloklangan!",
          "Sizda 2 marta yoki undan ko'p 'Kelmadi' holati mavjud. Bron qilish vaqtincha ta'qiqlanadi.",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
        isSubmitting.value = false;
        return;
      }

      // Check globally active bookings limit (max 2 active bookings per user)
      final userActiveBookings = await _firestore
          .collection('bookings')
          .where('clientUid', isEqualTo: uid)
          .where('status', whereIn: ['confirmed', 'pending', 'in-progress'])
          .get();

      if (userActiveBookings.docs.length >= 2) {
        Get.snackbar(
          "Limit!",
          "Sizda bir vaqtning o'zida maksimal 2 ta faol bron bo'lishi mumkin.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        isSubmitting.value = false;
        return;
      }

      // Anti-abuse: Cancellation rate check (max 3 cancels in 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentCancels = await _firestore
          .collection('bookings')
          .where('clientUid', isEqualTo: uid)
          .where('status', isEqualTo: 'cancelled')
          .get();

      int recentCancelCount = 0;
      for (var doc in recentCancels.docs) {
        final createdAt = doc.data()['createdAt'];
        if (createdAt != null) {
          final ts = (createdAt as dynamic).toDate();
          if (ts.isAfter(sevenDaysAgo)) {
            recentCancelCount++;
          }
        }
      }
      if (recentCancelCount >= 3) {
        Get.snackbar(
          "Ogohlantirish",
          "Siz ohirgi 7 kunda 3 marta bron bekor qildingiz. Yangi bron qilish vaqtincha cheklangan.",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
        isSubmitting.value = false;
        return;
      }

      // === Atomik slot + bron (faqat transaction.get) ===
      final barberId = selectedBarber.value?['id'] ?? '';
      final timeVal = selectedTime.value;
      if (barberId.isEmpty) {
        Get.snackbar(
          "Xatolik",
          "Usta tanlanmagan",
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
        isSubmitting.value = false;
        return;
      }

      final lockRef = BookingSlotLock.ref(
        _firestore,
        barberId,
        dateStr,
        timeVal,
      );
      final barberRef = _firestore.collection('barbers').doc(barberId);
      final priceForDb = servicePrice < 1 ? 1 : servicePrice;

      await _firestore.runTransaction((transaction) async {
        final lockSnap = await transaction.get(lockRef);
        if (lockSnap.exists) {
          throw Exception('TIME_SLOT_TAKEN');
        }

        final barberSnap = await transaction.get(barberRef);
        if (!barberSnap.exists) {
          throw Exception('BARBER_NOT_FOUND');
        }
        final barberUid = barberSnap.data()?['uid'] as String? ?? '';
        final barberGender =
            barberSnap.data()?['gender']?.toString().toLowerCase() ?? 'male';
        final clientGender = Get.find<UserService>().targetGender.value
            .toLowerCase();
        if (barberGender != 'all' && barberGender != clientGender) {
          throw Exception('GENDER_MISMATCH');
        }

        final newDocRef = _firestore.collection('bookings').doc();
        transaction.set(lockRef, {
          'barberId': barberId,
          'barberUid': barberUid,
          'date': dateStr,
          'time': timeVal,
          'bookingId': newDocRef.id,
          'clientUid': uid,
        });

        transaction.set(newDocRef, {
          'clientUid': uid,
          'client': InputSanitizer.sanitizeText(userService.name.value),
          'clientPhone': InputSanitizer.sanitizePhone(userService.phone.value),
          'barberName': barberName,
          'barberId': barberId,
          'barberUid': barberUid,
          'service': InputSanitizer.sanitizeText(serviceName),
          'price': priceForDb,
          'durationMinutes': serviceDurationMinutes,
          'date': dateStr,
          'time': timeVal,
          'paymentType': selectedPaymentMethod.value,
          'paymentStatus': selectedPaymentMethod.value == 'cash'
              ? 'unpaid'
              : 'pending_payment',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (barberUid.isNotEmpty) {
          final notifRef = _firestore.collection('notifications').doc();
          transaction.set(notifRef, {
            'userId': barberUid,
            'title': 'Yangi bron so\'rovi 📩',
            'message':
                '${InputSanitizer.sanitizeText(userService.name.value)} sizga $dateStr $timeVal ga ($serviceName) bron so\'rovi yubordi. Tasdiqlash yoki rad etish uchun panelga kiring.',
            'type': 'booking_created',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      Get.snackbar(
        "Bron yuborildi! 📩",
        "Usta tasdiqlashini kuting",
        backgroundColor: Color(0xFFC9A96E),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(16),
        borderRadius: 16,
      );

      await Future.delayed(Duration(seconds: 1));
      Get.offAllNamed('/home');
    } catch (e) {
      final es = e.toString();
      final msg = es.contains('TIME_SLOT_TAKEN')
          ? "Bu vaqt allaqachon band. Boshqa vaqt tanlang."
          : es.contains('BARBER_NOT_FOUND')
          ? "Usta ma'lumotlari topilmadi. Sahifani yangilang."
          : es.contains('GENDER_MISMATCH')
          ? "Tanlangan usta siz tanlagan bo'lim (erkaklar/ayollar) uchun mos emas."
          : "Bron qilishda xatolik yuz berdi. Qaytadan urinib ko'ring.";
      Get.snackbar(
        "Xatolik",
        msg,
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
