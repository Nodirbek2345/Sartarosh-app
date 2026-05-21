import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/my_bookings_controller.dart';
import '../../../../core/theme/app_theme.dart';

/// MyBookingsView — FAQAT MIJOZ uchun.
/// Sartaroshlar BarberDashboardView ga o'tkaziladi.
class MyBookingsView extends GetView<MyBookingsController> {
  const MyBookingsView({super.key});

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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ── Premium Dark Header ──
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
                    "📅 Bronlar",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Mening barcha bronlarim",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Filter Chips ──
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

          // ── Booking List ──
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        "Tizim tayyorlanmoqda...",
                        style: GoogleFonts.poppins(
                          color: AppTheme.textMedium,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
              var bookings = controller.allClientBookings.toList();
              if (selectedFilter.value != 'all') {
                bookings = bookings
                    .where((b) => b['status'] == selectedFilter.value)
                    .toList();
              }
              if (bookings.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 600));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: bookings.length,
                  itemBuilder: (_, i) => _buildBookingCard(bookings[i], i),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 64,
            color: AppTheme.textLight.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "📭 Bronlar topilmadi",
            style: GoogleFonts.poppins(
              color: AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Bosh sahifadan sartarosh tanlab bron qiling",
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Get.offAllNamed('/home'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "Bosh sahifaga o'tish",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  // ── Client Booking Card ──
  Widget _buildBookingCard(Map<String, dynamic> booking, int index) {
    final status = booking['status'] ?? 'pending';
    final statusColor = _statusColor(status);
    final statusText = _statusLabel(status);
    final statusIcon = _statusIcon(status);
    final date = booking['date'] ?? '';
    final time = booking['time'] ?? '';
    final price = booking['price'] ?? 0;
    final bookingId = booking['id'] ?? '';

    return Obx(() {
      final queuePos = controller.queuePositions[bookingId] ?? 0;

      return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: status == 'in-progress'
                  ? Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      width: 2,
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
                // ── Header: icon + barber name + status badge ──
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
                            child: Icon(
                              statusIcon,
                              color: statusColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking['barberName'] ?? 'Usta',
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

                // ── Date / Time / Price Row ──
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

                // ── Queue position info ──
                if (queuePos > 0 &&
                    (status == 'confirmed' || status == 'pending')) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 16,
                          color: AppTheme.gold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Navbat: $queuePos / ${controller.queueTotals[bookingId] ?? 0}  •  Kutish: ${controller.getEstimatedWait(booking)}",
                          style: GoogleFonts.poppins(
                            color: AppTheme.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── In-progress live indicator ──
                if (status == 'in-progress') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Usta sizga xizmat qilmoqda ✂️",
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
                                  booking['id'],
                                  booking['date'] ?? '',
                                  booking['time'] ?? '',
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
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

                // ── Rebook Button ──
                if (status == 'completed' ||
                    status == 'cancelled' ||
                    status == 'no-show' ||
                    status == 'penalty') ...[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => controller.rebook(booking),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(12),
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
                          "🔄 Qayta bron qilish",
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
              ],
            ),
          )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 60 + (index * 50)))
          .slideY(begin: 0.04);
    });
  }

  // ── Helpers ──
  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'confirmed':
        return AppTheme.primary;
      case 'in-progress':
        return Colors.orange;
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
      case 'no-show':
      case 'penalty':
        return AppTheme.danger;
      default:
        return AppTheme.textMedium;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return "Kutilmoqda";
      case 'confirmed':
        return "Tasdiqlangan";
      case 'in-progress':
        return "Jarayonda";
      case 'completed':
        return "Tugatilgan";
      case 'cancelled':
        return "Bekor qilingan";
      case 'no-show':
        return "Kelmadi";
      case 'penalty':
        return "Jarimali";
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'in-progress':
        return Icons.hourglass_top_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
      case 'no-show':
      case 'penalty':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
