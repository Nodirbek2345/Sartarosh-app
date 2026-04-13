import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';

class WelcomeView extends GetView<AuthController> {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.accent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Spacer(flex: 2),
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                SizedBox(height: 30),
                Text(
                  "Xush kelibsiz!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                SizedBox(height: 10),
                Text(
                  "Kim uchun xizmat kerak?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 17,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 500.ms),
                Spacer(flex: 1),

                // ─── GENDER SELECTION ───
                Row(
                  children: [
                    Expanded(
                      child: _genderCard(
                        icon: Icons.male_rounded,
                        label: "Erkaklar va\nBolalar uchun",
                        gender: 'male',
                        color: Color(0xFF4A90D9),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _genderCard(
                        icon: Icons.female_rounded,
                        label: "Ayollar va\nQizlar uchun",
                        gender: 'female',
                        color: Color(0xFFE8729A),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderCard({
    required IconData icon,
    required String label,
    required String gender,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Get.find<UserService>().setTargetGender(gender);
        controller.goToHome();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppTheme.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
