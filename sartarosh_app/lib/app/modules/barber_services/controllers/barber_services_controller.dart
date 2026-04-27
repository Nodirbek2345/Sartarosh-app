import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/user_service.dart';

class BarberServicesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = Get.find<UserService>();

  final isLoading = true.obs;
  final isSaving = false.obs;

  // List of all editable services
  final servicesList = <RxMap<String, dynamic>>[].obs;

  // Icon mapping
  static const Map<String, int> _iconMap = {
    'soch olish': 0xe14f,
    'soch turmak': 0xe14f,
    'soqol olish': 0xf04bc,
    'kompleks': 0xf0597,
    'styling': 0xe048,
    'bosh yuvish': 0xf0806,
    'makiyaj': 0xf1a0,
    "bo'yash": 0xe15a,
    'manikyur': 0xe6e1,
    'bolalar': 0xe091,
  };

  @override
  void onInit() {
    super.onInit();
    _fetchServices();
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

  Future<void> _fetchServices() async {
    try {
      isLoading.value = true;
      final uid = _userService.currentUid;

      // 1. Fetch Global Services
      final globalSnap = await _firestore.collection('services').get();
      final globalServices = globalSnap.docs.map((d) => d.data()).toList();

      // 2. Fetch Barber's custom services
      final barberDocSnap = await _firestore
          .collection('barbers')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      List<dynamic> myServices = [];
      String barberGender = 'male'; // Default if missing

      if (barberDocSnap.docs.isNotEmpty) {
        final data = barberDocSnap.docs.first.data();
        myServices = data['services'] ?? [];
        barberGender = data['gender'] ?? 'male';
      }

      final myServiceMap = <String, Map<String, dynamic>>{};
      for (var s in myServices) {
        final name = s['name'] ?? '';
        if (name.isNotEmpty) {
          myServiceMap[name] = s;
        }
      }

      // 3. Build reactive list
      final builtList = <RxMap<String, dynamic>>[];
      for (var g in globalServices) {
        final serviceGender = g['gender'] ?? 'all';

        // Filter out services that don't match exactly the barber's gender (or all)
        if (serviceGender != barberGender && serviceGender != 'all') continue;

        final name = g['name'] ?? '';
        final category = g['category'] ?? '';

        final myData = myServiceMap[name];
        final isEnabled = myData != null;
        final price = myData?['price'] ?? 15000;
        final duration = myData?['duration'] ?? 30;

        builtList.add(
          {
            'name': name,
            'category': category,
            'icon': _getIcon(name, category),
            'isEnabled': isEnabled,
            'price': price,
            'duration': duration,
          }.obs,
        );
      }

      servicesList.value = builtList;
    } catch (e) {
      Get.snackbar("Xato", "Xizmatlarni yuklashda xatolik yuz berdi");
    } finally {
      isLoading.value = false;
    }
  }

  void toggleService(int index) {
    final s = servicesList[index];
    s['isEnabled'] = !(s['isEnabled'] as bool);
  }

  void updatePrice(int index, int newPrice) {
    if (newPrice < 0) return;
    servicesList[index]['price'] = newPrice;
  }

  void updateDuration(int index, int newDuration) {
    if (newDuration < 5) return;
    servicesList[index]['duration'] = newDuration;
  }

  Future<void> saveSettings() async {
    isSaving.value = true;
    try {
      final uid = _userService.currentUid;
      final activeServices = servicesList
          .where((s) => s['isEnabled'] == true)
          .map(
            (s) => {
              'name': s['name'],
              'category': s['category'],
              'price': s['price'],
              'duration': s['duration'],
            },
          )
          .toList();

      final snapshot = await _firestore
          .collection('barbers')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'services': activeServices,
        });
        Get.snackbar(
          "Saqlandi",
          "Xizmatlar va narxlar muvaffaqiyatli saqlandi!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar("Xato", "Barber profili topilmadi");
      }
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Saqlashda xatolik yuz berdi",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }
}
