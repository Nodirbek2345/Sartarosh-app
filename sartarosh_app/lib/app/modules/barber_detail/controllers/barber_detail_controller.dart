import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/input_sanitizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class BarberDetailController extends GetxController {
  late Map<String, dynamic> barber;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final isJoiningQueue = false.obs;
  final distanceText = "".obs;

  @override
  void onInit() {
    super.onInit();
    barber = Get.arguments as Map<String, dynamic>? ?? {};
    _calculateDistance();
  }

  void _calculateDistance() {
    final userService = Get.find<UserService>();
    final uLat = userService.userLat.value;
    final uLng = userService.userLng.value;

    final bLat = barber['latitude'] ?? barber['lat'];
    final bLng = barber['longitude'] ?? barber['lng'];

    if (uLat != 0.0 && uLng != 0.0 && bLat != null && bLng != null) {
      double d = _haversine(
        uLat,
        uLng,
        (bLat as num).toDouble(),
        (bLng as num).toDouble(),
      );
      distanceText.value = "${d.toStringAsFixed(1)} km uzoqlikda";
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  void bookNow() {
    Get.toNamed('/booking', arguments: barber);
  }

  Future<void> openDirections() async {
    final lat = barber['latitude'] ?? barber['lat'];
    final lng = barber['longitude'] ?? barber['lng'];

    if (lat == null || lng == null) {
      // Fallback or error if no exact coords
      Get.snackbar(
        "Joylashuv mavjud emas",
        "Ustaning aniq xarita manzili (GPS) kiritilmagan",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final url = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        "Xatolik",
        "Xarita dasturini ochishda xatolik yuz berdi",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    }
  }

  Future<void> joinQueue(
    String serviceName,
    int price,
    int serviceDuration,
  ) async {
    final userService = Get.find<UserService>();
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

    if (!InputSanitizer.canPerformAction(
      cooldown: const Duration(seconds: 5),
    )) {
      Get.snackbar("Biroz kuting", "Iltimos, biroz kuting");
      return;
    }

    isJoiningQueue.value = true;
    try {
      final String barberId = barber['id'] ?? '';
      final String barberUid = barber['uid'] ?? '';

      // Calculate queue length (waiting + in_progress)
      final activeQueues = await _firestore
          .collection('queues')
          .where('barberId', isEqualTo: barberId)
          .where('status', whereIn: ['waiting', 'in_progress'])
          .get();

      final queueLength = activeQueues.docs.length;

      final num rawLimit = barber['queueLimit'] ?? 10;
      final int queueLimit = rawLimit.toInt();

      if (queueLength >= queueLimit) {
        Get.snackbar(
          "Navbat to'la",
          "Kechirasiz, hozircha ustaning jonli navbati to'lgan. Birozdan so'ng qayta urining yoki vaqtni band qiling.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        isJoiningQueue.value = false;
        return;
      }

      final estimatedTimeMinutes = queueLength * 30; // approx 30m avg

      await _firestore.collection('queues').add({
        'clientUid': userService.currentUid,
        'client': InputSanitizer.sanitizeText(userService.name.value),
        'clientPhone': InputSanitizer.sanitizePhone(userService.phone.value),
        'barberName': barber['name'] ?? 'Usta',
        'barberId': barberId,
        'barberUid': barberUid,
        'service': InputSanitizer.sanitizeText(serviceName),
        'price': price,
        'status': 'waiting',
        'queuePosition': queueLength + 1,
        'estimatedWaitMinutes': estimatedTimeMinutes,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (barberUid.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': barberUid,
          'title': 'Yangi navbat 🚶',
          'message':
              '${InputSanitizer.sanitizeText(userService.name.value)} jonli navbatga qo\'shildi. Uning navbati: ${queueLength + 1}.',
          'type': 'queue_joined',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Get.back(); // Close bottom sheet
      Get.snackbar(
        "Navbatga yozildingiz! 🎉",
        "Sizdan oldin $queueLength kishi bor. Taxminiy kutilish vaqti: $estimatedTimeMinutes daqiqa.",
        backgroundColor: AppTheme.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      await Future.delayed(const Duration(seconds: 1));
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Xatolik yuz berdi. Qaytadan urinib ko'ring.",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    } finally {
      isJoiningQueue.value = false;
    }
  }
}
