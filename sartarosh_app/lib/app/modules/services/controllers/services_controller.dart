import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/user_service.dart';
import '../../home/controllers/home_controller.dart';

class ServicesController extends GetxController {
  final selectedService = Rxn<Map<String, dynamic>>();
  final services = <Map<String, dynamic>>[].obs;

  // Track the current category to filter by
  final currentCategory = 'Barchasi'.obs;
  final isLoading = true.obs;

  // Icon mapping for known service categories/names
  static const Map<String, int> _iconMap = {
    'soch olish': 0xe14f, // content_cut
    'soch turmak': 0xe14f,
    'soch turmaklash': 0xe14f,
    'soqol olish': 0xf04bc, // face
    'soqol': 0xf04bc,
    'kompleks': 0xf0597, // spa
    'styling': 0xe048, // auto_awesome
    'bosh yuvish': 0xf0806, // water_drop
    'makiyaj': 0xf1a0, // face_retouching_natural
    "bo'yash": 0xe15a, // color_lens
    'manikyur': 0xe6e1, // back_hand
    'bolalar': 0xe091, // child_care
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
            for (final gs in globalServices) {
              final name = (gs['name'] ?? '') as String;
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

  int _getIcon(String name, String category) {
    final lower = name.toLowerCase();
    for (final entry in _iconMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    final catLower = category.toLowerCase();
    for (final entry in _iconMap.entries) {
      if (catLower.contains(entry.key)) return entry.value;
    }
    return 0xe14f; // fallback: content_cut
  }

  void selectService(Map<String, dynamic> service) {
    selectedService.value = service;
  }
}
