import 'package:sartarosh_app/core/theme/app_theme.dart';
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
    "to'y": 0xf06bb,
    'custom': 0xe145, // star icon for custom services
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

      // 2. Fetch Barber's current services
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

      // Track which names came from global catalog
      final globalNames = <String>{};

      // 3. Build reactive list from global services
      final builtList = <RxMap<String, dynamic>>[];
      for (var g in globalServices) {
        final serviceGender = g['gender'] ?? 'all';

        // Filter out services that don't match exactly the barber's gender (or all)
        if (serviceGender != barberGender && serviceGender != 'all') continue;

        final name = g['name'] ?? '';
        final category = g['category'] ?? '';
        globalNames.add(name);

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
            'isCustom': false,
          }.obs,
        );
      }

      // 4. Add barber's custom services (not in global catalog)
      for (var s in myServices) {
        final name = s['name'] ?? '';
        if (name.isNotEmpty && !globalNames.contains(name)) {
          final category = s['category'] ?? 'Maxsus';
          builtList.add(
            {
              'name': name,
              'category': category,
              'icon': _getIcon(name, category),
              'isEnabled': true,
              'price': s['price'] ?? 15000,
              'duration': s['duration'] ?? 30,
              'isCustom': true,
            }.obs,
          );
        }
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

  // ═══════════════════════════════════════════
  // ADD CUSTOM SERVICE
  // ═══════════════════════════════════════════
  void showAddCustomServiceDialog() {
    final nameCtrl = TextEditingController();
    final selectedCategory = 'Maxsus'.obs;
    final categories = [
      'Maxsus',
      'Kompleks',
      'Soch olish',
      'Soqol olish',
      'Styling',
      'Bosh yuvish',
      'Bolalar',
      "To'y marasim",
      'Makiyaj',
      "Bo'yash",
      'Manikyur',
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "➕ Yangi xizmat qo'shish",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Masalan: Bosh yuvish + Soch olish",
                style: TextStyle(fontSize: 13, color: AppTheme.textMedium),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Xizmat nomi",
                  hintText: "Masalan: Bosh yuvish + Soch olish",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  prefixIcon: Icon(Icons.content_cut, color: AppTheme.primary),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Text(
                "Kategoriya",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final isSelected = selectedCategory.value == cat;
                    return GestureDetector(
                      onTap: () => selectedCategory.value = cat,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      Get.snackbar(
                        "Xatolik",
                        "Xizmat nomini kiriting",
                        backgroundColor: AppTheme.danger,
                        colorText: Colors.white,
                      );
                      return;
                    }
                    // Check for duplicate
                    final exists = servicesList.any(
                      (s) =>
                          (s['name'] as String).toLowerCase() ==
                          name.toLowerCase(),
                    );
                    if (exists) {
                      Get.snackbar(
                        "Xatolik",
                        "Bu xizmat allaqachon mavjud",
                        backgroundColor: AppTheme.danger,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    final category = selectedCategory.value;
                    servicesList.add(
                      {
                        'name': name,
                        'category': category,
                        'icon': _getIcon(name, category),
                        'isEnabled': true,
                        'price': 15000,
                        'duration': 30,
                        'isCustom': true,
                      }.obs,
                    );
                    Get.back();
                    Get.snackbar(
                      "Qo'shildi ✅",
                      "\"$name\" xizmati qo'shildi. Narx va vaqtni sozlang.",
                      backgroundColor: AppTheme.success,
                      colorText: Colors.white,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Qo'shish",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ═══════════════════════════════════════════
  // DELETE CUSTOM SERVICE
  // ═══════════════════════════════════════════
  void deleteCustomService(int index) {
    final s = servicesList[index];
    if (s['isCustom'] != true) return;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("O'chirish"),
        content: Text("\"${s['name']}\" xizmatini o'chirishni xohlaysizmi?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Bekor qilish"),
          ),
          TextButton(
            onPressed: () {
              servicesList.removeAt(index);
              Get.back();
              Get.snackbar("O'chirildi", "Xizmat o'chirildi");
            },
            child: Text("O'chirish", style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
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
          "Saqlandi ✅",
          "Xizmatlar va narxlar muvaffaqiyatli saqlandi!",
          backgroundColor: AppTheme.success,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar("Xato", "Barber profili topilmadi");
      }
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Saqlashda xatolik yuz berdi",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }
}
