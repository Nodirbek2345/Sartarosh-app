import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/user_service.dart';

class MyBookingsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final activeBookings = <Map<String, dynamic>>[].obs;
  final pastBookings = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;

  StreamSubscription? _bookingsSub;

  @override
  void onInit() {
    super.onInit();
    _fetchBookings();
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
        return s == 'completed' ||
            s == 'cancelled' ||
            s == 'no-show' ||
            s == 'penalty';
      }).toList();

      isLoading.value = false;
    });
  }

  Future<void> cancelBooking(String id, String dateStr, String timeStr) async {
    try {
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
      if (newStatus == 'penalty') {
        Get.snackbar(
          "Ogohlantirish",
          "Bron kech bekor qilingani sababli tizimda qayd etildi.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar("Muvaffaqiyatli", "Bron bekor qilindi!");
      }
    } catch (e) {
      Get.snackbar("Xatolik", "Bekor qilishda xatolik yuz berdi");
    }
  }

  void rebook(Map<String, dynamic> b) {
    _firestore
        .collection('barbers')
        .where('name', isEqualTo: b['barberName'])
        .limit(1)
        .get()
        .then((snap) {
          if (snap.docs.isNotEmpty) {
            final barber = snap.docs.first.data();
            barber['id'] = snap.docs.first.id;
            Get.toNamed(
              '/booking',
              arguments: {
                'barber': barber,
                'service': b['service'] ?? 'Soch olish',
                'price': b['price'] ?? 30000,
              },
            );
          } else {
            Get.snackbar("Xatolik", "Usta tizimdan topilmadi.");
          }
        });
  }

  @override
  void onClose() {
    _bookingsSub?.cancel();
    super.onClose();
  }
}
