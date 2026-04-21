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

    // Go straight to Home (Region can be selected manually from Home)
    Get.offAllNamed(Routes.home);
  }
}
