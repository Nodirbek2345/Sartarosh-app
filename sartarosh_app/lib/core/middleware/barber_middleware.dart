import 'package:sartarosh_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/user_service.dart';
import '../../app/routes/app_routes.dart';

/// Middleware to protect routes that require barber role specifically
class BarberMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final userService = Get.find<UserService>();

    // 1. Must be authenticated
    if (!userService.isAuthenticated) {
      Get.snackbar(
        "Avtorizatsiya",
        "Iltimos, tizimga kiring.",
        backgroundColor: AppTheme.danger.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
      );
      return const RouteSettings(name: Routes.phoneLogin);
    }

    // 2. Must be a registered barber AND active in barber mode
    if (userService.userRole.value != 'barber' ||
        !userService.isBarberMode.value) {
      Get.snackbar(
        "Ruxsat yo'q",
        "Siz usta rejimida emassiz yoki hali ro'yxatdan o'tmagansiz. Usta bo'limiga kirish uchu avval rejimni o'zgartiring yoki ro'yxatdan o'ting.",
        backgroundColor: AppTheme.danger.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
      );
      return const RouteSettings(name: Routes.home); // Redirect to Home
    }

    // Security passed, allow access to dashboard
    return null;
  }
}

