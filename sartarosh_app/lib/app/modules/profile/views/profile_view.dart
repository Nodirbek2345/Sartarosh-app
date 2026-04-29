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
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              gradient: AppTheme.darkGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Get.back(),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "Profil",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                  SizedBox(height: 16),
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
                        final base64String = base64Encode(bytes);
                        Get.find<UserService>().updateAvatar(base64String);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Obx(() {
                        final avatarBase64 =
                            Get.find<UserService>().avatarBase64.value;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.transparent,
                              backgroundImage: avatarBase64.isNotEmpty
                                  ? MemoryImage(base64Decode(avatarBase64))
                                        as ImageProvider
                                  : const AssetImage(
                                      'assets/images/default_avatar.png',
                                    ),
                            ),
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.3),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Rasm",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                    ).animate().scale(duration: 500.ms),
                  ),
                  SizedBox(height: 14),
                  Obx(
                    () => Text(
                      Get.find<UserService>().name.value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  SizedBox(height: 4),
                  Obx(
                    () => Text(
                      Get.find<UserService>().phone.value,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ],
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
                    final userService = Get.find<UserService>();
                    final isBarber = userService.isBarberMode.value;
                    final isBarberRole = userService.userRole.value == 'barber';

                    if (isBarber) {
                      // ─── SARTAROSH (Barber) REJIMI MENYULARI ───
                      return Column(
                        children: [
                          _menuItem(
                            Icons.design_services_rounded,
                            "Xizmatlar va narxlarni tahrirlash",
                            0,
                            () => _showManageServices(),
                          ),
                          _menuItem(
                            Icons.swap_horiz_rounded,
                            "Mijoz rejimiga o'tish",
                            1,
                            () {
                              userService.toggleBarberMode();
                              Get.offAllNamed('/home');
                            },
                          ),
                          _menuItem(
                            Icons.settings_rounded,
                            "Sozlamalar",
                            2,
                            () => _showSettings(),
                          ),
                          _menuItem(
                            Icons.rate_review_rounded,
                            "Talab va takliflar",
                            3,
                            () => _showFeedbackBottomSheet(),
                          ),
                          _menuItem(
                            Icons.help_outline_rounded,
                            "Yordam",
                            4,
                            () => _showHelp(),
                          ),
                        ],
                      );
                    } else {
                      // ─── MIJOZ (Client) REJIMI MENYULARI ───
                      int idx = 0;
                      return Column(
                        children: [
                          _menuItem(
                            Icons.calendar_month_rounded,
                            "Mening bronlarim",
                            idx++,
                            () => Get.toNamed('/my-bookings'),
                          ),
                          _menuItem(
                            Icons.storefront_rounded,
                            "Sartarosh sifatida qo'shilish",
                            idx++,
                            () async {
                              if (isBarberRole) {
                                // Heal desync: Check if they actually still have a barber doc
                                final uid = userService.currentUid;
                                final docs = await FirebaseFirestore.instance
                                    .collection('barbers')
                                    .where('uid', isEqualTo: uid)
                                    .get();
                                if (docs.docs.isEmpty) {
                                  // Auto-heal role to 'client'
                                  userService.userRole.value = 'client';
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .set({
                                        'role': 'client',
                                      }, SetOptions(merge: true));
                                  Get.toNamed('/add-barber');
                                } else {
                                  Get.snackbar(
                                    "Diqqat!",
                                    "Siz allaqachon usta sifatida ro'yxatdan o'tgansiz.",
                                    backgroundColor: Colors.orange,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.TOP,
                                  );
                                }
                              } else {
                                Get.toNamed('/add-barber');
                              }
                            },
                          ),
                          if (isBarberRole) ...[
                            _menuItem(
                              Icons.swap_horiz_rounded,
                              "Usta rejimiga o'tish",
                              idx++,
                              () async {
                                // Validate if doc still exists
                                final uid = userService.currentUid;
                                final docs = await FirebaseFirestore.instance
                                    .collection('barbers')
                                    .where('uid', isEqualTo: uid)
                                    .get();
                                if (docs.docs.isEmpty) {
                                  Get.snackbar(
                                    "Kechirasiz",
                                    "Sizning usta profilingiz tizimda mavjud emas yoki o'chirilgan.",
                                    backgroundColor: AppTheme.danger,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.TOP,
                                  );
                                  // Auto-heal role to 'client'
                                  userService.userRole.value = 'client';
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .set({
                                        'role': 'client',
                                      }, SetOptions(merge: true));
                                } else {
                                  userService.toggleBarberMode();
                                  Get.offAllNamed('/home');
                                }
                              },
                            ),
                          ],
                          _menuItem(
                            Icons.settings_rounded,
                            "Sozlamalar",
                            idx++,
                            () => _showSettings(),
                          ),
                          _menuItem(
                            Icons.rate_review_rounded,
                            "Talab va takliflar",
                            idx++,
                            () => _showFeedbackBottomSheet(),
                          ),
                          _menuItem(
                            Icons.help_outline_rounded,
                            "Yordam",
                            idx++,
                            () => _showHelp(),
                          ),
                        ],
                      );
                    }
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── XIZMATLAR VA NARXLARNI TAHRIRLASH (BARBER MODE) ───
  void _showManageServices() {
    final userService = Get.find<UserService>();

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.design_services_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Xizmatlar va narxlar",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('services').get(),
                builder: (context, servicesSnapshot) {
                  if (servicesSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  final globalServices = servicesSnapshot.data?.docs ?? [];

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('barbers')
                        .where('uid', isEqualTo: userService.currentUid)
                        .snapshots(),
                    builder: (context, barberSnapshot) {
                      if (barberSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }

                      final barberDocs = barberSnapshot.data?.docs ?? [];
                      if (barberDocs.isEmpty) {
                        return const Center(
                          child: Text("Sartarosh profili topilmadi"),
                        );
                      }

                      final barberDoc = barberDocs.first;
                      final barberData =
                          barberDoc.data() as Map<String, dynamic>;
                      final currentServices =
                          (barberData['services'] as List?)
                              ?.cast<Map<String, dynamic>>() ??
                          [];

                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 800,
                                maxHeight: 800,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                final base64String = base64Encode(bytes);
                                await barberDoc.reference.update({
                                  'image': base64String,
                                });
                                Get.snackbar(
                                  'Muvaffaqiyatli',
                                  'Muqova rasmi yangilandi',
                                  backgroundColor: AppTheme.success,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo_camera_back_rounded,
                                    color: AppTheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Muqova rasmini almashtirish",
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: globalServices.length,
                              itemBuilder: (context, index) {
                                final gSvc =
                                    globalServices[index].data()
                                        as Map<String, dynamic>;
                                final gName = gSvc['name'] ?? '';
                                final gCat = gSvc['category'] ?? '';

                                // Find if barber already has this service
                                final existing = currentServices.firstWhere(
                                  (s) => s['name'] == gName,
                                  orElse: () =>
                                      <
                                        String,
                                        dynamic
                                      >{}, // Changed this line to ensure proper typing
                                );

                                final bool isEnabled = existing.isNotEmpty;
                                final priceCtrl = TextEditingController(
                                  text: isEnabled
                                      ? existing['price']?.toString()
                                      : '',
                                );
                                final durationCtrl = TextEditingController(
                                  text: isEnabled
                                      ? existing['duration']?.toString()
                                      : '',
                                );

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isEnabled
                                        ? AppTheme.primary.withValues(
                                            alpha: 0.05,
                                          )
                                        : AppTheme.background,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isEnabled
                                          ? AppTheme.primary.withValues(
                                              alpha: 0.3,
                                            )
                                          : AppTheme.textLight.withValues(
                                              alpha: 0.2,
                                            ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                gName,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.textDark,
                                                ),
                                              ),
                                              Text(
                                                gCat,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Switch(
                                            value: isEnabled,
                                            activeThumbColor: AppTheme.primary,
                                            onChanged: (val) async {
                                              final newServices =
                                                  List<
                                                    Map<String, dynamic>
                                                  >.from(currentServices);
                                              if (val) {
                                                newServices.add({
                                                  'name': gName,
                                                  'price': 0,
                                                  'duration': 30,
                                                  'category': gCat,
                                                });
                                              } else {
                                                newServices.removeWhere(
                                                  (s) => s['name'] == gName,
                                                );
                                              }
                                              await barberDoc.reference.update({
                                                'services': newServices,
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      if (isEnabled) ...[
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: priceCtrl,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: "Narxi (so'm)",
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                onSubmitted: (val) async {
                                                  final price =
                                                      int.tryParse(val) ?? 0;
                                                  final newServices =
                                                      List<
                                                        Map<String, dynamic>
                                                      >.from(currentServices);
                                                  final idx = newServices
                                                      .indexWhere(
                                                        (s) =>
                                                            s['name'] == gName,
                                                      );
                                                  if (idx != -1) {
                                                    newServices[idx]['price'] =
                                                        price;
                                                    await barberDoc.reference
                                                        .update({
                                                          'services':
                                                              newServices,
                                                        });
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextField(
                                                controller: durationCtrl,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: "Vaqt (daqiqa)",
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                onSubmitted: (val) async {
                                                  final duration =
                                                      int.tryParse(val) ?? 30;
                                                  final newServices =
                                                      List<
                                                        Map<String, dynamic>
                                                      >.from(currentServices);
                                                  final idx = newServices
                                                      .indexWhere(
                                                        (s) =>
                                                            s['name'] == gName,
                                                      );
                                                  if (idx != -1) {
                                                    newServices[idx]['duration'] =
                                                        duration;
                                                    await barberDoc.reference
                                                        .update({
                                                          'services':
                                                              newServices,
                                                        });
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () async {
                                              final price =
                                                  int.tryParse(
                                                    priceCtrl.text,
                                                  ) ??
                                                  0;
                                              final duration =
                                                  int.tryParse(
                                                    durationCtrl.text,
                                                  ) ??
                                                  30;
                                              final newServices =
                                                  List<
                                                    Map<String, dynamic>
                                                  >.from(currentServices);
                                              final idx = newServices
                                                  .indexWhere(
                                                    (s) => s['name'] == gName,
                                                  );
                                              if (idx != -1) {
                                                newServices[idx]['price'] =
                                                    price;
                                                newServices[idx]['duration'] =
                                                    duration;
                                                await barberDoc.reference
                                                    .update({
                                                      'services': newServices,
                                                    });
                                                Get.snackbar(
                                                  "Saqlandi",
                                                  "$gName narxi yangilandi",
                                                  snackPosition:
                                                      SnackPosition.BOTTOM,
                                                  backgroundColor:
                                                      AppTheme.success,
                                                  colorText: Colors.white,
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.check_circle_rounded,
                                              size: 18,
                                            ),
                                            label: const Text("Saqlash"),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
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
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Sartarosh ilovasini tanlaganingiz uchun rahmat!",
                        style: TextStyle(
                          color: AppTheme.textMedium,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 22),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textLight,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 400 + (index * 80)));
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
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
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

  // ─── TALAB VA TAKLIFLAR ───
  void _showFeedbackBottomSheet() {
    final userService = Get.find<UserService>();
    final msgCtrl = TextEditingController();
    bool isSubmitting = false;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
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
                          Icons.rate_review_rounded,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Talab va takliflar",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Ilovani yaxshilashda bizga yordam bering! Fikr, talab yoki takliflaringizni yozib qoldiring.",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: msgCtrl,
                      maxLines: 5,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: "Shu yerga yozing...",
                        hintStyle: TextStyle(color: AppTheme.textLight),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    GestureDetector(
                      onTap: () async {
                        if (msgCtrl.text.trim().isEmpty) return;
                        setState(() => isSubmitting = true);
                        try {
                          await FirebaseFirestore.instance
                              .collection('app_feedbacks')
                              .add({
                                'uid': userService.currentUid,
                                'name': userService.name.value,
                                'phone': userService.phone.value,
                                'role': userService.userRole.value,
                                'message': msgCtrl.text.trim(),
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                          Get.back();
                          Get.snackbar(
                            "Rahmat!",
                            "Fikringiz muvaffaqiyatli yuborildi.",
                            backgroundColor: AppTheme.success,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            margin: EdgeInsets.all(16),
                            borderRadius: 14,
                            icon: Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                            ),
                          );
                        } catch (e) {
                          setState(() => isSubmitting = false);
                          Get.snackbar(
                            "Xatolik",
                            "Yuborishda xatolik yuz berdi",
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSubmitting
                                ? [AppTheme.textLight, AppTheme.textMedium]
                                : [AppTheme.primary, AppTheme.accent],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Yuborish",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
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
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
