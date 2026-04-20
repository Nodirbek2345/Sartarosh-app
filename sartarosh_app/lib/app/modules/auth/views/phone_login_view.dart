import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/theme/app_theme.dart';

class PhoneLoginView extends GetView<AuthController> {
  const PhoneLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Spacer(flex: 1),

                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.phone_rounded,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                        ).animate().scale(duration: 500.ms),

                        SizedBox(height: 24),

                        Text(
                          "Telefon raqamingizni\nkiriting",
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        SizedBox(height: 12),

                        Text(
                          "Keyingi qadamda Google orqali tasdiqlaysiz",
                          style: TextStyle(
                            color: AppTheme.textMedium,
                            fontSize: 15,
                          ),
                        ).animate().fadeIn(delay: 300.ms),

                        SizedBox(height: 40),

                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: TextField(
                            controller: controller.phoneCtrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\s]'),
                              ),
                            ],
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                            decoration: InputDecoration(
                              hintText: "+998 XX XXX XX XX",
                              hintStyle: TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 20,
                              ),
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(left: 16, right: 12),
                                child: Icon(
                                  Icons.phone_rounded,
                                  color: AppTheme.primary,
                                  size: 24,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 20,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms),

                        Spacer(flex: 2),

                        GestureDetector(
                          onTap: () => controller.goToGoogleStep(),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primary, AppTheme.accent],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "Davom etish",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 500.ms),

                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
