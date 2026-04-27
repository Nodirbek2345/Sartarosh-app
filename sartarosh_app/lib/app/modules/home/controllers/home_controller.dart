import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/update_service.dart';
import '../views/widgets/review_bottom_sheet.dart';

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

    // Add the import at the top of the file mentally (will do another replace block)
    final sub = query.snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final docs = snapshot.docs.map((e) {
          final data = e.data();
          data['id'] = e.id;
          return data;
        }).toList();
        docs.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
        final doc = docs.first;
        lastBooking.value = doc;

        // Trigger Review Bottom Sheet if not rated
        if (doc['isRated'] != true) {
          Future.delayed(const Duration(seconds: 2), () {
            if (Get.isBottomSheetOpen != true) {
              Get.bottomSheet(
                ReviewBottomSheet(booking: doc),
                isScrollControlled: true,
                isDismissible: false,
                enableDrag: false,
              );
            }
          });
        }

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

  // ═══════════════════════════════════════════════════════
  // HAVERSINE DISTANCE (km)
  // ═══════════════════════════════════════════════════════
  static double _distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371.0; // Earth radius in km
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180);

  // ═══════════════════════════════════════════════════════
  // DUAL-MODE FETCH BARBERS
  // ═══════════════════════════════════════════════════════
  void _fetchBarbers() {
    final userService = Get.find<UserService>();
    final targetGender = userService.targetGender.value;
    final mode = userService.filterMode.value;
    final targetRegion = userService.selectedRegion.value;

    // Base query: always filter by gender
    var query = _firestore
        .collection('barbers')
        .where('gender', isEqualTo: targetGender);

    // REGION mode: add Firestore-level region filter
    if (mode == 'REGION' && targetRegion.isNotEmpty) {
      query = query.where('location', isEqualTo: targetRegion);
    }

    final sub = query.snapshots().listen(
      (snapshot) {
        var list = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // GPS mode: client-side distance filter (5km)
        if (mode == 'GPS' && userService.userLat.value != 0.0) {
          final myLat = userService.userLat.value;
          final myLng = userService.userLng.value;
          list = list.where((b) {
            final bLat = (b['lat'] as num?)?.toDouble() ?? 0.0;
            final bLng = (b['lng'] as num?)?.toDouble() ?? 0.0;
            if (bLat == 0.0 && bLng == 0.0) return false;
            final dist = _distanceKm(myLat, myLng, bLat, bLng);
            b['_distanceKm'] = dist; // inject distance for UI
            return dist <= 5.0;
          }).toList();
          // Sort by distance (nearest first)
          list.sort(
            (a, b) => ((a['_distanceKm'] as double?) ?? 99).compareTo(
              (b['_distanceKm'] as double?) ?? 99,
            ),
          );
        }

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

  // ═══════════════════════════════════════════════════════
  // MODE SWITCHES (PRO)
  // ═══════════════════════════════════════════════════════
  final isLocating = false.obs;

  Future<void> switchToGps() async {
    isLocating.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            "Ruxsat berilmadi",
            "GPS ruxsatini bering",
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          isLocating.value = false;
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          "GPS bloklangan",
          "Sozlamalardan GPS ni oching",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        isLocating.value = false;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Validate coordinates
      if (position.latitude < -90 ||
          position.latitude > 90 ||
          position.longitude < -180 ||
          position.longitude > 180) {
        Get.snackbar("Xatolik", "Noto'g'ri koordinatalar");
        isLocating.value = false;
        return;
      }

      final userService = Get.find<UserService>();
      userService.setGpsMode(position.latitude, position.longitude);
      _cancelBarberSubscriptions();
      _fetchBarbers();

      Get.snackbar(
        "📍 GPS faol",
        "5 km radiusdagi ustalar ko'rsatilmoqda",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        "GPS xatolik",
        "Joylashuvni aniqlab bo'lmadi",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLocating.value = false;
    }
  }

  void switchToRegion(String region) {
    final userService = Get.find<UserService>();
    userService.setRegionMode(region);
    _cancelBarberSubscriptions();
    _fetchBarbers();
  }

  /// Cancel only barber-related stream subscriptions before re-fetching
  void _cancelBarberSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    // Re-subscribe to non-barber streams
    _fetchServices();
    _fetchUpcomingBookings();
    _fetchPastBookings();
  }

  void refreshBarbers() {
    _cancelBarberSubscriptions();
    _fetchBarbers();
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.onClose();
  }
}
