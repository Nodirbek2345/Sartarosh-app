import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../controllers/home_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/image_helper.dart';
import '../../barber_dashboard/views/barber_dashboard_view.dart';
import '../../barber_dashboard/controllers/barber_dashboard_controller.dart';
import '../../barber_dashboard/bindings/barber_dashboard_binding.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = Get.find<UserService>();
    return Obx(() {
      if (userService.isBarberMode.value) {
        // Ensure BarberDashboardController is registered
        if (!Get.isRegistered<BarberDashboardController>()) {
          BarberDashboardBinding().dependencies();
        }
        return BarberDashboardView();
      }
      return _buildClientHome();
    });
  }

  Widget _buildClientHome() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  controller.refreshBarbers();
                  await Future.delayed(const Duration(milliseconds: 1000));
                },
                color: AppTheme.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: _buildSearchBar()),
                    SliverToBoxAdapter(child: _buildQuickAction()),
                    SliverToBoxAdapter(child: _buildBarberOfWeek()),
                    SliverToBoxAdapter(child: _buildCategories()),
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(
                        "Yaqindagi ustalar",
                        "Barchasi",
                      ),
                    ),
                    if (controller.rxBarbers.isEmpty)
                      SliverToBoxAdapter(child: _buildEmptyState())
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                        ).copyWith(bottom: 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildBarberListItem(
                              controller.rxBarbers[index],
                              index,
                            ),
                            childCount: controller.rxBarbers.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── HEADER ───
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Menu icon
            GestureDetector(
              onTap: () => _showMenuBottomSheet(),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu, color: AppTheme.textDark, size: 22),
              ),
            ),
            Spacer(),
            // Location (dynamic + tappable)
            GestureDetector(
              onTap: () => Get.toNamed('/region'),
              child: Obx(() {
                final region = Get.find<UserService>().selectedRegion.value;
                final displayRegion = region.isNotEmpty ? region : "Tanlang";
                return Row(
                  children: [
                    Icon(Icons.location_on, color: AppTheme.primary, size: 18),
                    SizedBox(width: 4),
                    Text(
                      displayRegion,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMedium,
                      size: 20,
                    ),
                  ],
                );
              }),
            ),
            Spacer(),
            // Avatar
            Obx(() {
              final avatarBase64 = Get.find<UserService>().avatarBase64.value;
              return GestureDetector(
                onTap: () => Get.toNamed('/profile'),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    image: avatarBase64.isNotEmpty
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(avatarBase64)),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: avatarBase64.isEmpty
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: avatarBase64.isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          color: AppTheme.primary,
                          size: 22,
                        )
                      : null,
                ),
              );
            }),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  // ─── SEARCH BAR ───
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: "Usta yoki xizmat qidiring...",
            hintStyle: GoogleFonts.poppins(
              color: AppTheme.textLight,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppTheme.textLight,
              size: 22,
            ),
            suffixIcon: Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.tune_rounded, color: Colors.white, size: 18),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ─── BARBER OF THE WEEK ───
  Widget _buildBarberOfWeek() {
    return Obx(() {
      if (controller.rxBarbers.isEmpty) return SizedBox.shrink();
      // Pick highest rated barber
      final featured = controller.rxBarbers.reduce(
        (a, b) => (a['rating'] ?? 0) >= (b['rating'] ?? 0) ? a : b,
      );
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: GestureDetector(
          onTap: () => Get.toNamed('/barber-detail', arguments: featured),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.5),
                width: 2,
              ),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.06),
                  Colors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Text content
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "⭐ Hafta ustasi",
                            style: GoogleFonts.poppins(
                              color: AppTheme.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          featured['name'] ?? 'Usta',
                          style: GoogleFonts.playfairDisplay(
                            color: AppTheme.textDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: i < (featured['rating'] ?? 5).round()
                                    ? AppTheme.primary
                                    : AppTheme.textLight.withValues(alpha: 0.3),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "${featured['rating'] ?? 5.0}",
                              style: GoogleFonts.poppins(
                                color: AppTheme.textDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primary),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Portfolio ko'rish",
                            style: GoogleFonts.poppins(
                              color: AppTheme.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Image
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(22),
                    ),
                    child: CachedNetworkImage(
                      imageUrl:
                          featured['image'] ??
                          'https://i.pravatar.cc/400?u=${featured['id']}',
                      fit: BoxFit.cover,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05);
    });
  }

  // ─── CATEGORIES ───
  Widget _buildCategories() {
    return Obx(() {
      final gender = Get.find<UserService>().targetGender.value;

      final List<Map<String, dynamic>> categories;

      if (gender == 'female') {
        categories = [
          {'icon': Icons.grid_view_rounded, 'name': 'Barchasi'},
          {'icon': Icons.content_cut_rounded, 'name': 'Soch turmak'},
          {'icon': Icons.face_retouching_natural_rounded, 'name': 'Makiyaj'},
          {'icon': Icons.color_lens_rounded, 'name': "Bo'yash"},
          {'icon': Icons.back_hand_rounded, 'name': 'Manikyur'},
          {'icon': Icons.spa_rounded, 'name': 'Kompleks'},
        ];
      } else {
        categories = [
          {'icon': Icons.grid_view_rounded, 'name': 'Barchasi'},
          {'icon': Icons.content_cut_rounded, 'name': 'Soch olish'},
          {'icon': Icons.face_rounded, 'name': 'Soqol'},
          {'icon': Icons.auto_awesome_rounded, 'name': 'Styling'},
          {'icon': Icons.water_drop_rounded, 'name': 'Bosh yuvish'},
          {'icon': Icons.child_care_rounded, 'name': 'Bolalar'},
          {'icon': Icons.spa_rounded, 'name': 'Kompleks'},
        ];
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Kategoriyalar",
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              child: Row(
                children: categories.asMap().entries.map((e) {
                  final cat = e.value;
                  final isFirst = e.key == 0;
                  return Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => Get.toNamed('/services'),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? (gender == 'female'
                                    ? AppTheme.accent
                                    : AppTheme.darkBg)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isFirst
                              ? null
                              : Border.all(
                                  color: AppTheme.textLight.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                          boxShadow: isFirst
                              ? [
                                  BoxShadow(
                                    color:
                                        (gender == 'female'
                                                ? AppTheme.accent
                                                : AppTheme.darkBg)
                                            .withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              color: isFirst ? Colors.white : AppTheme.textDark,
                              size: 26,
                            ),
                            SizedBox(height: 8),
                            Text(
                              cat['name'] as String,
                              style: GoogleFonts.poppins(
                                color: isFirst
                                    ? Colors.white
                                    : AppTheme.textMedium,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms);
    });
  }

  // ─── SECTION TITLE ───
  Widget _buildSectionTitle(String title, String action) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          GestureDetector(
            onTap: () => Get.toNamed('/services'),
            child: Text(
              "$action »",
              style: GoogleFonts.poppins(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  // ─── SMART REBOOK (AI FEEL) & QUICK ACTION ───
  Widget _buildQuickAction() {
    return Obx(() {
      final upcoming = controller.upcomingBooking.value;
      if (upcoming != null) {
        // If there's an upcoming booking, they don't necessarily need a strict 'rebook' right now.
        // We can just show standard upcoming booking overview.
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: GestureDetector(
            onTap: () => Get.toNamed('/my-bookings'),
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.08),
                    AppTheme.primary.withValues(alpha: 0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Yaqin kunlarda",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          "${upcoming['date']} | ${upcoming['time']} | ${upcoming['barberName']}",
                          style: GoogleFonts.poppins(
                            color: AppTheme.textMedium,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Ko'rish",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05);
      }

      // If NO upcoming booking, but there is a PAST booking, encourage rebook!
      final lastBooking = controller.lastBooking.value;
      if (lastBooking == null) return SizedBox.shrink();

      final smartRecommendationText = controller.smartRecommendationText.value;

      return Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: GestureDetector(
          onTap: () {
            // Find the barber reference
            final bName = lastBooking['barberName'];
            Map<String, dynamic>? targetBarber;
            try {
              targetBarber = controller.rxBarbers.firstWhere(
                (b) => b['name'] == bName,
              );
            } catch (_) {}

            if (targetBarber != null) {
              // 1-Click Booking Route!
              Get.toNamed(
                '/booking',
                arguments: {
                  'barber': targetBarber,
                  'service': lastBooking['service'] ?? 'Soch olish',
                  'price': lastBooking['price'] ?? 30000,
                },
              );
            } else {
              Get.snackbar(
                "Xatolik",
                "Sizning oxirgi ustangiz topilmadi, iltimos ustalar ro'yxatidan tanlang.",
              );
            }
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.success.withValues(alpha: 0.1),
                  AppTheme.success.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.success.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded, // AI feel icon
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Yana shu xizmatni olish",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        smartRecommendationText,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textMedium,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.textDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Qayta bron",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05);
    });
  }

  // ─── EMPTY STATE ───
  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.content_cut_rounded,
              size: 48,
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Hali usta ro'yxatga olinmagan",
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Sahifani qayta yuklang yoki keyinroq qaytib keling",
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () => controller.onInit(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Qayta yuklash",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BARBER LIST ITEM (Nearby style) ───
  Widget _buildBarberListItem(Map<String, dynamic> barber, int index) {
    // True business logic for Faol/Faol emas and Bo'sh/Band
    final bool isActive = barber['isActive'] ?? true;

    return GestureDetector(
          onTap: () => Get.toNamed('/barber-detail', arguments: barber),
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isActive
                  ? null
                  : Border.all(color: Colors.red.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: ImageHelper.getBarberImage(
                            barber['image']?.toString(),
                            barber['id']?.toString() ?? 'unknown',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  barber['name'] ?? 'Usta',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                              Obx(() {
                                final isFav = Get.find<UserService>()
                                    .isFavorite(barber['id']);
                                return GestureDetector(
                                  onTap: () {
                                    Get.find<UserService>().toggleFavorite(
                                      barber['id'],
                                    );
                                    if (!isFav) {
                                      Get.snackbar(
                                        "❤️ Sevimli",
                                        "Sevimlilarga qo'shildi",
                                        snackPosition: SnackPosition.TOP,
                                        backgroundColor: AppTheme.primary
                                            .withValues(alpha: 0.9),
                                        colorText: Colors.white,
                                        duration: Duration(seconds: 2),
                                        margin: EdgeInsets.all(16),
                                        borderRadius: 16,
                                      );
                                    }
                                  },
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFav
                                        ? Colors.redAccent
                                        : AppTheme.textLight,
                                    size: 20,
                                  ),
                                );
                              }),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.success.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isActive
                                            ? AppTheme.success
                                            : Colors.red,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      isActive ? "Ishda" : "Ishda emas",
                                      style: GoogleFonts.poppins(
                                        color: isActive
                                            ? AppTheme.success
                                            : Colors.red,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppTheme.gold,
                              ),
                              SizedBox(width: 2),
                              Text(
                                "${barber['rating'] ?? 5.0}",
                                style: GoogleFonts.poppins(
                                  color: AppTheme.textDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: AppTheme.textLight,
                              ),
                              SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  barber['address'] ?? "Toshkent",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textLight,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!isActive)
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                "Usta ayni damda o'z ish o'rnida emas",
                                style: GoogleFonts.poppins(
                                  color: AppTheme.textMedium,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // Action buttons removed based on user request
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 500 + (index * 80)))
        .slideX(begin: 0.05);
  }

  // ─── BOTTOM NAV ───
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(Icons.home_rounded, "Asosiy", true),
              _navItem(
                Icons.search_rounded,
                "Qidirish",
                false,
                onTap: () => Get.toNamed('/services'),
              ),
              _navItem(
                Icons.calendar_month_rounded,
                "Bronlar",
                false,
                onTap: () => Get.toNamed('/my-bookings'),
              ),
              _navItem(
                Icons.favorite_rounded,
                "Sevimlilar",
                false,
                onTap: () => Get.toNamed('/favorites'),
              ),
              _navItem(
                Icons.person_rounded,
                "Profil",
                false,
                onTap: () => Get.toNamed('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: isActive
                  ? BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Icon(
                icon,
                color: isActive ? AppTheme.primary : AppTheme.textLight,
                size: 22,
              ),
            ),
            SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isActive ? AppTheme.primary : AppTheme.textLight,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenuBottomSheet() {
    final userService = Get.find<UserService>();
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Obx(() {
              final role = userService.userRole.value;
              final isBarber = userService.isBarberMode.value;
              final roleName = isBarber
                  ? "Sartarosh"
                  : (role == 'barber' ? "Mijoz (Sartarosh)" : "Mijoz");
              final roleColor = isBarber ? AppTheme.gold : AppTheme.primary;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Builder(
                        builder: (_) {
                          final avatarBase64 = userService.avatarBase64.value;
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              image: avatarBase64.isNotEmpty
                                  ? DecorationImage(
                                      image: MemoryImage(
                                        base64Decode(avatarBase64),
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: avatarBase64.isEmpty
                                ? Icon(Icons.person, color: AppTheme.primary)
                                : null,
                          );
                        },
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userService.name.value,
                              style: GoogleFonts.poppins(
                                color: AppTheme.textDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              userService.phone.value,
                              style: GoogleFonts.poppins(
                                color: AppTheme.textMedium,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roleName,
                          style: GoogleFonts.poppins(
                            color: roleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),

                  // ─── MIJOZ (Client) MENU ───
                  if (!isBarber) ...[
                    _menuItem(
                      icon: Icons.person_outline_rounded,
                      title: "Mening profilim",
                      onTap: () {
                        Get.back();
                        Get.toNamed('/profile');
                      },
                    ),
                    _menuItem(
                      icon: Icons.calendar_today_rounded,
                      title: "Mening bronlarim",
                      onTap: () {
                        Get.back();
                        Get.toNamed('/my-bookings');
                      },
                    ),
                    _menuItem(
                      icon: Icons.favorite_border_rounded,
                      title: "Sevimlilar",
                      onTap: () {
                        Get.back();
                        Get.toNamed('/favorites');
                      },
                    ),
                    _menuItem(
                      icon: Icons.support_agent_rounded,
                      title: "Qo'llab-quvvatlash",
                      onTap: () {
                        Get.back();
                        Get.toNamed('/support-chat');
                      },
                    ),
                  ],

                  // ─── SARTAROSH (Barber) MENU ───
                  if (isBarber) ...[
                    _menuItem(
                      icon: Icons.person_outline_rounded,
                      title: "Mening profilim",
                      onTap: () {
                        Get.back();
                        Get.toNamed('/profile');
                      },
                    ),
                    _menuItem(
                      icon: Icons.design_services_rounded,
                      title: "Xizmatlar va narxlar",
                      onTap: () {
                        Get.back();
                        Get.toNamed('/profile');
                      },
                    ),
                    _menuItem(
                      icon: Icons.support_agent_rounded,
                      title: "Qo'llab-quvvatlash",
                      onTap: () {
                        Get.back();
                        Get.toNamed('/support-chat');
                      },
                    ),
                  ],

                  Divider(color: AppTheme.background, height: 30),

                  // Rol almashish
                  if (role == 'barber' && !isBarber)
                    _menuItem(
                      icon: Icons.storefront_rounded,
                      title: "Usta rejimiga o'tish",
                      color: AppTheme.gold,
                      onTap: () {
                        Get.back();
                        userService.toggleBarberMode();
                      },
                    ),
                  if (isBarber)
                    _menuItem(
                      icon: Icons.swap_horiz_rounded,
                      title: "Mijoz rejimiga o'tish",
                      color: AppTheme.primary,
                      onTap: () {
                        Get.back();
                        userService.toggleBarberMode();
                      },
                    ),

                  _menuItem(
                    icon: Icons.logout_rounded,
                    title: "Tizimdan chiqish",
                    color: Colors.redAccent,
                    onTap: () {
                      Get.back();
                      userService.logout();
                      Get.offAllNamed('/welcome');
                    },
                  ),
                  SizedBox(height: 20),
                ],
              );
            }),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color?.withValues(alpha: 0.1) ?? AppTheme.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: color ?? AppTheme.textDark, size: 22),
              SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: color ?? AppTheme.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: color ?? AppTheme.textMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
