import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/theme/app_theme.dart';

/// OTP is replaced by Google Sign-In. This page shows the Google button.
class OtpView extends GetView<AuthController> {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          SizedBox(height: 16),
                          // Back button
                          Align(
                            alignment: Alignment.topLeft,
                            child: GestureDetector(
                              onTap: () => Get.back(),
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),

                          Spacer(flex: 2),

                          // Logo replacing vector graphics with user provided image
                          Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 50,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(80),
                                  child: Image.asset(
                                    'assets/images/barber_pulse.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1.05, 1.05),
                                duration: 800.ms,
                                curve: Curves.easeInOutCubic,
                              ),

                          SizedBox(height: 32),

                          Text(
                            "Tasdiqlash",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ).animate().fadeIn(delay: 300.ms),

                          SizedBox(height: 8),

                          Text(
                            "Google akkauntingiz bilan\nhisob tasdiqlang",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ).animate().fadeIn(delay: 500.ms),

                          Spacer(flex: 2),

                          // Google Sign-In Button
                          Obx(
                            () => GestureDetector(
                              onTap: controller.isLoading.value
                                  ? null
                                  : () => controller.signInWithGoogle(),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: controller.isLoading.value
                                    ? Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: Center(
                                              child: Text(
                                                "G",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700,
                                                  foreground: Paint()
                                                    ..shader =
                                                        LinearGradient(
                                                          colors: [
                                                            Color(0xFF4285F4),
                                                            Color(0xFF34A853),
                                                            Color(0xFFFBBC05),
                                                            Color(0xFFEA4335),
                                                          ],
                                                        ).createShader(
                                                          Rect.fromLTWH(
                                                            0,
                                                            0,
                                                            28,
                                                            28,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 14),
                                          Text(
                                            "Google orqali tasdiqlash",
                                            style: GoogleFonts.poppins(
                                              color: Color(0xFF333333),
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.15),

                          SizedBox(height: 16),

                          Text(
                            "Kod kerak emas — faqat\nGoogle akkauntingiz bilan tasdiqlang",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ).animate().fadeIn(delay: 900.ms),

                          Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
