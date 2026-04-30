import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/my_bookings_controller.dart';
import '../../../../core/theme/app_theme.dart';

class MyBookingsView extends GetView<MyBookingsController> {
  const MyBookingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            "Mening bronlarim",
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
            onPressed: () => Get.back(),
          ),
          bottom: TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMedium,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: "Faol"),
              Tab(text: "Tarix"),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    "Bronlar yuklanmoqda...",
                    style: GoogleFonts.poppins(
                      color: AppTheme.textMedium,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return TabBarView(children: [_buildActiveList(), _buildPastList()]);
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ACTIVE BOOKINGS - WITH QUEUE POSITION
  // ═══════════════════════════════════════════
  Widget _buildActiveList() {
    return Obx(() {
      final items = controller.activeBookings;
      if (items.isEmpty) {
        return _buildEmptyState(
          icon: Icons.event_available_rounded,
          title: "Hozircha faol bron yo'q",
          subtitle: "Yangi bron yaratish uchun bosh sahifaga o'ting",
        );
      }

      return RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final b = items[index];
            return _buildActiveBookingCard(b, index);
          },
        ),
      );
    });
  }

  Widget _buildActiveBookingCard(Map<String, dynamic> b, int index) {
    final status = b['status'] ?? 'pending';
    final bookingId = b['id'] ?? '';

    return Obx(() {
      final queuePos = controller.queuePositions[bookingId] ?? 0;
      final queueTotal = controller.queueTotals[bookingId] ?? 0;
      final estimatedWait = controller.getEstimatedWait(b);

      return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: status == 'in-progress'
                    ? AppTheme.primary.withValues(alpha: 0.4)
                    : _statusColor(status).withValues(alpha: 0.15),
                width: status == 'in-progress' ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _statusColor(status).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Queue Position Header ──
                if (queuePos > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: status == 'in-progress'
                            ? [
                                AppTheme.primary.withValues(alpha: 0.12),
                                AppTheme.primary.withValues(alpha: 0.04),
                              ]
                            : [
                                AppTheme.gold.withValues(alpha: 0.12),
                                AppTheme.gold.withValues(alpha: 0.04),
                              ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: status == 'in-progress'
                                ? LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.accent],
                                  )
                                : LinearGradient(
                                    colors: [
                                      AppTheme.gold,
                                      AppTheme.gold.withValues(alpha: 0.7),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: status == 'in-progress'
                                ? Icon(
                                    Icons.content_cut_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : Text(
                                    "$queuePos",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status == 'in-progress'
                                    ? "Hozir xizmat ko'rsatilmoqda"
                                    : "Navbat: $queuePos / $queueTotal",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                status == 'in-progress'
                                    ? "Usta sizga xizmat qilmoqda ✂️"
                                    : "Kutish: $estimatedWait",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (status == 'in-progress')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "LIVE",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                // ── Main Content ──
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _statusIcon(status),
                              color: _statusColor(status),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b['service'] ?? 'Xizmat',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      size: 14,
                                      color: AppTheme.textLight,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        b['barberName'] ?? '—',
                                        style: GoogleFonts.poppins(
                                          color: AppTheme.textMedium,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: GoogleFonts.poppins(
                                color: _statusColor(status),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── Separator ──
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.textLight.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Date/Time/Price ──
                      Row(
                        children: [
                          _infoChip(
                            Icons.calendar_month_rounded,
                            b['date'] ?? '—',
                          ),
                          const SizedBox(width: 8),
                          _infoChip(Icons.access_time_rounded, b['time'] ?? ''),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${((b['price'] ?? 0) ~/ 1000)} ming",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── Duration info ──
                      if ((b['durationMinutes'] ?? 0) > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.timelapse_rounded,
                              size: 14,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Davomiyligi: ${b['durationMinutes']} daqiqa",
                              style: GoogleFonts.poppins(
                                color: AppTheme.textMedium,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ── Info Banner ──
                      if (status == 'pending') ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFD97706,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFFD97706,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.hourglass_top_rounded,
                                size: 18,
                                color: const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Usta tasdiqlanishini kutmoqda...",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFD97706),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (status == 'confirmed') ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.success.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: AppTheme.success,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Tasdiqlangan. Iltimos o'z vaqtida keling.",
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Cancel Button ──
                      if (status == 'pending' || status == 'confirmed') ...[
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () {
                            Get.dialog(
                              AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  "Bekor qilish",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                content: Text(
                                  "Haqiqatan ham ushbu bronni bekor qilmoqchimisiz?",
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: Text(
                                      "Yo'q",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Get.back();
                                      controller.cancelBooking(
                                        b['id'],
                                        b['date'] ?? '',
                                        b['time'] ?? '',
                                      );
                                    },
                                    child: Text(
                                      "Ha, bekor qilish",
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.danger,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.danger.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Bekor qilish",
                                style: GoogleFonts.poppins(
                                  color: AppTheme.danger,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 80 + (index * 60)))
          .slideY(begin: 0.04);
    });
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMedium),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // PAST BOOKINGS
  // ═══════════════════════════════════════════
  Widget _buildPastList() {
    return Obx(() {
      final items = controller.pastBookings;
      if (items.isEmpty) {
        return _buildEmptyState(
          icon: Icons.history_rounded,
          title: "Bronlar tarixi bo'sh",
          subtitle: "Tugatilgan bronlar bu yerda ko'rinadi",
        );
      }

      return RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final b = items[index];
            final status = b['status'] ?? 'pending';
            return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor(status).withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _statusIcon(status),
                              color: _statusColor(status),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b['service'] ?? 'Xizmat',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  b['barberName'] ?? '—',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textMedium,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: GoogleFonts.poppins(
                                color: _statusColor(status),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Get.dialog(
                                AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Text("Tarixdan o'chirish"),
                                  content: Text(
                                    "Haqiqatan ham bu yozuvni tarixdan yashirmoqchimisiz?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: Text("Yo'q"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Get.back();
                                        controller.deleteHistoryItem(b['id']);
                                      },
                                      child: Text(
                                        "Ha, o'chirish",
                                        style: TextStyle(
                                          color: AppTheme.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: AppTheme.danger,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: AppTheme.background),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 14,
                                color: AppTheme.textLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${b['date'] ?? '—'} • ${b['time'] ?? ''}",
                                style: GoogleFonts.poppins(
                                  color: AppTheme.textMedium,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${((b['price'] ?? 0) ~/ 1000)} ming so'm",
                            style: GoogleFonts.poppins(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => controller.rebook(b),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primary, AppTheme.accent],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "Qayta bron qilish",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 + (index * 50)))
                .slideY(begin: 0.05);
          },
        ),
      );
    });
  }

  // ═══════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 56,
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════
  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppTheme.success;
      case 'in-progress':
        return AppTheme.primary;
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.danger;
      case 'no-show':
      case 'penalty':
        return AppTheme.textMedium;
      default:
        return const Color(0xFFD97706);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'in-progress':
        return Icons.hourglass_top_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
      case 'penalty':
        return Icons.cancel_outlined;
      case 'no-show':
        return Icons.person_off_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Kutilmoqda';
      case 'confirmed':
        return 'Tasdiqlangan';
      case 'in-progress':
        return 'Jarayonda';
      case 'completed':
        return 'Tugallangan';
      case 'cancelled':
        return 'Bekor qilindi';
      case 'penalty':
        return 'Kech bekor';
      case 'no-show':
        return 'Kelmadi';
      default:
        return status;
    }
  }
}
