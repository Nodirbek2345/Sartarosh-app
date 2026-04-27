import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/input_sanitizer.dart';

class AddBarberController extends GetxController {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final expCtrl = TextEditingController();
  final aboutCtrl = TextEditingController();
  final servicesList = <RxMap<String, dynamic>>[].obs;
  final isLoadingServices = true.obs;

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

  final openTime = "09:00".obs;
  final closeTime = "21:00".obs;
  final gender = "male".obs; // 'male' or 'female'
  final location = "".obs; // barber's region
  final selectedImagePath = "".obs;

  // Location Pro Feature
  final isLocating = false.obs;
  final lat = 0.0.obs;
  final lng = 0.0.obs;

  final isSubmitting = false.obs;
  final currentStep = 0.obs; // 0 = info, 1 = services, 2 = preview

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    final userService = Get.find<UserService>();
    location.value = userService.selectedRegion.value;
    gender.value = userService.targetGender.value;

    // Reactively filter services whenever the barber changes gender
    ever(gender, (_) => _filterServices());

    _fetchGlobalServices();

    // Auto-fetch location for Pro experience
    Future.microtask(() => fetchLocation());
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
    return 0xe14f;
  }

  // Store all raw services from Firestore in memory to avoid redundant DB trips
  final _allRawServices = <Map<String, dynamic>>[];

  // Standard services catalog — auto-seeded if missing from Firestore
  // Each service has a 'gender' field: 'male', 'female', or 'all'
  static const List<Map<String, String>> _defaultServices = [
    // ─── ERKAKLAR (male) ───
    {'name': 'Soch olish', 'category': 'Soch olish', 'gender': 'male'},
    {'name': 'Soqol olish', 'category': 'Soqol olish', 'gender': 'male'},
    {'name': 'Soch + Soqol', 'category': 'Kompleks', 'gender': 'male'},
    {'name': 'Styling', 'category': 'Styling', 'gender': 'male'},
    {'name': 'Bosh yuvish', 'category': 'Bosh yuvish', 'gender': 'male'},
    {'name': 'Bolalar soch olish', 'category': 'Bolalar', 'gender': 'male'},

    // ─── AYOLLAR (female) ───
    {'name': 'Soch turmaklash', 'category': 'Soch turmak', 'gender': 'female'},
    {"name": "Bo'yash", "category": "Bo'yash", "gender": "female"},
    {'name': 'Makiyaj', 'category': 'Makiyaj', 'gender': 'female'},
    {'name': 'Manikyur', 'category': 'Manikyur', 'gender': 'female'},
    {'name': 'Soch kesish', 'category': 'Soch olish', 'gender': 'female'},
    {'name': 'Kompleks xizmat', 'category': 'Kompleks', 'gender': 'female'},
  ];

  Future<void> _fetchGlobalServices() async {
    try {
      isLoadingServices.value = true;

      // Auto-seed and Auto-patch: ensure all default services exist AND have the correct gender tag
      for (final def in _defaultServices) {
        final defName = def['name']!;
        try {
          final query = await _firestore
              .collection('services')
              .where('name', isEqualTo: defName)
              .get();

          if (query.docs.isEmpty) {
            // Missing? Add it
            await _firestore.collection('services').add(def);
          } else {
            // Exists? Ensure it has the correct gender field
            for (var doc in query.docs) {
              if (doc.data()['gender'] != def['gender']) {
                await doc.reference.update({'gender': def['gender']});
              }
            }
          }
        } catch (e) {
          debugPrint("Failed to seed/patch service $defName: $e");
        }
      }

      // Re-fetch after seeding/patching
      final freshSnap = await _firestore.collection('services').get();

      // Cache all raw services
      _allRawServices.clear();
      for (final doc in freshSnap.docs) {
        _allRawServices.add(doc.data());
      }

      // Initial filter based on current `gender.value`
      _filterServices();
    } catch (e) {
      debugPrint("Error fetching global services: $e");
    } finally {
      isLoadingServices.value = false;
    }
  }

  void _filterServices() {
    final barberGender = gender.value; // 'male' or 'female'
    final list = <RxMap<String, dynamic>>[];

    for (final data in _allRawServices) {
      final serviceGender = data['gender'] ?? 'all';

      // Show only services matching barber's gender (or 'all')
      if (serviceGender != barberGender && serviceGender != 'all') continue;

      final name = data['name'] ?? '';
      final category = data['category'] ?? '';
      list.add(
        {
          'name': name,
          'category': category,
          'icon': _getIcon(name, category),
          'priceCtrl': TextEditingController(text: '0'),
        }.obs,
      );
    }
    servicesList.value = list;
  }

  void nextStep() {
    if (currentStep.value == 0) {
      if (!InputSanitizer.isValidName(nameCtrl.text)) {
        _error("Iltimos, haqiqiy ism kiriting (harflar bilan)");
        return;
      }
      final sanitizedPhone = InputSanitizer.sanitizePhone(phoneCtrl.text);
      if (!InputSanitizer.isValidPhone(sanitizedPhone)) {
        _error("Iltimos, to'g'ri telefon raqamni kiriting");
        return;
      }
      if (addressCtrl.text.trim().isEmpty) {
        _error("Iltimos, manzilingizni kiriting");
        return;
      }
    }
    if (currentStep.value == 1) {
      bool hasActiveService = false;
      for (var s in servicesList) {
        final ctrl = s['priceCtrl'] as TextEditingController;
        final price = int.tryParse(ctrl.text.replaceAll('.', '').trim()) ?? 0;
        if (price > 0) {
          hasActiveService = true;
          break;
        }
      }
      if (!hasActiveService) {
        _error("Iltimos, kamida bitta xizmat narxini to'g'ri kiriting");
        return;
      }
    }
    if (currentStep.value < 2) currentStep.value++;
  }

  void prevStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  void _error(String msg) {
    Get.snackbar(
      "Xatolik",
      msg,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  List<Map<String, dynamic>> get activeServices {
    final list = <Map<String, dynamic>>[];
    for (var s in servicesList) {
      final ctrl = s['priceCtrl'] as TextEditingController;
      final price = int.tryParse(ctrl.text.replaceAll('.', '').trim()) ?? 0;
      if (price > 0) {
        list.add({
          'name': s['name'],
          'category': s['category'] ?? '',
          'price': price,
          'duration': 30, // Default duration, they can edit later in profile
        });
      }
    }
    return list;
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Optimize image
      );
      if (pickedFile != null) {
        selectedImagePath.value = pickedFile.path;
      }
    } catch (e) {
      _error("Rasm tanlashda xatolik yuz berdi");
    }
  }

  Future<void> fetchLocation() async {
    isLocating.value = true;
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error("Joylashuvni aniqlash uchun ruxsat berilmadi.");
          isLocating.value = false;
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _error("Siz joylashuvni butunlay bloklagansiz. Sozlamalardan oching.");
        isLocating.value = false;
        return;
      }

      // Get location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      lat.value = position.latitude;
      lng.value = position.longitude;

      // OSM Reverse Geocoding
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {'lat': lat.value, 'lon': lng.value, 'format': 'json'},
        options: Options(
          headers: {
            'User-Agent': 'SartaroshApp/1.0', // OSM requires user-agent
            'Accept-Language': 'uz-UZ', // Prefer Uzbek/Latin format
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['display_name'] != null) {
          addressCtrl.text = data['display_name'];
          // PRO: Extract REGION (state) from OSM, not city/town
          if (data['address'] != null) {
            final addr = data['address'];
            // Priority: state > city > county
            String regionRaw =
                addr['state'] ?? addr['city'] ?? addr['county'] ?? "Toshkent";
            // Strip suffixes to match app region names
            location.value = regionRaw
                .replaceAll(' viloyati', '')
                .replaceAll(' shahri', '')
                .replaceAll(' Region', '')
                .replaceAll(' Province', '')
                .trim();
          }
          Get.snackbar(
            "Muvaffaqiyatli ✅",
            "Joylashuv: ${location.value}",
            backgroundColor: AppTheme.primary,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      _showRegionFallbackDialog();
    } finally {
      isLocating.value = false;
    }
  }

  void _showRegionFallbackDialog() {
    Get.snackbar(
      "GPS Xatolik",
      "Joylashuvni avtomatik aniqlab bo'lmadi. O'zingiz tanlang.",
      backgroundColor: AppTheme.primary,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 4),
    );

    final regions = [
      {'name': 'Toshkent shahri', 'lat': 41.311081, 'lng': 69.240562},
      {'name': 'Andijon viloyati', 'lat': 40.782064, 'lng': 72.344246},
      {'name': 'Farg\'ona viloyati', 'lat': 40.38639, 'lng': 71.71882},
      {'name': 'Namangan viloyati', 'lat': 41.00108, 'lng': 71.67257},
      {'name': 'Samarqand viloyati', 'lat': 39.627012, 'lng': 66.974973},
      {'name': 'Buxoro viloyati', 'lat': 39.77472, 'lng': 64.42861},
      {'name': 'Xorazm viloyati', 'lat': 41.55, 'lng': 60.63333},
      {'name': 'Qashqadaryo viloyati', 'lat': 38.89639, 'lng': 65.78361},
      {'name': 'Surxondaryo viloyati', 'lat': 37.22806, 'lng': 67.27833},
      {'name': 'Sirdaryo viloyati', 'lat': 40.85, 'lng': 68.66667},
      {'name': 'Jizzax viloyati', 'lat': 40.11583, 'lng': 67.84222},
      {'name': 'Navoiy viloyati', 'lat': 40.08444, 'lng': 65.37917},
      {'name': 'Toshkent viloyati', 'lat': 41.2, 'lng': 69.85},
      {'name': 'Qoraqalpog\'iston', 'lat': 42.46667, 'lng': 59.61667},
    ];

    Get.bottomSheet(
      Container(
        height: 400,
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Text(
                "Viloyatni qo'lda tanlang",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: regions.length,
                  itemBuilder: (context, index) {
                    final region = regions[index];
                    return ListTile(
                      leading: Icon(
                        Icons.location_city,
                        color: AppTheme.primary,
                      ),
                      title: Text(region['name'] as String),
                      onTap: () {
                        addressCtrl.text = region['name'] as String;
                        location.value = (region['name'] as String)
                            .replaceAll(' viloyati', '')
                            .replaceAll(' shahri', '');
                        lat.value = region['lat'] as double;
                        lng.value = region['lng'] as double;
                        Get.back();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> submitRegistration() async {
    // Rate Limiting
    if (!InputSanitizer.canPerformAction(cooldown: Duration(seconds: 10))) {
      return;
    }

    // PRO: Validate location before submit
    if (location.value.trim().isEmpty) {
      _error("Iltimos, avval 📍 tugmasini bosib joylashuvni aniqlang");
      return;
    }

    isSubmitting.value = true;
    try {
      final safeName = InputSanitizer.sanitizeText(nameCtrl.text);
      final safePhone = InputSanitizer.sanitizePhone(phoneCtrl.text);
      final safeAddress = InputSanitizer.sanitizeText(addressCtrl.text);
      final safeAbout = InputSanitizer.sanitizeText(aboutCtrl.text);
      final uid = Get.find<UserService>().currentUid;

      // Anti-Spam: Check if user already registered as barber
      final existing = await _firestore
          .collection('barbers')
          .where('uid', isEqualTo: uid)
          .get();
      if (existing.docs.isNotEmpty) {
        // PRO: Auto-fix role desync instead of just showing error
        final userService = Get.find<UserService>();
        userService.setUserRole('barber');
        if (!userService.isBarberMode.value) {
          userService.toggleBarberMode();
        }
        // Also sync to Firestore users collection
        try {
          await _firestore.collection('users').doc(uid).set({
            'role': 'barber',
          }, SetOptions(merge: true));
        } catch (_) {}
        Get.snackbar(
          "Diqqat!",
          "Siz allaqachon usta sifatida ro'yxatdan o'tgansiz. Usta rejimiga o'tildi.",
          backgroundColor: AppTheme.primary,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        await Future.delayed(Duration(milliseconds: 800));
        Get.offAllNamed('/home');
        isSubmitting.value = false;
        return;
      }

      String imageUrl = '';
      if (selectedImagePath.value.isNotEmpty) {
        try {
          final file = File(selectedImagePath.value);
          final ext = selectedImagePath.value.split('.').last;
          final ref = FirebaseStorage.instance.ref().child(
            'barber_images/${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext',
          );
          await ref.putFile(file);
          imageUrl = await ref.getDownloadURL();
        } catch (e) {
          debugPrint('Image upload error: $e');
        }
      }

      await _firestore.collection('barbers').add({
        'uid': uid, // Link barber to user's UID for security
        'name': safeName,
        'phone': safePhone,
        'address': safeAddress,
        'gender': gender.value,
        'location': location.value,
        'lat': lat.value,
        'lng': lng.value,
        'image': imageUrl,
        'rating': 5.0,
        'reviewCount': 0,
        'experience': int.tryParse(expCtrl.text.trim()) ?? 1,
        'about': safeAbout.isNotEmpty ? safeAbout : 'Professional sartarosh',
        'workingHours': {'open': openTime.value, 'close': closeTime.value},
        'services': activeServices,
        'tags': ['Yangi'],
        'isActive': true,
        'queueLimit': 10, // default
        'targetGender': Get.find<UserService>().targetGender.value,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // PRO: Sync role to BOTH local storage AND Firestore users collection
      final userService = Get.find<UserService>();
      userService.setUserRole('barber');
      if (!userService.isBarberMode.value) {
        userService.toggleBarberMode();
      }
      // Persist role to Firestore so it survives re-login
      try {
        await _firestore.collection('users').doc(uid).set({
          'role': 'barber',
          'name': safeName,
          'phone': safePhone,
        }, SetOptions(merge: true));
      } catch (_) {}

      Get.snackbar(
        "Muvaffaqiyatli! 🎉",
        "Siz usta sifatida ro'yxatdan o'tdingiz",
        backgroundColor: AppTheme.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );

      await Future.delayed(Duration(milliseconds: 800));
      Get.offAllNamed('/home');
    } catch (e) {
      _error(
        "Ro'yxatdan o'tishda xatolik yuz berdi. Iltimos qaytadan urinib ko'ring.",
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    expCtrl.dispose();
    aboutCtrl.dispose();
    for (var s in servicesList) {
      final ctrl = s['priceCtrl'] as TextEditingController;
      ctrl.dispose();
    }
    super.onClose();
  }
}
