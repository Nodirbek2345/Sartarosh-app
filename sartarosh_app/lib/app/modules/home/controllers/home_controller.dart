import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/update_service.dart';

class HomeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final rxBarbers = <Map<String, dynamic>>[].obs;
  final rxServices = <Map<String, dynamic>>[].obs;
  final upcomingBooking = Rxn<Map<String, dynamic>>();
  final lastBooking = Rxn<Map<String, dynamic>>();
  final smartRecommendationText = "".obs;
  final isLoading = true.obs;

  // Stream subscriptions for proper cleanup
  final List<StreamSubscription> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _fetchBarbers();
    _fetchServices();
    _fetchUpcomingBookings();
    _fetchPastBookings();
  }

  @override
  void onReady() {
    super.onReady();
    Get.find<UpdateService>().checkUpdate();
  }

  void _fetchServices() {
    final sub = _firestore.collection('services').snapshots().listen((
      snapshot,
    ) {
      rxServices.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'category': data['category'] ?? '',
        };
      }).toList();
    });
    _subscriptions.add(sub);
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'soch olish':
        return Icons.content_cut_rounded;
      case 'soqol olish':
        return Icons.face_rounded;
      case 'kompleks':
        return Icons.auto_awesome_rounded;
      case 'maxsus':
        return Icons.spa_rounded;
      default:
        return Icons.content_cut_rounded;
    }
  }

  void _fetchUpcomingBookings() {
    final userService = Get.find<UserService>();
    final uid = userService.currentUid;

    // Use UID for secure queries, fallback to name for backward compatibility
    final query = uid.isNotEmpty
        ? _firestore
              .collection('bookings')
              .where('clientUid', isEqualTo: uid)
              .where('status', whereIn: ['confirmed', 'pending'])
        : _firestore
              .collection('bookings')
              .where('client', isEqualTo: userService.name.value)
              .where('status', whereIn: ['confirmed', 'pending']);

    final sub = query.snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first.data();
        upcomingBooking.value = doc;
      } else {
        upcomingBooking.value = null;
      }
    });
    _subscriptions.add(sub);
  }

  void _fetchPastBookings() {
    final userService = Get.find<UserService>();
    final uid = userService.currentUid;

    final query = uid.isNotEmpty
        ? _firestore
              .collection('bookings')
              .where('clientUid', isEqualTo: uid)
              .where('status', whereIn: ['completed'])
        : _firestore
              .collection('bookings')
              .where('client', isEqualTo: userService.name.value)
              .where('status', whereIn: ['completed']);

    final sub = query.snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final docs = snapshot.docs.map((e) => e.data()).toList();
        docs.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
        final doc = docs.first;
        lastBooking.value = doc;

        // Smart AI recommendation logic
        final dateStr = doc['date'] as String?;
        if (dateStr != null) {
          try {
            final lastDate = DateTime.parse(dateStr);
            final daysSince = DateTime.now().difference(lastDate).inDays;
            if (daysSince > 10) {
              smartRecommendationText.value =
                  "Siz odatda har 2 haftada kelasiz. Sochingizni yangilash vaqti keldi!";
            } else {
              smartRecommendationText.value =
                  "Siz oxirgi marta $daysSince kun oldin tashrif buyurdingiz.";
            }
          } catch (_) {
            smartRecommendationText.value = "Oxirgi tashrifingizni takrorlang";
          }
        } else {
          smartRecommendationText.value = "Oxirgi tashrifingizni takrorlang";
        }
      } else {
        lastBooking.value = null;
        smartRecommendationText.value = "";
      }
    });
    _subscriptions.add(sub);
  }

  void _fetchBarbers() {
    final userService = Get.find<UserService>();
    final targetGender = userService.targetGender.value;

    // Server-side filtering by gender for efficiency
    final sub = _firestore
        .collection('barbers')
        .where('gender', isEqualTo: targetGender)
        .snapshots()
        .listen(
          (snapshot) {
            final list = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
            rxBarbers.value = list;
            isLoading.value = false;
          },
          onError: (e) {
            isLoading.value = false;
            Get.snackbar("Xatolik", "Baza bilan ulanishda xatolik");
          },
        );
    _subscriptions.add(sub);
  }

  void refreshBarbers() {
    isLoading.value = true;
    // Cancel old barber subscription and re-fetch
    _fetchBarbers();
  }

  @override
  void onClose() {
    // Cancel all stream subscriptions to prevent memory leaks
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.onClose();
  }
}
