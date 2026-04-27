import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/input_sanitizer.dart';

class BookingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Step management
  final currentStep = 0.obs;

  // Step 1: Barber
  final selectedBarber = Rxn<Map<String, dynamic>>();
  final barbers = <Map<String, dynamic>>[].obs;

  // Step 2: Date & Time
  final selectedDate = DateTime.now().obs;
  final viewingMonth = DateTime.now().obs; // For calendar UI navigation
  final selectedTime = ''.obs;
  final allTimes = <String>[].obs;
  final availableTimes = <String>[].obs;

  StreamSubscription<QuerySnapshot>? _bookingsSub;

  // Step 3: Service info (passed from arguments)
  String serviceName = 'Soch olish';
  int servicePrice = 30000;

  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchBarbers();

    final args = Get.arguments;
    if (args != null) {
      if (args['barber'] != null) {
        selectedBarber.value = args['barber'];
      }
      if (args['service'] != null) {
        serviceName = InputSanitizer.sanitizeText(args['service']);
      }
      if (args['price'] != null) {
        servicePrice = args['price'];
      }
    }

    ever(selectedDate, (_) => _updateAvailableTimes());
    ever(selectedBarber, (_) => _updateAvailableTimes());
    _generateTimeSlots();
    _updateAvailableTimes(); // initial load
  }

  int get serviceDurationMinutes {
    final lower = serviceName.toLowerCase();
    if (lower.contains('soch')) return 30;
    if (lower.contains('soqol')) return 20;
    if (lower.contains('kompleks') || lower.contains('komplex')) return 60;
    if (lower.contains('bo\'yash') || lower.contains('makiyaj')) return 60;
    return 30; // default 30 mins
  }

  void _generateTimeSlots() {
    List<String> slots = [];
    int startHour = 9;
    int endHour = 20; // 09:00 to 20:00
    for (int h = startHour; h < endHour; h++) {
      String hr = h.toString().padLeft(2, '0');
      slots.add('$hr:00');
      slots.add('$hr:30');
    }
    allTimes.value = slots;
  }

  @override
  void onClose() {
    _bookingsSub?.cancel();
    super.onClose();
  }

  void _fetchBarbers() {
    final userService = Get.find<UserService>();
    final userGender = userService.targetGender.value;

    _firestore
        .collection('barbers')
        .where('targetGender', isEqualTo: userGender)
        .where('isActive', isEqualTo: true) // Only show active barbers
        .snapshots()
        .listen((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          barbers.value = list;

          if (list.isNotEmpty &&
              (selectedBarber.value == null ||
                  !list.any((b) => b['id'] == selectedBarber.value?['id']))) {
            selectedBarber.value = list.first;
          }
        });
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
            final t = data['time'] as String;
            final dur = data['durationMinutes'] ?? 30; // fallbacks

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
    if (currentStep.value < 2) {
      currentStep.value++;
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
        backgroundColor: Colors.redAccent,
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

    isSubmitting.value = true;
    try {
      final userService = Get.find<UserService>();

      // Security: verify user is authenticated
      if (!userService.isAuthenticated) {
        Get.snackbar(
          "Xatolik",
          "Iltimos, avval tizimga kiring",
          backgroundColor: Colors.redAccent,
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
          backgroundColor: Colors.redAccent,
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
          backgroundColor: Colors.redAccent,
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
          backgroundColor: Colors.redAccent,
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

      // === SERVER-SIDE DOUBLE BOOKING GUARD (Transaction) ===
      final barberId = selectedBarber.value?['id'] ?? '';
      final timeVal = selectedTime.value;

      await _firestore.runTransaction((transaction) async {
        // Re-check for overlapping bookings inside the transaction
        final conflictQuery = await _firestore
            .collection('bookings')
            .where('barberId', isEqualTo: barberId)
            .where('date', isEqualTo: dateStr)
            .where('time', isEqualTo: timeVal)
            .where('status', whereIn: ['confirmed', 'pending', 'in-progress'])
            .get();

        if (conflictQuery.docs.isNotEmpty) {
          throw Exception('TIME_SLOT_TAKEN');
        }

        final newDocRef = _firestore.collection('bookings').doc();
        transaction.set(newDocRef, {
          'clientUid': uid,
          'client': InputSanitizer.sanitizeText(userService.name.value),
          'clientPhone': InputSanitizer.sanitizePhone(userService.phone.value),
          'barberName': barberName,
          'barberId': barberId,
          'service': InputSanitizer.sanitizeText(serviceName),
          'price': servicePrice,
          'durationMinutes': serviceDurationMinutes,
          'date': dateStr,
          'time': timeVal,
          'paymentType': 'cash',
          'paymentStatus': 'unpaid',
          'status': 'confirmed',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      Get.snackbar(
        "Broningiz muvaffaqiyatli tasdiqlandi! ✅",
        "Sizni kutib qolamiz",
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
      Get.snackbar(
        "Xatolik",
        "Bron qilishda xatolik yuz berdi",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
