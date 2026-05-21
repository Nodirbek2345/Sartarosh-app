import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/update_service.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ┌─────────────────────────────────────────────
          // │  GLASSMORPHISM PROFILE HERO HEADER
          // └─────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.glassHeroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 28),
                child: Column(
                  children: [
                    // Top bar
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: EdgeInsets.all(9),
                            decoration: AppTheme.glassCard(radius: 13),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "Profil",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 42),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Glass profile card — like the reference image
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: AppTheme.glassCard(radius: 24),
                      child: Column(
                        children: [
                          // Avatar + name row
                          Row(
                            children: [
                              // Avatar with glass ring (tap to change)
                              GestureDetector(
                                onTap: () async {
                                  final picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 400,
                                    maxHeight: 400,
                                    imageQuality: 80,
                                  );
                                  if (image != null) {
                                    final bytes = await image.readAsBytes();
                                    Get.find<UserService>().updateAvatar(
                                      base64Encode(bytes),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 16,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Obx(() {
                                    final av = Get.find<UserService>()
                                        .avatarBase64
                                        .value;
                                    return CircleAvatar(
                                      radius: 36,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      backgroundImage: av.isNotEmpty
                                          ? MemoryImage(base64Decode(av))
                                                as ImageProvider
                                          : const AssetImage(
                                              'assets/images/default_avatar.png',
                                            ),
                                      child: av.isEmpty
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.camera_alt_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                Text(
                                                  "Rasm",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : null,
                                    );
                                  }),
                                ).animate().scale(duration: 500.ms),
                              ),
                              SizedBox(width: 16),
                              // Name, phone, role badges
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Obx(
                                      () => Text(
                                        Get.find<UserService>().name.value,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: 100.ms),
                                    SizedBox(height: 2),
                                    Obx(
                                      () => Text(
                                        Get.find<UserService>().phone.value,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: 200.ms),
                                    SizedBox(height: 10),
                                    // Role badge pills — inspired by reference image
                                    Obx(() {
                                      final us = Get.find<UserService>();
                                      final isBarber =
                                          us.userRole.value == 'barber';
                                      return Wrap(
                                        spacing: 8,
                                        children: [
                                          _glassBadge(
                                            isBarber ? "Sartarosh ✂️" : "Mijoz",
                                          ),
                                          if (isBarber) _glassBadge("Pro ⭐"),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.06),
                  ],
                ),
              ),
            ),
          ),

          // Bonus Card
          _buildBonusCard(),

          // Menu items
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Obx(() {
                    int idx = 0;
                    return Column(
                      children: [
                        _menuItem(
                          Icons.favorite_rounded,
                          "Sevimlilar",
                          idx++,
                          () => Get.toNamed('/favorites'),
                        ),
                        _menuItem(
                          Icons.settings_rounded,
                          "Sozlamalar",
                          idx++,
                          () => _showSettings(),
                        ),
                        // (Removed "Sartarosh sifatida qo'shilish" option completely to separate Barber and Client)
                        _menuItem(
                          Icons.help_outline_rounded,
                          "Yordam",
                          idx++,
                          () => _showHelp(),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Glass badge pill, like in reference image
  Widget _glassBadge(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── SOZLAMALAR ───
  void _showSettings() {
    final userService = Get.find<UserService>();
    final nameCtrl = TextEditingController(text: userService.name.value);
    final phoneCtrl = TextEditingController(text: userService.phone.value);
    final barberPhoneCtrl = TextEditingController();
    final isBarber = userService.isBarberMode.value;

    // If barber mode, load the barber's business phone from Firestore
    if (isBarber) {
      FirebaseFirestore.instance
          .collection('barbers')
          .where('uid', isEqualTo: userService.currentUid)
          .limit(1)
          .get()
          .then((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final data = snapshot.docs.first.data();
              barberPhoneCtrl.text = data['phone'] ?? '';
            }
          });
    }

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Sozlamalar",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                // Name field
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Ismingiz",
                    labelStyle: TextStyle(color: AppTheme.textMedium),
                    prefixIcon: Icon(
                      Icons.person_rounded,
                      color: AppTheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.textLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Personal Phone field
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: isBarber
                        ? "Shaxsiy raqamingiz"
                        : "Telefon raqam",
                    labelStyle: TextStyle(color: AppTheme.textMedium),
                    prefixIcon: Icon(
                      Icons.phone_rounded,
                      color: AppTheme.primary,
                    ),
                    helperText: isBarber
                        ? "Bu raqam faqat sizning akkauntingiz uchun"
                        : null,
                    helperStyle: TextStyle(
                      color: AppTheme.textMedium,
                      fontSize: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.textLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                ),
                // Barber business phone — only visible in barber mode
                if (isBarber) ...[
                  SizedBox(height: 16),
                  TextField(
                    controller: barberPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Usta telefon raqami (mijozlar ko'radi)",
                      labelStyle: TextStyle(color: AppTheme.textMedium),
                      prefixIcon: Icon(
                        Icons.phone_in_talk_rounded,
                        color: AppTheme.gold,
                      ),
                      helperText:
                          "Bu raqamni mijozlar ko'radi va qo'ng'iroq qiladi",
                      helperStyle: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppTheme.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppTheme.gold, width: 2),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 24),
                // Save
                GestureDetector(
                  onTap: () async {
                    // Save personal info — always
                    userService.updateUser(
                      nameCtrl.text.trim(),
                      phoneCtrl.text.trim(),
                    );

                    // If barber, also update barber phone in Firestore
                    if (isBarber && barberPhoneCtrl.text.trim().isNotEmpty) {
                      try {
                        final snap = await FirebaseFirestore.instance
                            .collection('barbers')
                            .where('uid', isEqualTo: userService.currentUid)
                            .limit(1)
                            .get();
                        if (snap.docs.isNotEmpty) {
                          await snap.docs.first.reference.update({
                            'phone': barberPhoneCtrl.text.trim(),
                          });
                        }
                      } catch (_) {}
                    }

                    Get.back();
                    Get.snackbar(
                      "Saqlandi ✅",
                      "Ma'lumotlaringiz yangilandi",
                      backgroundColor: AppTheme.primary,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                      margin: EdgeInsets.all(16),
                      borderRadius: 14,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        "Saqlash",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Logout
                GestureDetector(
                  onTap: () {
                    Get.dialog(
                      AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text("Chiqish"),
                        content: Text("Rostdan ham tizimdan chiqmoqchimisiz?"),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text("Yo'q"),
                          ),
                          TextButton(
                            onPressed: () {
                              userService.logout();
                              Get.back(); // close dialog
                              Get.back(); // close bottom sheet
                              Get.offAllNamed('/onboarding');
                            },
                            child: Text(
                              "Ha, chiqish",
                              style: TextStyle(color: AppTheme.danger),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        "Tizimdan chiqish",
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ─── YORDAM ───
  void _showHelp() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Yordam",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _helpItem(
                Icons.smart_toy_rounded,
                "AI Yordam (Murojaat)",
                "Suni'y intellekt orqali muammoni hal qilish",
                () {
                  Get.back(); // close bottom sheet
                  Get.toNamed('/support-chat');
                },
              ),
              _helpItem(
                Icons.info_outline_rounded,
                "Ilova versiyasi",
                "${Get.find<UpdateService>().currentVersion} (Tekshirish)",
                () {
                  Get.back();
                  Get.find<UpdateService>().checkUpdate();
                },
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.textLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Sartarosh v${Get.find<UpdateService>().currentVersion}",
                    style: TextStyle(
                      color: AppTheme.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _helpItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppTheme.textMedium, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textLight,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, int index, VoidCallback onTap) {
    return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    blurRadius: 16,
                    spreadRadius: -4,
                    offset: Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 300 + (index * 80)))
        .slideX(begin: 0.04);
  }

  // ─── BONUS CARD ───
  Widget _buildBonusCard() {
    final userService = Get.find<UserService>();
    return Obx(() {
      final uid = userService.currentUid;
      final name = userService.name.value;

      final query = uid.isNotEmpty
          ? FirebaseFirestore.instance
                .collection('bookings')
                .where('clientUid', isEqualTo: uid)
                .where('status', isEqualTo: 'completed')
          : FirebaseFirestore.instance
                .collection('bookings')
                .where('client', isEqualTo: name)
                .where('status', isEqualTo: 'completed');

      return StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          int visits = 0;
          if (snapshot.hasData) {
            visits = snapshot.data!.docs.length;
          }

          int points = visits * 20; // Example: 20 ball per visit
          int currentCycle = visits % 6; // 6-marta BEPUL (0..5)
          int visitsLeft = 5 - currentCycle;
          if (visitsLeft <= 0) visitsLeft = 0; // If 5, next is free

          String visitsLeftText = visitsLeft == 0
              ? "Sizning navbatdagi tashrifingiz BEPUL!"
              : "Yana $visitsLeft ta tashrif qoldi";

          return Container(
            margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.07),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.gold.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: AppTheme.gold,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sizning bonusingiz",
                              style: GoogleFonts.poppins(
                                color: AppTheme.textMedium,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "$points ball",
                              style: GoogleFonts.poppins(
                                color: AppTheme.textDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Premium",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  "5 marta keling → 6-marta BEPUL!",
                  style: GoogleFonts.poppins(
                    color: AppTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: List.generate(6, (index) {
                    final isCompleted = index < currentCycle;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index == 5 ? 0 : 6),
                        height: 6,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppTheme.gold
                              : AppTheme.textMedium.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 8),
                Text(
                  visitsLeftText,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textMedium,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05);
        },
      );
    });
  }
}
