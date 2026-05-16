import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/user_service.dart';

class NavbatController extends GetxController {
  final userService = Get.find<UserService>();
  final isLoading = true.obs;

  // Kutishyotgan navbatlar (mijozning faol bronlari uchun)
  final activeQueueBookings = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Agar barber bo'lsa darxol dashboard'ga olib o'tadi
    if (userService.userRole.value == 'barber') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/home');
        // Barber dashboard'a o'tish home orqali yoki to'g'ridan-to'g'ri bo'lishi mumkin
      });
      return;
    }

    _listenToMyQueueBookings();
  }

  void _listenToMyQueueBookings() {
    final uid = userService.currentUid;
    if (uid.isEmpty) {
      isLoading.value = false;
      return;
    }

    // Faqat bugungi pending yoki in_progress bronlarimizni olaiz
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    FirebaseFirestore.instance
        .collection('bookings')
        .where('clientUid', isEqualTo: uid)
        .where('date', isEqualTo: todayStr)
        .where('status', whereIn: ['pending', 'in_progress'])
        .snapshots()
        .listen((shot) async {
          final List<Map<String, dynamic>> myBookings = [];

          for (var doc in shot.docs) {
            final data = doc.data();
            data['docId'] = doc.id;

            // Barber id orqali queue pozitsiyani hisoblaymiz
            final barberId = data['barberId'];
            int queuePosition = 0;
            int estimatedWait = 0;

            if (data['isQueue'] == true && data['status'] == 'pending') {
              // Queue pozitsiyani topish
              final queueShot = await FirebaseFirestore.instance
                  .collection('bookings')
                  .where('barberId', isEqualTo: barberId)
                  .where('date', isEqualTo: todayStr)
                  .where('isQueue', isEqualTo: true)
                  .where('status', isEqualTo: 'pending')
                  .orderBy('createdAt', descending: false)
                  .get();

              int pos = 1;
              for (var qDoc in queueShot.docs) {
                if (qDoc.id == doc.id) {
                  queuePosition = pos;
                  break;
                }
                pos++;
              }
              estimatedWait =
                  queuePosition * 30; // Har bir mijozga o'rtacha 30 daqiqa
            }

            data['queuePosition'] = queuePosition;
            data['estimatedWait'] = estimatedWait;

            myBookings.add(data);
          }

          activeQueueBookings.value = myBookings;
          isLoading.value = false;
        });
  }
}
