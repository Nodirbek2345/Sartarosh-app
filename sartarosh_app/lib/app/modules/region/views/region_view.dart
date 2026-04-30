import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/region_controller.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';

class RegionView extends GetView<RegionController> {
  const RegionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Color(0xFFFAF8F5)),
        child: SafeArea(
          child: Column(
            children: [
              // ─── HEADER ───
              Obx(() {
                final userService = Get.find<UserService>();
                final canGoBack =
                    userService.selectedRegion.value.isNotEmpty ||
                    userService.filterMode.value == 'GPS';
                return Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      if (canGoBack)
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF1A1A1A),
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ─── GPS ICON ───
                        Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.gold.withValues(alpha: 0.15),
                                    AppTheme.primary.withValues(alpha: 0.08),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.my_location_rounded,
                                color: AppTheme.gold,
                                size: 52,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .scale(
                              begin: Offset(0.8, 0.8),
                              end: Offset(1, 1),
                              duration: 500.ms,
                            ),

                        SizedBox(height: 32),

                        // ─── TITLE ───
                        Text(
                          "Joylashuvingizni\naniqlang",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            color: Color(0xFF1A1A1A),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        SizedBox(height: 16),

                        // ─── SUBTITLE ───
                        Text(
                          "Sizga yaqin ustalarni ko'rsatish uchun\nGPS orqali joylashuvingizni aniqlang",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Color(0xFF1A1A1A).withValues(alpha: 0.5),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 300.ms),

                        SizedBox(height: 48),

                        // ─── GPS DETECT BUTTON ───
                        Obx(
                          () => GestureDetector(
                            onTap: controller.isDetecting.value
                                ? null
                                : () => controller.detectAndGo(),
                            child: AnimatedContainer(
                              duration: 300.ms,
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                gradient: controller.isDetecting.value
                                    ? LinearGradient(
                                        colors: [
                                          AppTheme.textLight,
                                          AppTheme.textMedium,
                                        ],
                                      )
                                    : AppTheme.goldGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  if (!controller.isDetecting.value)
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 24,
                                      offset: Offset(0, 10),
                                    ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (controller.isDetecting.value)
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.my_location_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  SizedBox(width: 12),
                                  Text(
                                    controller.isDetecting.value
                                        ? "Aniqlanmoqda..."
                                        : "📍 GPS orqali aniqlash",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15),

                        SizedBox(height: 16),

                        // ─── MANUAL SELECTION BUTTON ───
                        GestureDetector(
                          onTap: () => controller.showRegionFallbackDialog(),
                          child: AnimatedContainer(
                            duration: 300.ms,
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.05,
                                  ),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_city_rounded,
                                  color: AppTheme.primary,
                                  size: 22,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "Viloyatni qo'lda tanlash",
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.15),

                        SizedBox(height: 24),

                        // ─── INFO NOTE ───
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppTheme.gold,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Siz faqat o'z viloyatingizdagi ustalarga bron qilishingiz mumkin",
                                  style: GoogleFonts.poppins(
                                    color: Color(
                                      0xFF1A1A1A,
                                    ).withValues(alpha: 0.6),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
