import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';

class RegionController extends GetxController {
  final searchQuery = ''.obs;
  final selectedRegion = ''.obs;
  final isDetecting = false.obs;

  final regions = <Map<String, String>>[
    {'name': 'Toshkent shahri', 'key': 'Toshkent'},
    {'name': 'Andijon viloyati', 'key': 'Andijon'},
    {'name': 'Farg\'ona viloyati', 'key': 'Farg\'ona'},
    {'name': 'Namangan viloyati', 'key': 'Namangan'},
    {'name': 'Samarqand viloyati', 'key': 'Samarqand'},
    {'name': 'Buxoro viloyati', 'key': 'Buxoro'},
    {'name': 'Xorazm viloyati', 'key': 'Xorazm'},
    {'name': 'Qashqadaryo viloyati', 'key': 'Qashqadaryo'},
    {'name': 'Surxondaryo viloyati', 'key': 'Surxondaryo'},
    {'name': 'Sirdaryo viloyati', 'key': 'Sirdaryo'},
    {'name': 'Jizzax viloyati', 'key': 'Jizzax'},
    {'name': 'Navoiy viloyati', 'key': 'Navoiy'},
    {'name': 'Toshkent viloyati', 'key': 'Toshkent viloyati'},
    {'name': 'Qoraqalpog\'iston Respublikasi', 'key': 'Qoraqalpog\'iston'},
  ];

  List<Map<String, String>> get filteredRegions {
    if (searchQuery.value.isEmpty) return regions;
    return regions
        .where(
          (r) => r['name']!.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    selectedRegion.value = Get.find<UserService>().selectedRegion.value;
  }

  void selectRegion(String regionKey) {
    selectedRegion.value = regionKey;
  }

  void confirmAndGo() {
    if (selectedRegion.value.isEmpty) {
      Get.snackbar(
        "Diqqat",
        "Iltimos, viloyatingizni tanlang",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    _saveAndNavigate(selectedRegion.value);
  }

  Future<void> detectLocation() async {
    isDetecting.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError("Joylashuv ruxsati berilmadi");
          isDetecting.value = false;
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showError(
          "Joylashuv ruxsati butunlay rad etilgan. Sozlamalardan yoqing.",
        );
        isDetecting.value = false;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final regionKey = _matchRegion(place);

        // Ularni oynada tanlab qo'yamiz (lekin o'zgartirmaymiz/ketmaymiz)
        selectRegion(regionKey);

        // Aniq nima topilganini ko'rsatamiz
        final street = place.street ?? '';
        final subLocality = place.subLocality ?? '';
        final locality = place.locality ?? '';
        final adminArea = place.administrativeArea ?? '';

        // Form a nice string
        final parts = [
          street,
          subLocality,
          locality,
          adminArea,
        ].where((e) => e.isNotEmpty).toList();
        final exactPlace = parts.join(', ');

        Get.snackbar(
          "📍 Joylashuv aniqlandi",
          exactPlace.isNotEmpty ? exactPlace : "$regionKey tanlandi",
          backgroundColor: AppTheme.gold,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 4),
        );
      } else {
        _showError("Joylashuvni aniqlab bo'lmadi");
      }
    } catch (e) {
      _showError("GPS xatolik: $e");
    } finally {
      isDetecting.value = false;
    }
  }

  String _matchRegion(Placemark placemark) {
    final admin = (placemark.administrativeArea ?? '').toLowerCase();
    final locality = (placemark.locality ?? '').toLowerCase();
    final sub = (placemark.subAdministrativeArea ?? '').toLowerCase();
    final combined = '$admin $locality $sub';

    if (combined.contains('toshkent') || combined.contains('tashkent')) {
      return 'Toshkent';
    } else if (combined.contains('andijon') || combined.contains('andijan')) {
      return 'Andijon';
    } else if (combined.contains('farg') || combined.contains('fergana')) {
      return "Farg'ona";
    } else if (combined.contains('namangan')) {
      return 'Namangan';
    } else if (combined.contains('samarqand') ||
        combined.contains('samarkand')) {
      return 'Samarqand';
    } else if (combined.contains('buxoro') || combined.contains('bukhara')) {
      return 'Buxoro';
    } else if (combined.contains('xorazm') || combined.contains('khorezm')) {
      return 'Xorazm';
    } else if (combined.contains('qashqa') || combined.contains('kashka')) {
      return 'Qashqadaryo';
    } else if (combined.contains('surxon') || combined.contains('surkhan')) {
      return 'Surxondaryo';
    } else if (combined.contains('sirdaryo') || combined.contains('syrdarya')) {
      return 'Sirdaryo';
    } else if (combined.contains('jizzax') || combined.contains('jizzakh')) {
      return 'Jizzax';
    } else if (combined.contains('navoiy') || combined.contains('navoi')) {
      return 'Navoiy';
    } else if (combined.contains('qoraqalpog') ||
        combined.contains('karakalpak')) {
      return "Qoraqalpog'iston";
    }
    return 'Toshkent';
  }

  void _saveAndNavigate(String region) {
    final userService = Get.find<UserService>();
    userService.selectedRegion.value = region;
    userService.setRegion(region);

    Get.snackbar(
      "📍 $region",
      "$region dagi ustalar ko'rsatilmoqda",
      backgroundColor: AppTheme.primary,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 2),
    );

    Get.offAllNamed('/home');
  }

  void _showError(String msg) {
    Get.snackbar(
      "Xatolik",
      msg,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
