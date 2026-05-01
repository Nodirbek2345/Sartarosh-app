import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';

class RegionController extends GetxController {
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

  /// GPS orqali joylashuvni aniqlash va avtomatik yo'naltirish
  Future<void> detectAndGo() async {
    isDetecting.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showGpsFailureModal("Joylashuv ruxsati berilmadi");
          isDetecting.value = false;
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showGpsFailureModal(
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

        if (regionKey.isEmpty) {
          _showGpsFailureModal("Sizning hududingiz bazada topilmadi.");
          isDetecting.value = false;
          return;
        }

        // Save region and navigate to home
        final userService = Get.find<UserService>();
        userService.setGpsMode(position.latitude, position.longitude);
        userService.setRegion(regionKey);

        Get.offAllNamed('/home');
      } else {
        _showGpsFailureModal("Joylashuvni aniqlab bo'lmadi");
      }
    } catch (e) {
      debugPrint("GPS error: $e");
      _showGpsFailureModal("GPS orqali joylashuvni aniqlashda xatolik.");
    } finally {
      isDetecting.value = false;
    }
  }

  String _matchRegion(Placemark placemark) {
    final admin = (placemark.administrativeArea ?? '').toLowerCase();
    final locality = (placemark.locality ?? '').toLowerCase();
    final sub = (placemark.subAdministrativeArea ?? '').toLowerCase();
    final combined = '$admin $locality $sub';

    if (combined.contains('surxon') ||
        combined.contains('surkhan') ||
        combined.contains('surkhon') ||
        combined.contains('сурхан') ||
        combined.contains('termiz') ||
        combined.contains('termez')) {
      return 'Surxondaryo';
    } else if (combined.contains('qashqa') ||
        combined.contains('kashka') ||
        combined.contains('qashqadaryo') ||
        combined.contains('кашкадарья')) {
      return 'Qashqadaryo';
    } else if (combined.contains('andijon') ||
        combined.contains('andijan') ||
        combined.contains('андижан')) {
      return 'Andijon';
    } else if (combined.contains('farg') ||
        combined.contains('fergana') ||
        combined.contains('фергана')) {
      return "Farg'ona";
    } else if (combined.contains('namangan') || combined.contains('наманган')) {
      return 'Namangan';
    } else if (combined.contains('samarqand') ||
        combined.contains('samarkand') ||
        combined.contains('самарканд')) {
      return 'Samarqand';
    } else if (combined.contains('buxoro') ||
        combined.contains('bukhara') ||
        combined.contains('бухара')) {
      return 'Buxoro';
    } else if (combined.contains('xorazm') ||
        combined.contains('khorezm') ||
        combined.contains('хорезм')) {
      return 'Xorazm';
    } else if (combined.contains('sirdaryo') ||
        combined.contains('syrdarya') ||
        combined.contains('сырдарья')) {
      return 'Sirdaryo';
    } else if (combined.contains('jizzax') ||
        combined.contains('jizzakh') ||
        combined.contains('джизак')) {
      return 'Jizzax';
    } else if (combined.contains('navoiy') ||
        combined.contains('navoi') ||
        combined.contains('навои')) {
      return 'Navoiy';
    } else if (combined.contains('qoraqalpog') ||
        combined.contains('karakalpak') ||
        combined.contains('каракалпак')) {
      return "Qoraqalpog'iston";
    } else if (combined.contains('tashkent') ||
        combined.contains('toshkent') ||
        combined.contains('ташкент')) {
      if (combined.contains('viloyat') ||
          combined.contains('region') ||
          combined.contains('oblast')) {
        return 'Toshkent viloyati';
      }
      return 'Toshkent';
    }

    return '';
  }

  void _showGpsFailureModal(String desc) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off_rounded,
                size: 48,
                color: AppTheme.danger,
              ),
              SizedBox(height: 16),
              Text(
                "Joylashuv aniqlanmadi",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    detectAndGo(); // Retry
                  },
                  child: Text(
                    "Qayta urinib ko'rish",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    showRegionFallbackDialog();
                  },
                  child: Text(
                    "Viloyatni tanlash",
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

  void showRegionFallbackDialog() {
    Get.bottomSheet(
      Container(
        height: 480,
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Text(
                "Viloyatni tanlang",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Divider(color: Colors.grey.withValues(alpha: 0.2)),
              Expanded(
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: regions.length,
                  itemBuilder: (context, index) {
                    final region = regions[index];
                    return ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_city_rounded,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(region['name'] ?? ''),
                      onTap: () {
                        // Close BottomSheet
                        Get.back();

                        final regionKey = region['key'] ?? '';
                        final userService = Get.find<UserService>();
                        userService.setRegionMode(regionKey);

                        Get.snackbar(
                          "📍 $regionKey",
                          "Hudud tanlandi",
                          backgroundColor: AppTheme.primary,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          duration: Duration(seconds: 3),
                        );

                        Get.offAllNamed('/home');
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
}
