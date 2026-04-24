import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServicesController extends GetxController {
  final selectedService = Rxn<Map<String, dynamic>>();
  final services = <Map<String, dynamic>>[].obs;

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
    _loadServicesFromBarbers();
  }

  void _loadServicesFromBarbers() {
    FirebaseFirestore.instance
        .collection('barbers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((querySnapshot) {
          final Map<String, Map<String, dynamic>> aggregated = {};

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

              if (aggregated.containsKey(name)) {
                // Track min/max prices and barber count
                final existing = aggregated[name]!;
                final minP = existing['minPrice'] as int;
                final maxP = existing['maxPrice'] as int;
                existing['minPrice'] = price < minP ? price : minP;
                existing['maxPrice'] = price > maxP ? price : maxP;
                existing['barberCount'] = (existing['barberCount'] as int) + 1;
                // Average duration
                final totalDur = (existing['totalDuration'] as int) + duration;
                final count = existing['barberCount'] as int;
                existing['totalDuration'] = totalDur;
                existing['duration'] = totalDur ~/ count;
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
