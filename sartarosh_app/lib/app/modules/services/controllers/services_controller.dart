import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/user_service.dart';
import '../../home/controllers/home_controller.dart';
import '../../add_barber/controllers/add_barber_controller.dart';

class ServicesController extends GetxController {
  final selectedService = Rxn<Map<String, dynamic>>();
  final services = <Map<String, dynamic>>[].obs;

  // Track the current category to filter by
  final currentCategory = 'Barchasi'.obs;
  final isLoading = true.obs;

  // Icon mapping for known service categories/names
  static const Map<String, IconData> _iconMap = {
    'soch olish': Icons.content_cut_rounded,
    'soch turmak': Icons.content_cut_rounded,
    'soch turmaklash': Icons.content_cut_rounded,
    'soqol olish': Icons.face_rounded,
    'soqol': Icons.face_rounded,
    'kompleks': Icons.spa_rounded,
    'styling': Icons.auto_awesome_rounded,
    'bosh yuvish': Icons.water_drop_rounded,
    'makiyaj': Icons.face_retouching_natural_rounded,
    "bo'yash": Icons.color_lens_rounded,
    'manikyur': Icons.back_hand_rounded,
    'bolalar': Icons.child_care_rounded,
    "to'y marasim": Icons.celebration_rounded,
  };

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is String) {
      currentCategory.value = Get.arguments;
    }
    _loadServicesFromBarbers();
  }

  void _loadServicesFromBarbers() {
    isLoading.value = true;
    final targetGender = Get.find<UserService>().targetGender.value;

    FirebaseFirestore.instance
        .collection('barbers')
        .where('gender', isEqualTo: targetGender)
        .snapshots()
        .listen((querySnapshot) {
          final Map<String, Map<String, dynamic>> aggregated = {};

          try {
            final globalServices = Get.find<HomeController>().rxServices;
            final allServices = [
              ...globalServices,
              ...AddBarberController.defaultServices,
            ];

            // Track by unique name to prevent duplicates if globalServices already has it
            final Set<String> processedNames = {};

            for (final gs in allServices) {
              final name = (gs['name'] ?? '') as String;
              if (processedNames.contains(name)) continue;

              final category = (gs['category'] ?? '') as String;
              final serviceGender = (gs['gender'] ?? 'all') as String;
              if (name.isEmpty) continue;

              // Skip services that don't match the target gender
              if (serviceGender != targetGender && serviceGender != 'all') {
                continue;
              }

              if (currentCategory.value != 'Barchasi') {
                final target = currentCategory.value.toLowerCase();
                final matchCat = category.toLowerCase().contains(target);
                final matchName = name.toLowerCase().contains(target);
                if (!matchCat && !matchName) continue;
              }

              processedNames.add(name);

              aggregated[name] = {
                'name': name,
                'category': category,
                'price': 0,
                'minPrice': 0,
                'maxPrice': 0,
                'duration': 0,
                'totalDuration': 0,
                'barberCount': 0,
                'icon': _getIcon(name, category),
              };
            }
          } catch (_) {}

          for (final doc in querySnapshot.docs) {
            final data = doc.data();
            if (data['uid'] == Get.find<UserService>().currentUid) continue;
            final barberServices = data['services'] as List?;
            if (barberServices == null) continue;

            for (final s in barberServices) {
              final sMap = s as Map<String, dynamic>;
              final name = (sMap['name'] ?? '') as String;
              if (name.isEmpty) continue;

              final price = (sMap['price'] ?? 0) as int;
              final duration = (sMap['duration'] ?? 30) as int;
              final category = (sMap['category'] ?? '') as String;

              // Apply Logic Filtering
              if (currentCategory.value != 'Barchasi') {
                final target = currentCategory.value.toLowerCase();
                final matchCat = category.toLowerCase().contains(target);
                final matchName = name.toLowerCase().contains(target);

                // Keep if either category maps to it, or name contains it
                if (!matchCat && !matchName) continue;
              }

              if (aggregated.containsKey(name)) {
                // Track min/max prices and barber count
                final existing = aggregated[name]!;
                final minP = existing['minPrice'] as int;
                final maxP = existing['maxPrice'] as int;

                if (existing['barberCount'] == 0) {
                  existing['minPrice'] = price;
                  existing['maxPrice'] = price;
                  existing['duration'] = duration;
                  existing['totalDuration'] = duration;
                  existing['barberCount'] = 1;
                } else {
                  existing['minPrice'] = price < minP ? price : minP;
                  existing['maxPrice'] = price > maxP ? price : maxP;
                  existing['barberCount'] =
                      (existing['barberCount'] as int) + 1;
                  // Average duration
                  final totalDur =
                      (existing['totalDuration'] as int) + duration;
                  final count = existing['barberCount'] as int;
                  existing['totalDuration'] = totalDur;
                  existing['duration'] = totalDur ~/ count;
                }
              } else {
                aggregated[name] = {
                  'name': name,
                  'category': category,
                  'price': price,
                  'minPrice': price,
                  'maxPrice': price,
                  'duration': duration,
                  'totalDuration': duration,
                  'barberCount': 1,
                  'icon': _getIcon(name, category),
                };
              }
            }
          }

          // Sort by barber count (most popular first)
          final result = aggregated.values.toList()
            ..sort(
              (a, b) =>
                  (b['barberCount'] as int).compareTo(a['barberCount'] as int),
            );

          services.value = result;
          isLoading.value = false;
        });
  }

  IconData _getIcon(String name, String category) {
    final lower = name.toLowerCase();
    for (final entry in _iconMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    final catLower = category.toLowerCase();
    for (final entry in _iconMap.entries) {
      if (catLower.contains(entry.key)) return entry.value;
    }
    return Icons.content_cut_rounded; // fallback
  }

  void selectService(Map<String, dynamic> service) {
    selectedService.value = service;
  }
}
