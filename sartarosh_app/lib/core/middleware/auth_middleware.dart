import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/user_service.dart';
import '../../app/routes/app_routes.dart';

/// Middleware to protect routes that require authentication
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final userService = Get.find<UserService>();

    // Allow public routes
    final publicRoutes = [
      Routes.splash,
      Routes.onboarding,
      Routes.phoneLogin,
      Routes.otp,
      Routes.welcome,
    ];

    if (publicRoutes.contains(route)) {
      return null;
    }

    // Require authentication for all other routes
    if (!userService.isAuthenticated) {
      Get.snackbar(
        "Avtorizatsiya",
        "Iltimos, ushbu sahifaga kirish uchun avval tizimga kiring",
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      );

      return const RouteSettings(name: Routes.phoneLogin);
    }

    // Security passed
    return null;
  }
}
