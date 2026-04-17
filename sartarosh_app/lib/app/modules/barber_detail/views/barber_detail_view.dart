import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/image_helper.dart';

class BarberDetailView extends StatelessWidget {
  const BarberDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final barber = Get.arguments as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Hero Image
          Stack(
            children: [
              Container(
                height: 320,
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
              // Gradient overlay
              Container(
                height: 320,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      AppTheme.background,
                    ],
                  ),
                ),
              ),
              // Back
              Positioned(
                top: 48,
                left: 16,
                child: _circleButton(
                  Icons.arrow_back_rounded,
                  () => Get.back(),
                ),
              ),
              // Favorite
              Positioned(
                top: 48,
                right: 68,
                child: Obx(() {
                  final isFav = Get.find<UserService>().isFavorite(
                    barber['id'],
                  );
                  return _circleButton(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    () => Get.find<UserService>().toggleFavorite(barber['id']),
                    color: isFav ? Colors.redAccent : AppTheme.textDark,
                  );
                }),
              ),
              // Share
              Positioned(
                top: 48,
                right: 16,
                child: _circleButton(Icons.share_rounded, () {}),
              ),
            ],
          ).animate().fadeIn(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        barber['name'] ?? 'Usta',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Builder(
                        builder: (_) {
                          final bool isActive = barber['isActive'] ?? true;
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.success.withValues(alpha: 0.1)
                                  : AppTheme.textMedium.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? "Ochiq" : "Faol emas",
                              style: GoogleFonts.poppins(
                                color: isActive
                                    ? AppTheme.success
                                    : AppTheme.textMedium,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 15,
                        color: AppTheme.textMedium,
                      ),
                      SizedBox(width: 4),
                      Text(
                        barber['address'] ?? "Toshkent",
                        style: GoogleFonts.poppins(
                          color: AppTheme.textMedium,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.star_rounded, size: 15, color: AppTheme.gold),
                      SizedBox(width: 3),
                      Text(
                        "${barber['rating'] ?? 5.0}",
                        style: GoogleFonts.poppins(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "  (${barber['reviewCount'] ?? 0} sharhlar)",
                        style: GoogleFonts.poppins(
                          color: AppTheme.textMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  SizedBox(height: 20),

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
                        () => _launch(
                          "https://maps.google.com/?q=${Uri.encodeComponent(barber['address'] ?? 'Toshkent')}",
                        ),
                      ),
                      _actionButton(Icons.share_rounded, "Ulashish", () {}),
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
                    ...(barber['services'] as List).map<Widget>(
                      (s) => GestureDetector(
                        onTap: () {
                          if (barber['isActive'] != false) {
                            Get.toNamed(
                              '/booking',
                              arguments: {
                                'barber': barber,
                                'service': s['name'] ?? 'Soch olish',
                                'price': s['price'] ?? 30000,
                              },
                            );
                          } else {
                            Get.snackbar(
                              "Eslatma",
                              "Usta hozirda faol emas, bron qilib bo'lmaydi",
                              duration: Duration(seconds: 2),
                            );
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s['name'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "${(s['price'] / 1000).toStringAsFixed(0)} ming",
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppTheme.textMedium.withValues(
                                      alpha: 0.5,
                                    ),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // CTA
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
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
              onTap: () => Get.toNamed(
                '/booking',
                arguments: {
                  'barber': barber,
                  'service': 'Soch olish',
                  'price': barber['services']?[0]?['price'] ?? 30000,
                },
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "Bron qilish",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ).animate().slideY(begin: 1, delay: 400.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }

  Widget _circleButton(
    IconData icon,
    VoidCallback onTap, {
    Color color = AppTheme.textDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
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
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
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
                    image: NetworkImage(portfolio[index]),
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
