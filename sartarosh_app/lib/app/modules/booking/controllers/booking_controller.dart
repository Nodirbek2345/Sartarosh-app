import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
  final selectedTime = ''.obs;
  final availableTimes = <String>[].obs;
  final _allTimes = ['10:00', '12:00', '14:00', '16:00', '18:00'];

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
    _updateAvailableTimes(); // initial load
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

  Future<void> _updateAvailableTimes() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value);
    final barberName = selectedBarber.value?['name'];

    if (barberName == null) {
      availableTimes.value = List.from(_allTimes);
      return;
    }

    try {
      final bookingsSnap = await _firestore
          .collection('bookings')
          .where('barberName', isEqualTo: barberName)
          .where('date', isEqualTo: dateStr)
          .where('status', whereIn: ['confirmed', 'pending', 'in-progress'])
          .get();

      final bookedTimes = bookingsSnap.docs
          .map((doc) => doc.data()['time'] as String)
          .toList();
      availableTimes.value = _allTimes
          .where((t) => !bookedTimes.contains(t))
          .toList();

      if (bookedTimes.contains(selectedTime.value)) {
        selectedTime.value = '';
      }
    } catch (_) {
      availableTimes.value = List.from(_allTimes);
    }
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

  void selectBarber(Map<String, dynamic> barber) {
    selectedBarber.value = barber;
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
  }

  void selectTime(String time) {
    selectedTime.value = time;
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

      // Smart Booking Check (Prevent double booking)
      final existingBookings = await _firestore
          .collection('bookings')
          .where('barberName', isEqualTo: barberName)
          .where('date', isEqualTo: dateStr)
          .where('time', isEqualTo: selectedTime.value)
          .where('status', whereIn: ['confirmed', 'pending', 'in-progress'])
          .get();

      if (existingBookings.docs.isNotEmpty) {
        Get.snackbar(
          "Vaqt band!",
          "Kechirasiz, ustaning bu vaqti allaqachon band. Boshqa vaqt tanlang.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        isSubmitting.value = false;
        return;
      }

      // Check daily limit for this user (max 3 bookings per day)
      final userDailyBookings = await _firestore
          .collection('bookings')
          .where('clientUid', isEqualTo: uid)
          .where('date', isEqualTo: dateStr)
          .where('status', whereIn: ['confirmed', 'pending', 'in-progress'])
          .get();

      if (userDailyBookings.docs.length >= 3) {
        Get.snackbar(
          "Limit!",
          "Kuniga eng ko'pi bilan 3 ta bron qilish mumkin",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        isSubmitting.value = false;
        return;
      }

      await _firestore.collection('bookings').add({
        'clientUid': uid, // Secure: UID-based identification
        'client': InputSanitizer.sanitizeText(userService.name.value),
        'clientPhone': InputSanitizer.sanitizePhone(userService.phone.value),
        'barberName': barberName,
        'barberId': selectedBarber.value?['id'] ?? '',
        'service': InputSanitizer.sanitizeText(serviceName),
        'price': servicePrice,
        'date': dateStr,
        'time': selectedTime.value,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
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
