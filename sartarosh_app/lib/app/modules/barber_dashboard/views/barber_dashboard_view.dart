import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/barber_dashboard_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/update_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BarberDashboardView extends GetView<BarberDashboardController> {
  const BarberDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentTab = 0.obs;
    final pageController = PageController();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => currentTab.value = i,
        children: [
          _DashboardTab(controller: controller),
          _BarberBookingsTab(controller: controller),
          _QueueTab(controller: controller),
          _ServicesTab(),
          _BarberProfileTab(),
        ],
      ),
      bottomNavigationBar: Obx(
        () => _buildBottomNav(currentTab, pageController),
      ),
    );
  }

  Widget _buildBottomNav(RxInt currentTab, PageController pageCtrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(
                Icons.dashboard_rounded,
                "Dashboard",
                currentTab.value == 0,
                () {
                  pageCtrl.jumpToPage(0);
                  currentTab.value = 0;
                },
              ),
              _navItem(
                Icons.calendar_month_rounded,
                "Bronlar",
                currentTab.value == 1,
                () {
                  pageCtrl.jumpToPage(1);
                  currentTab.value = 1;
                },
              ),
              _navItem(
                Icons.queue_rounded,
                "Navbat",
                currentTab.value == 2,
                () {
                  pageCtrl.jumpToPage(2);
                  currentTab.value = 2;
                },
              ),
              _navItem(
                Icons.design_services_rounded,
                "Xizmatlar",
                currentTab.value == 3,
                () {
                  pageCtrl.jumpToPage(3);
                  currentTab.value = 3;
                },
              ),
              _navItem(
                Icons.person_rounded,
                "Profil",
                currentTab.value == 4,
                () {
                  pageCtrl.jumpToPage(4);
                  currentTab.value = 4;
                },
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
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
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
            const SizedBox(height: 3),
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
}

// ═══════════════════════════════════════════
// TAB 1: DASHBOARD
// ═══════════════════════════════════════════
class _DashboardTab extends StatelessWidget {
  final BarberDashboardController controller;
  const _DashboardTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        );
      }
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildStats()),
          SliverToBoxAdapter(child: _buildStatusToggle()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                "Bugungi navbatlar",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ).animate().fadeIn(delay: 350.ms),
          ),
          if (controller.todayBookings.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ).copyWith(bottom: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildBookingCard(controller.todayBookings[index]),
                  childCount: controller.todayBookings.length,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildHeader() {
    final userService = Get.find<UserService>();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        gradient: AppTheme.darkGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Salom, ${userService.name.value} 👋",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Usta boshqaruv paneli",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _statCard(
            Icons.people_rounded,
            "Mijozlar",
            "${controller.todayClientsCount.value}",
            AppTheme.primary,
          ),
          const SizedBox(width: 12),
          _statCard(
            Icons.check_circle_rounded,
            "Bajarildi",
            "${controller.completedCount.value}",
            AppTheme.success,
          ),
          const SizedBox(width: 12),
          _statCard(
            Icons.monetization_on_rounded,
            "Daromad",
            "${controller.todayEarnings.value}",
            AppTheme.gold,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Qabul limiti",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Maksimal mijozlar",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                  _buildPremiumCounter(),
                ],
              ),
            ),
            Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
            GestureDetector(
              onTap: () => controller.toggleActiveStatus(),
              child: Obx(() {
                final active = controller.isActive.value;
                return AnimatedContainer(
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.success.withValues(alpha: 0.08)
                        : Colors.red.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? AppTheme.success : Colors.red,
                          boxShadow: [
                            BoxShadow(
                              color: (active ? AppTheme.success : Colors.red)
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              active
                                  ? "Siz hozir ish o'rnidasiz"
                                  : "Siz hozir ishda emassiz",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              active
                                  ? "Mijozlar qabulga yoza oladi"
                                  : "Sizga yangi navbatlar kelmaydi",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active ? Colors.red : AppTheme.success,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: (active ? Colors.red : AppTheme.success)
                                  .withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          active ? "Ishni yopish" : "Ishni boshlash",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildPremiumCounter() {
    return Obx(() {
      final value = controller.queueLimit.value;
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => controller.decrementLimit(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.remove_rounded,
                  size: 18,
                  color: value > 1
                      ? AppTheme.textDark
                      : Colors.grey.withValues(alpha: 0.5),
                ),
              ),
            ),
            Container(
              alignment: Alignment.center,
              width: 36,
              child: Text(
                value.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => controller.incrementLimit(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: value < 99
                      ? AppTheme.textDark
                      : Colors.grey.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 48,
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Bugun navbat yo'q",
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Yangi mijozlar kutilmoqda",
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'pending';
    Color statusColor;
    String statusText;
    switch (status) {
      case 'confirmed':
        statusColor = AppTheme.primary;
        statusText = "Tasdiqlangan";
        break;
      case 'in-progress':
        statusColor = Colors.orange;
        statusText = "Jarayonda";
        break;
      case 'completed':
        statusColor = AppTheme.success;
        statusText = "Tugatilgan";
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = "Bekor qilingan";
        break;
      default:
        statusColor = AppTheme.textMedium;
        statusText = "Kutilmoqda";
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['client'] ?? 'Mijoz',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        "${booking['time'] ?? ''} | ${booking['service'] ?? 'Xizmat'}",
                        style: GoogleFonts.poppins(
                          color: AppTheme.textMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    "Qabul qilish",
                    AppTheme.success,
                    () => controller.acceptBooking(booking['docId']),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionBtn(
                    "Qaytarish",
                    Colors.redAccent,
                    () => controller.rejectBooking(booking['docId']),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'confirmed') ...[
            const SizedBox(height: 14),
            _actionBtn(
              "🔥 Boshlash",
              null,
              () => controller.startClient(booking['docId']),
              isGold: true,
            ),
          ],
          if (status == 'in-progress') ...[
            const SizedBox(height: 14),
            _actionBtn(
              "✓ Tugatish",
              AppTheme.success,
              () => controller.completeClient(booking['docId']),
              isSolid: true,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.03);
  }

  Widget _actionBtn(
    String text,
    Color? color,
    VoidCallback onTap, {
    bool isGold = false,
    bool isSolid = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isGold ? AppTheme.goldGradient : null,
          color: isGold
              ? null
              : (isSolid ? color : color?.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: (isGold || isSolid) ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// TAB 2: BARBER BRONLAR
// ═══════════════════════════════════════════
class _BarberBookingsTab extends StatelessWidget {
  final BarberDashboardController controller;
  const _BarberBookingsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final selectedFilter = 'all'.obs;
    final filters = {
      'all': 'Barchasi',
      'pending': 'Kutilmoqda',
      'confirmed': 'Tasdiqlangan',
      'in-progress': 'Jarayonda',
      'completed': 'Bajarildi',
      'cancelled': 'Bekor',
    };

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          decoration: BoxDecoration(
            gradient: AppTheme.darkGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "📅 Bronlar",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Obx(() {
                      final pending = controller.pendingCount.value;
                      if (pending == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$pending ta yangi",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Barcha mijoz bronlari (barcha kunlar)",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(
                    () => Row(
                      children: filters.entries.map((e) {
                        final isSelected = selectedFilter.value == e.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => selectedFilter.value = e.key,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                e.value,
                                style: GoogleFonts.poppins(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            var bookings = controller.allBookings.toList();
            if (selectedFilter.value != 'all') {
              bookings = bookings
                  .where((b) => b['status'] == selectedFilter.value)
                  .toList();
            }
            if (bookings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 64,
                      color: AppTheme.textLight.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Bronlar topilmadi",
                      style: GoogleFonts.poppins(
                        color: AppTheme.textMedium,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: bookings.length,
              itemBuilder: (_, i) => _buildAllBookingCard(bookings[i]),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAllBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'pending';
    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case 'confirmed':
        statusColor = AppTheme.primary;
        statusText = "Tasdiqlangan";
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'in-progress':
        statusColor = Colors.orange;
        statusText = "Jarayonda";
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'completed':
        statusColor = AppTheme.success;
        statusText = "Tugatilgan";
        statusIcon = Icons.task_alt_rounded;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = "Bekor qilingan";
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.orangeAccent;
        statusText = "Kutilmoqda";
        statusIcon = Icons.access_time_rounded;
    }

    final date = booking['date'] ?? '';
    final time = booking['time'] ?? '';
    final price = booking['price'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: status == 'pending'
            ? Border.all(
                color: Colors.orangeAccent.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sarlavha: Mijoz nomi va status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking['client'] ?? 'Mijoz',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            booking['service'] ?? 'Xizmat',
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Sana, vaqt, narx
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppTheme.textMedium,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppTheme.textMedium,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  "$price so'm",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Amal tugmalari
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _btn(
                    "✓ Qabul qilish",
                    AppTheme.success,
                    () => controller.acceptBooking(booking['docId']),
                    isSolid: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _btn(
                    "✗ Rad etish",
                    Colors.redAccent,
                    () => controller.rejectBooking(booking['docId']),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'confirmed') ...[
            const SizedBox(height: 14),
            _btn(
              "🔥 Boshlash",
              null,
              () => controller.startClient(booking['docId']),
              isGold: true,
            ),
          ],
          if (status == 'in-progress') ...[
            const SizedBox(height: 14),
            _btn(
              "✓ Tugatish",
              AppTheme.success,
              () => controller.completeClient(booking['docId']),
              isSolid: true,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 50.ms).slideX(begin: 0.02);
  }

  Widget _btn(
    String text,
    Color? color,
    VoidCallback onTap, {
    bool isGold = false,
    bool isSolid = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isGold ? AppTheme.goldGradient : null,
          color: isGold
              ? null
              : (isSolid ? color : color?.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: (isGold || isSolid) ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// TAB 3: NAVBAT (QUEUE) — 🔥 ENG MUHIM
// ═══════════════════════════════════════════
class _QueueTab extends StatelessWidget {
  final BarberDashboardController controller;
  const _QueueTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: BoxDecoration(
            gradient: AppTheme.darkGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "⏱ Navbat boshqaruvi",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Hozirgi va keyingi mijoz",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            // Get active queue: confirmed + in-progress
            final queue = controller.todayBookings
                .where(
                  (b) =>
                      b['status'] == 'confirmed' ||
                      b['status'] == 'in-progress',
                )
                .toList();
            final inProgress = queue
                .where((b) => b['status'] == 'in-progress')
                .toList();
            final waiting = queue
                .where((b) => b['status'] == 'confirmed')
                .toList();
            final currentClient = inProgress.isNotEmpty
                ? inProgress.first
                : null;
            final nextClient = waiting.isNotEmpty ? waiting.first : null;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── HOZIRGI MIJOZ ───
                  Text(
                    "Hozirgi mijoz",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (currentClient != null)
                    _buildQueueCard(currentClient, isActive: true)
                  else
                    _buildEmptyQueueCard(
                      "Hozir xizmat ko'rsatilmayapti",
                      Icons.person_off_rounded,
                    ),

                  const SizedBox(height: 28),

                  // ─── KEYINGI MIJOZ ───
                  Text(
                    "Keyingi mijoz",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (nextClient != null)
                    _buildQueueCard(nextClient, isNext: true)
                  else
                    _buildEmptyQueueCard(
                      "Navbatda kutayotgan yo'q",
                      Icons.hourglass_empty_rounded,
                    ),

                  const SizedBox(height: 28),

                  // ─── KUTISH NAVBATI ───
                  if (waiting.length > 1) ...[
                    Text(
                      "Kutish navbati (${waiting.length - 1})",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...waiting.skip(1).map((b) => _buildQueueCard(b)),
                  ],
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQueueCard(
    Map<String, dynamic> booking, {
    bool isActive = false,
    bool isNext = false,
  }) {
    final borderColor = isActive
        ? Colors.orange
        : (isNext
              ? AppTheme.primary
              : AppTheme.textLight.withValues(alpha: 0.2));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.orange : AppTheme.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isActive ? Icons.content_cut_rounded : Icons.person_rounded,
                  color: isActive ? Colors.orange : AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['client'] ?? 'Mijoz',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${booking['time'] ?? ''} • ${booking['service'] ?? 'Xizmat'}",
                      style: GoogleFonts.poppins(
                        color: AppTheme.textMedium,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "🔥 Jarayonda",
                    style: GoogleFonts.poppins(
                      color: Colors.orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          if (isActive)
            GestureDetector(
              onTap: () => controller.completeClient(booking['docId']),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    "✓ Tugatish",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            )
          else if (isNext)
            GestureDetector(
              onTap: () => controller.startClient(booking['docId']),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    "🔥 Boshlash",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.03);
  }

  Widget _buildEmptyQueueCard(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: AppTheme.textLight.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// TAB 4: XIZMATLAR
// ═══════════════════════════════════════════
class _ServicesTab extends StatelessWidget {
  const _ServicesTab();

  @override
  Widget build(BuildContext context) {
    final userService = Get.find<UserService>();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          decoration: BoxDecoration(
            gradient: AppTheme.darkGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "✂️ Xizmatlar",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Narx va davomiylikni boshqaring",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('barbers')
                .where('uid', isEqualTo: userService.currentUid)
                .snapshots(),
            builder: (context, barberSnapshot) {
              if (barberSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }
              final barberDocs = barberSnapshot.data?.docs ?? [];
              if (barberDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        size: 64,
                        color: AppTheme.textLight.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Sartarosh profili topilmadi",
                        style: GoogleFonts.poppins(
                          color: AppTheme.textMedium,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final barberDoc = barberDocs.first;
              final barberData = barberDoc.data() as Map<String, dynamic>;
              final isFemale = barberData['targetGender'] == 'female';

              // O'zgaruvchan standart xizmatlar ro'yxati (Global ro'yxat vazifasini bajaradi)
              final List<Map<String, dynamic>> standardServices = isFemale
                  ? [
                      {'name': 'Soch turmaklash', 'category': 'Asosiy'},
                      {'name': "Bo'yash / Ukladka", 'category': 'Qo\'shimcha'},
                      {'name': 'Soch + Makiyaj', 'category': 'Kompleks'},
                      {'name': 'Kechki turmak', 'category': 'Maxsus'},
                    ]
                  : [
                      {'name': 'Soch olish', 'category': 'Asosiy'},
                      {'name': 'Soqol olish', 'category': 'Asosiy'},
                      {'name': 'Soch + Soqol', 'category': 'Kompleks'},
                      {'name': 'Bolalar ukladkasi', 'category': 'Qo\'shimcha'},
                    ];

              final currentServices =
                  (barberData['services'] as List?)
                      ?.cast<Map<String, dynamic>>() ??
                  [];

              return Column(
                children: [
                  // Xizmatlar ro'yxati
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: standardServices.length,
                      itemBuilder: (context, index) {
                        final gSvc = standardServices[index];
                        final gName = gSvc['name'] as String;
                        final gCat = gSvc['category'] as String;

                        final existingIndex = currentServices.indexWhere(
                          (s) => s['name'] == gName,
                        );
                        final bool isEnabled = existingIndex != -1;
                        final existing = isEnabled
                            ? currentServices[existingIndex]
                            : <String, dynamic>{};

                        final priceCtrl = TextEditingController(
                          text: isEnabled ? existing['price']?.toString() : '',
                        );
                        final durationCtrl = TextEditingController(
                          text: isEnabled
                              ? existing['duration']?.toString()
                              : '',
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isEnabled
                                ? AppTheme.primary.withValues(alpha: 0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isEnabled
                                  ? AppTheme.primary.withValues(alpha: 0.3)
                                  : AppTheme.textLight.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        gCat,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppTheme.textMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: isEnabled,
                                    activeThumbColor: AppTheme.primary,
                                    activeTrackColor: AppTheme.primary
                                        .withValues(alpha: 0.5),
                                    onChanged: (val) async {
                                      final newServices =
                                          List<Map<String, dynamic>>.from(
                                            currentServices,
                                          );
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
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: priceCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: "Narxi (so'm)",
                                          labelStyle: GoogleFonts.poppins(
                                            fontSize: 12,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: durationCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: "Vaqti (daq)",
                                          labelStyle: GoogleFonts.poppins(
                                            fontSize: 12,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      final price =
                                          int.tryParse(
                                            priceCtrl.text.replaceAll('.', ''),
                                          ) ??
                                          0;
                                      final duration =
                                          int.tryParse(durationCtrl.text) ?? 30;

                                      final newServices =
                                          List<Map<String, dynamic>>.from(
                                            currentServices,
                                          );
                                      final idx = newServices.indexWhere(
                                        (s) => s['name'] == gName,
                                      );
                                      if (idx != -1) {
                                        newServices[idx]['price'] = price;
                                        newServices[idx]['duration'] = duration;
                                        await barberDoc.reference.update({
                                          'services': newServices,
                                        });
                                        Get.snackbar(
                                          "Saqlandi",
                                          "$gName narxi yangilandi ✅",
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: AppTheme.success,
                                          colorText: Colors.white,
                                          margin: const EdgeInsets.all(16),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      "Saqlash",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: AppTheme.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
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
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// TAB 5: BARBER PROFIL
// ═══════════════════════════════════════════
class _BarberProfileTab extends StatelessWidget {
  const _BarberProfileTab();

  @override
  Widget build(BuildContext context) {
    final userService = Get.find<UserService>();
    final controller = Get.find<BarberDashboardController>();
    return Column(
      children: [
        // Header with avatar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            gradient: AppTheme.darkGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => controller.uploadProfileImage(),
                  child: Obx(() {
                    final photoUrl = userService.photoUrl.value;

                    ImageProvider? imageProvider;
                    if (photoUrl.isNotEmpty) {
                      imageProvider = CachedNetworkImageProvider(photoUrl);
                    }

                    return Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white24,
                            backgroundImage: imageProvider,
                            child: imageProvider == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 36,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.gold,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryDark,
                                width: 2,
                              ),
                            ),
                            child: controller.isUploadingPhoto.value
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Text(
                    userService.name.value,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "✂️ Sartarosh",
                    style: GoogleFonts.poppins(
                      color: AppTheme.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPortfolioSection(controller),
                const SizedBox(height: 16),
                _profileMenuItem(
                  Icons.person_rounded,
                  "Ma'lumotlarim",
                  () => Get.toNamed('/profile'),
                ),
                _profileMenuItem(
                  Icons.access_time_rounded,
                  "Ish vaqti sozlamalari",
                  () {
                    Get.snackbar(
                      "Tez kunda",
                      "Ish vaqti sozlamalari tez orada qo'shiladi",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                _profileMenuItem(
                  Icons.settings_rounded,
                  "Sozlamalar",
                  () => Get.toNamed('/profile'),
                ),
                _profileMenuItem(Icons.help_outline_rounded, "Yordam", () {
                  Get.toNamed('/support-chat');
                }),
                _profileMenuItem(
                  Icons.info_outline_rounded,
                  "Ilova versiyasi",
                  () {
                    Get.find<UpdateService>().checkUpdate();
                  },
                ),
                const SizedBox(height: 12),
                // Switch to client mode
                GestureDetector(
                  onTap: () {
                    userService.toggleBarberMode();
                    Get.offAllNamed('/home');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horiz_rounded, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          "Mijoz rejimiga o'tish",
                          style: GoogleFonts.poppins(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Logout
                GestureDetector(
                  onTap: () {
                    Get.dialog(
                      AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text("Chiqish"),
                        content: const Text(
                          "Rostdan ham tizimdan chiqmoqchimisiz?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text("Yo'q"),
                          ),
                          TextButton(
                            onPressed: () {
                              userService.logout();
                              Get.back();
                              Get.offAllNamed('/onboarding');
                            },
                            child: const Text(
                              "Ha, chiqish",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        "Tizimdan chiqish",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioSection(BarberDashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Mening Portfoliom",
              style: GoogleFonts.poppins(
                color: AppTheme.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Obx(
              () => controller.isUploadingPortfolio.value
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: Obx(() {
            final images = controller.portfolioImages;
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length + 1,
              itemBuilder: (context, index) {
                if (index == images.length) {
                  // Add new photo button
                  return GestureDetector(
                    onTap: () => controller.uploadPortfolioImage(),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.05),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_a_photo_rounded,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                      ),
                    ),
                  );
                }

                // Photo item
                final url = images[index];
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          Get.dialog(
                            AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text("O'chirish"),
                              content: const Text(
                                "Bu rasmni portfoliodan o'chirasizmi?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text("Yo'q"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                    controller.deletePortfolioImage(url);
                                  },
                                  child: const Text(
                                    "Ha",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _profileMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }
}
