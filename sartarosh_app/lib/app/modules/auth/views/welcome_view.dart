import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';

class WelcomeView extends GetView<AuthController> {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Step tracker: 0 = role selection, 1 = gender selection
    final currentStep = 0.obs;

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
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Obx(
              () => currentStep.value == 0
                  ? _buildRoleSelection(currentStep)
                  : _buildGenderSelection(),
            ),
          ),
        ),
      ),
    );
  }

  // ─── STEP 1: ROLE SELECTION ───
  Widget _buildRoleSelection(RxInt currentStep) {
    final userService = Get.find<UserService>();

    return Column(
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
              Icons.person_search_rounded,
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
          "Siz kimsiz?",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 17,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 500.ms),
        SizedBox(height: 6),
        Text(
          "Ilovadan qanday foydalanmoqchisiz?",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            height: 1.4,
          ),
        ).animate().fadeIn(delay: 600.ms),
        Spacer(flex: 1),

        // ─── ROLE CARDS ───
        Row(
          children: [
            Expanded(
              child: _roleCard(
                icon: Icons.person_rounded,
                emoji: "👤",
                label: "Mijoz",
                subtitle: "Sartarosh izlash\nva band qilish",
                color: Color(0xFF4A90D9),
                onTap: () {
                  userService.setUserRole('client');
                  // Save role to Firestore
                  _updateFirestoreRole('client');
                  currentStep.value = 1;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _roleCard(
                icon: Icons.content_cut_rounded,
                emoji: "✂️",
                label: "Sartarosh",
                subtitle: "O'z xizmatlarimni\ne'lon qilish",
                color: Color(0xFFC9A96E),
                onTap: () {
                  userService.setUserRole('barber');
                  // Save role to Firestore
                  _updateFirestoreRole('barber');
                  currentStep.value = 1;
                },
              ),
            ),
          ],
        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),

        Spacer(flex: 2),
      ],
    );
  }

  // ─── STEP 2: GENDER SELECTION ───
  Widget _buildGenderSelection() {
    return Column(
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
            child: Icon(Icons.check_rounded, size: 56, color: Colors.white),
          ),
        ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
        SizedBox(height: 30),
        Text(
          "Ajoyib! ✨",
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
    );
  }

  // ─── ROLE CARD WIDGET ───
  Widget _roleCard({
    required IconData icon,
    required String emoji,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppTheme.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppTheme.textMedium,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── GENDER CARD WIDGET ───
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
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 12),
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
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppTheme.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── UPDATE FIRESTORE ROLE ───
  void _updateFirestoreRole(String role) {
    final userService = Get.find<UserService>();
    final uid = userService.currentUid;
    if (uid.isNotEmpty) {
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': role,
      }, SetOptions(merge: true));
    }
  }
}
