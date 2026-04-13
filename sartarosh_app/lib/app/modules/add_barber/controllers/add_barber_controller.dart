import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/input_sanitizer.dart';

class AddBarberController extends GetxController {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final expCtrl = TextEditingController();
  final aboutCtrl = TextEditingController();
  final haircutPriceCtrl = TextEditingController();
  final beardPriceCtrl = TextEditingController();
  final comboPriceCtrl = TextEditingController();

  final openTime = "09:00".obs;
  final closeTime = "21:00".obs;
  final gender = "male".obs; // 'male' or 'female'
  final location = "".obs; // barber's region

  final isSubmitting = false.obs;
  final currentStep = 0.obs; // 0 = info, 1 = services, 2 = preview

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    final userService = Get.find<UserService>();
    location.value = userService.selectedRegion.value;
    gender.value = userService.targetGender.value;
  }

  void nextStep() {
    if (currentStep.value == 0) {
      if (!InputSanitizer.isValidName(nameCtrl.text)) {
        _error("Iltimos, haqiqiy ism kiriting (harflar bilan)");
        return;
      }
      final sanitizedPhone = InputSanitizer.sanitizePhone(phoneCtrl.text);
      if (!InputSanitizer.isValidPhone(sanitizedPhone)) {
        _error("Iltimos, to'g'ri telefon raqamni kiriting");
        return;
      }
      if (addressCtrl.text.trim().isEmpty) {
        _error("Iltimos, manzilingizni kiriting");
        return;
      }
    }
    if (currentStep.value == 1) {
      if (!InputSanitizer.isValidPrice(haircutPriceCtrl.text)) {
        _error("Iltimos, kamida bitta asosiy xizmat narxini to'g'ri kiriting");
        return;
      }
    }
    if (currentStep.value < 2) currentStep.value++;
  }

  void prevStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  void _error(String msg) {
    Get.snackbar(
      "Xatolik",
      msg,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  int get haircutPrice =>
      int.tryParse(haircutPriceCtrl.text.replaceAll('.', '').trim()) ?? 0;
  int get beardPrice =>
      int.tryParse(beardPriceCtrl.text.replaceAll('.', '').trim()) ?? 0;
  int get comboPrice =>
      int.tryParse(comboPriceCtrl.text.replaceAll('.', '').trim()) ?? 0;

  bool get isFemale => Get.find<UserService>().targetGender.value == 'female';

  List<Map<String, dynamic>> get servicesList {
    final list = <Map<String, dynamic>>[];
    if (haircutPrice > 0) {
      list.add({
        'name': isFemale ? 'Soch turmaklash' : 'Soch olish',
        'price': haircutPrice,
        'duration': 30,
      });
    }
    if (beardPrice > 0) {
      list.add({
        'name': isFemale ? "Bo'yash / Ukladka" : 'Soqol olish',
        'price': beardPrice,
        'duration': 40,
      });
    }
    if (comboPrice > 0) {
      list.add({
        'name': isFemale ? 'Soch + Makiyaj' : 'Soch + Soqol',
        'price': comboPrice,
        'duration': 60,
      });
    }
    return list;
  }

  Future<void> submitRegistration() async {
    // Rate Limiting
    if (!InputSanitizer.canPerformAction(cooldown: Duration(seconds: 10))) {
      return;
    }

    isSubmitting.value = true;
    try {
      final safeName = InputSanitizer.sanitizeText(nameCtrl.text);
      final safePhone = InputSanitizer.sanitizePhone(phoneCtrl.text);
      final safeAddress = InputSanitizer.sanitizeText(addressCtrl.text);
      final safeAbout = InputSanitizer.sanitizeText(aboutCtrl.text);
      final uid = Get.find<UserService>().currentUid;

      await _firestore.collection('barbers').add({
        'uid': uid, // Link barber to user's UID for security
        'name': safeName,
        'phone': safePhone,
        'address': safeAddress,
        'gender': gender.value,
        'location': location.value,
        'image':
            'https://i.pravatar.cc/500?u=${DateTime.now().millisecondsSinceEpoch}',
        'rating': 5.0,
        'reviewCount': 0,
        'experience': int.tryParse(expCtrl.text.trim()) ?? 1,
        'about': safeAbout.isNotEmpty ? safeAbout : 'Professional sartarosh',
        'workingHours': {'open': openTime.value, 'close': closeTime.value},
        'services': servicesList,
        'tags': ['Yangi'],
        'isActive': true,
        'queueLimit': 10, // default
        'targetGender': isFemale ? 'female' : 'male',
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        "Muvaffaqiyatli! 🎉",
        "Siz usta sifatida ro'yxatdan o'tdingiz",
        backgroundColor: AppTheme.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );

      await Future.delayed(Duration(milliseconds: 800));
      Get.offAllNamed('/home');
    } catch (e) {
      _error(
        "Ro'yxatdan o'tishda xatolik yuz berdi. Iltimos qaytadan urinib ko'ring.",
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    expCtrl.dispose();
    aboutCtrl.dispose();
    haircutPriceCtrl.dispose();
    beardPriceCtrl.dispose();
    comboPriceCtrl.dispose();
    super.onClose();
  }
}
