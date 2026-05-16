import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/image_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/barber_detail_controller.dart';

class BarberDetailView extends StatelessWidget {
  const BarberDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final barber = Get.arguments as Map<String, dynamic>? ?? {};
    final userService = Get.find<UserService>();
    // Xavfsizlik: sartarosh o'zini-o'zi bron qila olmasligi kerak
    final bool isSelf =
        barber['uid'] == userService.currentUid ||
        barber['name'] == userService.name.value;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ── IMMERSIVE GLASS HERO ──────────────────────
          Stack(
            children: [
              // Hero image
              Container(
                height: 340,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: ImageHelper.getBarberImage(
                      barber['image']?.toString(),
                      barber['id']?.toString() ?? 'unknown',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Multi-layer gradient overlay for depth
              Container(
                height: 340,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.35, 0.75, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.30),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              // Back button — glass
              Positioned(
                top: 48,
                left: 16,
                child: _circleButton(
                  Icons.arrow_back_rounded,
                  () => Get.back(),
                ),
              ),
              // Favorite button — glass
              Positioned(
                top: 48,
                right: 16,
                child: Obx(() {
                  final isFav = Get.find<UserService>().isFavorite(
                    barber['id'],
                  );
                  return _circleButton(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    () => Get.find<UserService>().toggleFavorite(barber['id']),
                    color: isFav ? AppTheme.danger : Colors.white,
                  );
                }),
              ),
              // Glass name/info card overlaid at the bottom of hero
              Positioned(
                bottom: 0,
                left: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.all(18),
                  decoration: AppTheme.glassCard(radius: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              barber['name'] ?? 'Usta',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Builder(
                            builder: (_) {
                              final bool isActive = barber['isActive'] ?? true;
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.success.withValues(alpha: 0.25)
                                      : AppTheme.danger.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive
                                        ? AppTheme.success.withValues(
                                            alpha: 0.6,
                                          )
                                        : AppTheme.danger.withValues(
                                            alpha: 0.6,
                                          ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isActive
                                            ? AppTheme.success
                                            : AppTheme.danger,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (isActive
                                                        ? AppTheme.success
                                                        : AppTheme.danger)
                                                    .withValues(alpha: 0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      isActive ? "Ishda" : "Ishda emas",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Location + rating in one row
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: Colors.white70,
                          ),
                          SizedBox(width: 3),
                          Expanded(
                            child: Obx(() {
                              final ctrl = Get.find<BarberDetailController>();
                              final dist = ctrl.distanceText.value;
                              final addr = barber['address'] ?? 'Toshkent';
                              return Text(
                                dist.isNotEmpty ? "$addr · $dist" : addr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              );
                            }),
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppTheme.primaryLight,
                          ),
                          SizedBox(width: 3),
                          Text(
                            "${barber['rating'] ?? 5.0}",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "  (${barber['reviewCount'] ?? 0})",
                            style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08),
              ),
            ],
          ).animate().fadeIn(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(
                        Icons.phone_rounded,
                        "Qo'ng'iroq",
                        () => _launch(
                          "tel:${barber['phone'] ?? '+998901234567'}",
                        ),
                      ),
                      _actionButton(
                        Icons.chat_bubble_outline_rounded,
                        "Xabar",
                        () => _launch(
                          "sms:${barber['phone'] ?? '+998901234567'}",
                        ),
                      ),
                      _actionButton(
                        Icons.directions_rounded,
                        "Yo'nalish",
                        () =>
                            Get.find<BarberDetailController>().openDirections(),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),

                  SizedBox(height: 24),

                  // About
                  if (barber['about'] != null) ...[
                    Text(
                      "Haqida",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      barber['about'],
                      style: GoogleFonts.poppins(
                        color: AppTheme.textMedium,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],

                  // Portfolio
                  _buildPortfolio(barber),
                  SizedBox(height: 10),

                  // Services
                  if (barber['services'] != null &&
                      (barber['services'] as List).isNotEmpty) ...[
                    Text(
                      "Xizmatlar",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...(barber['services'] as List).map<Widget>((s) {
                      final bool barberIsActive = barber['isActive'] ?? true;
                      final int price = s['price'] ?? 0;
                      final int duration = s['duration'] ?? 30;
                      return GestureDetector(
                        onTap: () {
                          if (isSelf) {
                            Get.snackbar(
                              "⚠️ Bu sizning profilingiz",
                              "O'zingizga o'zingiz bron qila olmaysiz.",
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: AppTheme.primary.withValues(
                                alpha: 0.9,
                              ),
                              colorText: Colors.white,
                              duration: Duration(seconds: 3),
                              margin: EdgeInsets.all(16),
                              borderRadius: 16,
                            );
                            return;
                          }
                          if (barberIsActive) {
                            _showBookingOptions(
                              context,
                              s['name'] ?? 'Soch olish',
                              price,
                              duration,
                            );
                          } else {
                            Get.snackbar(
                              "⚠️ Usta hozir ishda emas",
                              "Usta ish o'rniga qaytganda qayta urinib ko'ring",
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: AppTheme.danger.withValues(
                                alpha: 0.9,
                              ),
                              colorText: Colors.white,
                              duration: Duration(seconds: 3),
                              margin: EdgeInsets.all(16),
                              borderRadius: 16,
                            );
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: barberIsActive
                                ? Colors.white
                                : Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s['name'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: barberIsActive
                                            ? AppTheme.textDark
                                            : AppTheme.textMedium,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 13,
                                          color: AppTheme.textLight,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "$duration daqiqa",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    price > 0
                                        ? "${(price / 1000).toStringAsFixed(0)} ming"
                                        : "Kelishiladi",
                                    style: GoogleFonts.poppins(
                                      color: barberIsActive
                                          ? AppTheme.primary
                                          : AppTheme.textLight,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (!isSelf) ...[
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: barberIsActive
                                            ? AppTheme.primary.withValues(
                                                alpha: 0.1,
                                              )
                                            : AppTheme.textLight.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        barberIsActive
                                            ? Icons.arrow_forward_rounded
                                            : Icons.block_rounded,
                                        color: barberIsActive
                                            ? AppTheme.primary
                                            : AppTheme.textLight,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 10),
                  ],

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // CTA
          Builder(
            builder: (_) {
              if (isSelf) return const SizedBox.shrink();
              final bool ctaActive = barber['isActive'] ?? true;
              return Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.paddingOf(Get.context!).bottom + 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    if (isSelf) {
                      Get.snackbar(
                        "⚠️ Bron qilib bo'lmaydi",
                        "Siz o'zingizning profilingizni ko'ryapsiz. Faqat mijozlar bron qilishi mumkin.",
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: AppTheme.primary.withValues(
                          alpha: 0.9,
                        ),
                        colorText: Colors.white,
                        duration: Duration(seconds: 3),
                        margin: EdgeInsets.all(16),
                        borderRadius: 16,
                      );
                      return;
                    }
                    if (ctaActive) {
                      _showBookingOptions(
                        Get.context!,
                        barber['services']?[0]?['name'] ?? 'Soch olish',
                        barber['services']?[0]?['price'] ?? 30000,
                        30,
                      );
                    } else {
                      Get.snackbar(
                        "⚠️ Usta hozir ishda emas",
                        "Usta ish o'rniga qaytganda siz bron qila olasiz",
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: AppTheme.danger.withValues(alpha: 0.9),
                        colorText: Colors.white,
                        duration: Duration(seconds: 3),
                        margin: EdgeInsets.all(16),
                        borderRadius: 16,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: ctaActive ? AppTheme.goldGradient : null,
                      color: ctaActive
                          ? null
                          : AppTheme.textLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: ctaActive
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!ctaActive && !isSelf) ...[
                            Icon(
                              Icons.schedule_rounded,
                              color: AppTheme.textMedium,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                          ],
                          if (isSelf) ...[
                            Icon(
                              Icons.person_rounded,
                              color: AppTheme.textMedium,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                          ],
                          Text(
                            isSelf
                                ? "Bu sizning profilingiz"
                                : (ctaActive
                                      ? "✂️  Hozir bron qilish"
                                      : "Usta hozir ishda emas"),
                            style: GoogleFonts.poppins(
                              color: isSelf
                                  ? AppTheme.textMedium
                                  : (ctaActive
                                        ? Colors.white
                                        : AppTheme.textMedium),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ).animate().slideY(begin: 1, delay: 400.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }

  Widget _circleButton(
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: AppTheme.glassCard(radius: 14),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.15),
                  AppTheme.primary.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingOptions(
    BuildContext context,
    String serviceName,
    int price,
    int duration,
  ) {
    final BarberDetailController controller = Get.find();
    final barber = controller.barber;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Xizmat qabul qilish turi",
              style: GoogleFonts.playfairDisplay(
                color: AppTheme.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Bron qilish yoki jonli navbatga yozilishni tanlang.",
              style: GoogleFonts.poppins(
                color: AppTheme.textMedium,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),

            // Bron qilish Option
            GestureDetector(
              onTap: () {
                Get.back(); // close bottom sheet
                Get.toNamed(
                  '/booking',
                  arguments: {
                    'barber': barber,
                    'service': serviceName,
                    'price': price,
                    'duration': duration,
                  },
                );
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bron qilish (Vaqt tanlash)",
                            style: GoogleFonts.poppins(
                              color: AppTheme.textDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "O'zingizga qulay kun va vaqtni band qiling",
                            style: GoogleFonts.poppins(
                              color: AppTheme.textMedium,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 0.2).fadeIn(),

            SizedBox(height: 16),

            // Jonli Navbat Option
            GestureDetector(
              onTap: () => controller.joinQueue(serviceName, price, duration),
              child: Obx(
                () => Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: controller.isJoiningQueue.value
                      ? Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.people_alt_rounded,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Jonli navbatga yozilish",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "Hozirgi navbat oxiriga qo'shilish",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ).animate().slideY(begin: 0.2, delay: 100.ms).fadeIn(),
            SizedBox(height: 24),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildPortfolio(Map<String, dynamic> barber) {
    final List portfolio = barber['portfolio'] ?? [];
    if (portfolio.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Portfolio & Ish namunalari",
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            itemCount: portfolio.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(portfolio[index]),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20),
      ],
    ).animate().fadeIn(delay: 350.ms);
  }
}
