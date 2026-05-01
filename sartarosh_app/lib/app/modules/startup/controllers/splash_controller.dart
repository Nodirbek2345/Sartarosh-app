import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../routes/app_routes.dart';
import '../../../../core/services/user_service.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _checkVersionAndNavigate();
  }

  void _checkVersionAndNavigate() async {
    // Determine minimum delay for splash screen aesthetics
    final minimumDelay = Future.delayed(Duration(seconds: 3));

    try {
      // Fetch current app version info
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      // Fetch required version from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('platform_config')
          .doc('app_version')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        int minVersion = data['min_version'] ?? 0;

        if (currentBuild < minVersion) {
          await minimumDelay;
          Get.offAllNamed(Routes.forceUpdate, arguments: data);
          return;
        }
      }
    } catch (e) {
      Get.log('Version check error: $e');
      // On error (e.g. no internet), we just bypass and let the app handle it naturally
    }

    await minimumDelay;
    _navigate();
  }

  void _navigate() {
    final userService = Get.find<UserService>();

    if (!userService.isLogged.value) {
      Get.offAllNamed(Routes.onboarding);
      return;
    }

    // Force Location Selection if empty
    if (!userService.hasLocation) {
      Get.offAllNamed(Routes.region);
      return;
    }

    // Go straight to Home
    Get.offAllNamed(Routes.home);
  }
}
