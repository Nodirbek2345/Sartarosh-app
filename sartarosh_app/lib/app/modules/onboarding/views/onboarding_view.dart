import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/onboarding_controller.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final pageCtrl = PageController();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Get.offAllNamed('/phone-login'),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "O'tkazib yuborish",
                          style: GoogleFonts.poppins(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: pageCtrl,
                  onPageChanged: (i) => controller.currentPage.value = i,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final page = controller.pages[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primary.withValues(alpha: 0.2),
                                  AppTheme.primaryDark.withValues(alpha: 0.1),
                                ],
                              ),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              IconData(
                                page['icon'] as int,
                                fontFamily: 'MaterialIcons',
                              ),
                              size: 64,
                              color: AppTheme.primary,
                            ),
                          ).animate().scale(
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),

                          SizedBox(height: 48),

                          Text(
                            page['title'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ).animate().fadeIn(delay: 200.ms),

                          SizedBox(height: 16),

                          Text(
                            page['subtitle'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Dots
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: controller.currentPage.value == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: controller.currentPage.value == i
                            ? AppTheme.primary
                            : AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // CTA Button
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Obx(
                  () => GestureDetector(
                    onTap: () {
                      if (controller.currentPage.value < 2) {
                        pageCtrl.nextPage(
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        controller.next();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          controller.pages[controller
                                  .currentPage
                                  .value]['button']
                              as String,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
