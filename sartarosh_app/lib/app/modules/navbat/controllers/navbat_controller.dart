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

    // Query 'queues' collection for the client's active walk-in requests
    FirebaseFirestore.instance
        .collection('queues')
        .where('clientUid', isEqualTo: uid)
        .where('status', whereIn: ['waiting', 'in_progress'])
        .snapshots()
        .listen((shot) async {
          final List<Map<String, dynamic>> myQueues = [];

          for (var doc in shot.docs) {
            final data = doc.data();
            data['docId'] = doc.id;

            final barberId = data['barberId'];
            int queuePosition = 0;
            int estimatedWait = 0;

            if (data['status'] == 'waiting') {
              // Calculate live queue position based on arrival time
              final queueShot = await FirebaseFirestore.instance
                  .collection('queues')
                  .where('barberId', isEqualTo: barberId)
                  .where('status', isEqualTo: 'waiting')
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
              // Average 30 min wait per person ahead
              estimatedWait = queuePosition * 30;
            }

            // Map field names from queues collection to match NavbatView requirements
            data['serviceName'] = data['service'] ?? 'Xizmat turi';
            data['queuePosition'] = queuePosition;
            data['estimatedWait'] = estimatedWait;
            data['isQueue'] = true; // Flag for UI distinction

            myQueues.add(data);
          }

          // Also merge any 'in-progress' BOOKINGS (appointments) to show them here too
          // That way the user sees if they have an active appointment right now
          try {
            final now = DateTime.now();
            final todayStr =
                "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

            final bookingsShot = await FirebaseFirestore.instance
                .collection('bookings')
                .where('clientUid', isEqualTo: uid)
                .where('date', isEqualTo: todayStr)
                .where('status', whereIn: ['pending', 'in_progress'])
                .get();

            for (var bDoc in bookingsShot.docs) {
              final bData = bDoc.data();
              bData['docId'] = bDoc.id;
              bData['isQueue'] = false;
              myQueues.add(bData);
            }
          } catch (_) {}

          activeQueueBookings.value = myQueues;
          isLoading.value = false;
        });
  }
}
