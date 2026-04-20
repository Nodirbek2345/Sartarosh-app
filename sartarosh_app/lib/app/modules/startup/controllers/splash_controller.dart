import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../../core/services/user_service.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _navigate();
  }

  void _navigate() async {
    await Future.delayed(Duration(seconds: 3));
    final userService = Get.find<UserService>();

    if (!userService.isLogged.value) {
      Get.offAllNamed(Routes.onboarding);
      return;
    }

    // Check if region is already selected
    if (userService.selectedRegion.value.isNotEmpty) {
      Get.offAllNamed(Routes.home);
    } else {
      Get.offAllNamed(Routes.region);
    }
  }
}
