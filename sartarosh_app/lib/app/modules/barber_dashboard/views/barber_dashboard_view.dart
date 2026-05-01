import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/barber_dashboard_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/update_service.dart';
import '../../notifications/controllers/notifications_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BarberDashboardView extends GetView<BarberDashboardController> {
  const BarberDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentTab = 0.obs;
    final pageController = PageController();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (currentTab.value == 0) {
            Get.offAllNamed('/home');
          } else {
            pageController.jumpToPage(0);
            currentTab.value = 0;
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: PageView(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => currentTab.value = i,
          children: [
            _DashboardTab(controller: controller),
            _BarberBookingsTab(controller: controller),
            _BarberProfileTab(controller: controller),
          ],
        ),
        bottomNavigationBar: Obx(
          () => _buildBottomNav(currentTab, pageController),
        ),
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
                Icons.person_rounded,
                "Profil",
                currentTab.value == 2,
                () {
                  pageCtrl.jumpToPage(2);
                  currentTab.value = 2;
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
          SliverToBoxAdapter(child: _buildQueueLimitAndStatus()),
          SliverToBoxAdapter(child: _buildQueueSection()),
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
            Obx(() {
              final notifController =
                  Get.isRegistered<NotificationsController>()
                  ? Get.find<NotificationsController>()
                  : Get.put(NotificationsController());

              final unread = notifController.unreadCount.value;
              return GestureDetector(
                onTap: () => Get.toNamed('/notifications'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                        .animate(
                          target: unread > 0 ? 1 : 0,
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .shimmer(duration: 1500.ms)
                        .shake(
                          hz: 4,
                          curve: Curves.easeInOutCubic,
                          duration: 2000.ms,
                        ),

                    if (unread > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child:
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.darkBg,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                "$unread",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ).animate().scale(
                              duration: 400.ms,
                              curve: Curves.elasticOut,
                            ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Row(
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
                "Bugun",
                "${controller.todayEarnings.value}",
                AppTheme.gold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                Icons.account_balance_wallet_rounded,
                "Bu hafta",
                "${controller.weeklyEarnings.value}",
                const Color(0xFF5E60CE), // Deep Purple
              ),
              const SizedBox(width: 12),
              _statCard(
                Icons.savings_rounded,
                "Bu oy",
                "${controller.monthlyEarnings.value}",
                const Color(0xFF6930C3), // Vibrant Violet
              ),
            ],
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

  Widget _buildQueueLimitAndStatus() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
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
          children: [
            // Queue Limit Section
            Padding(
              padding: const EdgeInsets.all(16),
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove,
                            size: 18,
                            color: AppTheme.textMedium,
                          ),
                          onPressed: () => controller.decrementLimit(),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        Obx(
                          () => Text(
                            "${controller.queueLimit.value}",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.gold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                            color: AppTheme.textMedium,
                          ),
                          onPressed: () => controller.incrementLimit(),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(color: const Color(0xFFFAF6F0), height: 1),

            // Active Status Section
            Obx(() {
              final isActive = controller.isActive.value;
              return Container(
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.success.withValues(alpha: 0.05)
                      : AppTheme.danger.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.success : AppTheme.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isActive
                                ? "Siz hozir ishdasiz"
                                : "Siz hozir ishda emassiz",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            isActive
                                ? "Yangi navbatlarni qabul qilasiz"
                                : "Sizga yangi navbatlar kelmaydi",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.toggleActiveStatus,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.danger : AppTheme.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? "Ishni to'xtatish" : "Ishni boshlash",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.03);
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

  Widget _buildQueueSection() {
    return Obx(() {
      final current = controller.currentClient.value;
      final next = controller.nextClient.value;
      if (current == null && next == null) return const SizedBox();
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "📋 Navbat",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              if (current != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Hozir: ${current['client'] ?? 'Mijoz'} ${current['isQueue'] == true ? '(Jonli navbat)' : '— ${current['time'] ?? ''}'}",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (current['isQueue'] == true) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            controller.completeQueueClient(current['docId']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "✓ Tugatish",
                            style: GoogleFonts.poppins(
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],
              if (next != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Navbatdagi: ${next['client'] ?? 'Mijoz'} ${next['isQueue'] == true ? '(Jonli navbat)' : '— ${next['time'] ?? ''}'}",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (next['isQueue'] == true) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => controller.skipQueueClient(next['docId']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "O'tkazish",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => controller.startQueueClient(next['docId']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "🔥 Boshlash",
                            style: GoogleFonts.poppins(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ).animate().fadeIn(delay: 320.ms);
    });
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'pending';
    Color statusColor;
    String statusText;
    switch (status) {
      case 'pending':
        statusColor = const Color(0xFFD97706);
        statusText = "Kutilmoqda";
        break;
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
        statusColor = AppTheme.danger;
        statusText = "Bekor qilingan";
        break;
      default:
        statusColor = AppTheme.textMedium;
        statusText = status;
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
          // Payment info row
          if (booking['paymentType'] == 'cash' &&
              booking['paymentStatus'] == 'unpaid' &&
              status != 'completed' &&
              status != 'cancelled')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    "Naqd to'lov — hali to'lanmagan",
                    style: GoogleFonts.poppins(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
                    AppTheme.danger,
                    () => controller.rejectBooking(booking['docId']),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'confirmed') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Obx(() {
                    // Re-evaluate canStart reactively
                    controller.todayBookings.length; // trigger rebuild
                    final canStart = controller.canStartBooking(booking);
                    return _actionBtn(
                      "🔥 Boshlash",
                      null,
                      canStart
                          ? () => controller.startClient(booking['docId'])
                          : null,
                      isGold: canStart,
                    );
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionBtn(
                    "❌ Kelmadi",
                    Colors.grey,
                    () => controller.markNoShow(booking['docId']),
                  ),
                ),
              ],
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
    VoidCallback? onTap, {
    bool isGold = false,
    bool isSolid = false,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
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
      case 'pending':
        statusColor = const Color(0xFFD97706);
        statusText = "Kutilmoqda";
        statusIcon = Icons.access_time_rounded;
        break;
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
        statusColor = AppTheme.danger;
        statusText = "Bekor qilingan";
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppTheme.textMedium;
        statusText = status;
        statusIcon = Icons.help_outline_rounded;
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
                    AppTheme.danger,
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
// TAB 5: BARBER PROFIL
// ═══════════════════════════════════════════
class _BarberProfileTab extends StatelessWidget {
  final BarberDashboardController controller;
  const _BarberProfileTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    UserService userService;
    try {
      userService = Get.find<UserService>();
    } catch (_) {
      userService = Get.put(UserService());
    }
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
                  Icons.content_cut_rounded,
                  "Xizmatlarim va Narxlar",
                  () => Get.toNamed('/barber-services'),
                ),
                _profileMenuItem(
                  Icons.access_time_rounded,
                  "Ish vaqti sozlamalari",
                  () => _showWorkingHours(context),
                ),
                _profileMenuItem(Icons.help_outline_rounded, "Yordam", () {
                  Get.toNamed('/support-chat');
                }),
                _profileMenuItem(
                  Icons.info_outline_rounded,
                  "Ilova versiyasi",
                  () {
                    final updateService = Get.find<UpdateService>();
                    Get.dialog(
                      AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text("Ilova versiyasi"),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Sartarosh Pro",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Versiya: ${updateService.currentVersion}",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text("Yopish"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Get.back();
                              updateService.checkUpdate();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Yangilanishni tekshirish",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
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
                              style: TextStyle(color: AppTheme.danger),
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
                                    style: TextStyle(color: AppTheme.danger),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.danger,
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

  void _showWorkingHours(BuildContext context) async {
    // 1. Fetch current hours
    Get.dialog(
      Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      barrierDismissible: false,
    );
    final hours = await controller.getWorkingHours();
    Get.back(); // close loading dialog

    if (!context.mounted) return;

    final openTime = RxString(hours['open'] ?? "09:00");
    final closeTime = RxString(hours['close'] ?? "21:00");

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.paddingOf(context).bottom + 72, // Lift it higher!
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  color: AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Ish vaqtini sozlash",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              "Ochilish vaqti",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final initial = TimeOfDay(
                  hour: int.parse(openTime.value.split(':')[0]),
                  minute: int.parse(openTime.value.split(':')[1]),
                );
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initial,
                );
                if (picked != null) {
                  openTime.value =
                      "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Obx(
                  () => Text(
                    openTime.value,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Yopilish vaqti",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final initial = TimeOfDay(
                  hour: int.parse(closeTime.value.split(':')[0]),
                  minute: int.parse(closeTime.value.split(':')[1]),
                );
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initial,
                );
                if (picked != null) {
                  closeTime.value =
                      "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Obx(
                  () => Text(
                    closeTime.value,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 48,
            ), // Push save button higher relative to inputs
            GestureDetector(
              onTap: () {
                controller.updateWorkingHours(openTime.value, closeTime.value);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "Saqlash",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
