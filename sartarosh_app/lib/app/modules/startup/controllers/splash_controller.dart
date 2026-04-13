import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../routes/app_routes.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';

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
      _showLocationDialog();
    }
  }

  void _showLocationDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFFAF8F5), // Light cream color as in image
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Map Illustration Header
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Color(0xFFF3EEDD).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // A subtle map background or icon stack
                    Icon(
                      Icons.map_rounded,
                      size: 80,
                      color: AppTheme.gold.withValues(alpha: 0.3),
                    ),
                    Positioned(
                      top: 15,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF6B48FF), // Purple accent
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF6B48FF).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  children: [
                    Text(
                      "Joylashuv",
                      style: GoogleFonts.playfairDisplay(
                        color: Color(0xFF1A1A1A),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Joylashuvingizni aniqlaymizmi?\n\nHozirda eng yaqin sartaroshlarni ko'rish uchun",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 32),

                    // Purple GPS Button
                    GestureDetector(
                      onTap: () {
                        Get.back();
                        Get.offAllNamed(Routes.region);
                        Future.delayed(Duration(milliseconds: 500), () {
                          // Let RegionController handle GPS detection
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF8A5DFF), Color(0xFF5E38E6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF6B48FF).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Ruxsat berish",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Gold Manual Button
                    GestureDetector(
                      onTap: () {
                        Get.back();
                        Get.offAllNamed(Routes.region);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE5C170), Color(0xFFD4AF37)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFD4AF37).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Qo'lda tanlash",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
