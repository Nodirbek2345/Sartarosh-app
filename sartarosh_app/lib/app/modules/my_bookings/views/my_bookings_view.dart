import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/my_bookings_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';

class MyBookingsView extends GetView<MyBookingsController> {
  const MyBookingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isBarber = controller.isBarberMode;
      if (isBarber) {
        return _buildBarberMode();
      } else {
        return _buildClientMode();
      }
    });
  }

  // ═══════════════════════════════════════════
  // 🔥 CLIENT MODE — PRO BRONLAR DESIGN
  // ═══════════════════════════════════════════
  Widget _buildClientMode() {
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
                      // Barber mode toggle (if user is also a barber)
                      Obx(() {
                        final userService = Get.find<UserService>();
                        if (userService.userRole.value == 'barber') {
                          return GestureDetector(
                            onTap: () => userService.toggleBarberMode(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.content_cut_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Usta rejim",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
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
                return _buildEmptyState(
                  icon: Icons.calendar_today_rounded,
                  title: "📭 Bronlar topilmadi",
                  subtitle: "Bosh sahifadan sartarosh tanlab bron qiling",
                );
              }

              return RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: bookings.length,
                  itemBuilder: (_, i) =>
                      _buildClientBookingCard(bookings[i], i),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Client Booking Card (Premium Design) ──
  Widget _buildClientBookingCard(Map<String, dynamic> booking, int index) {
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

                // ── Cancel Button for pending/confirmed ──
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

                // ── Rebook Button for completed/cancelled ──
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

  // ═══════════════════════════════════════════
  // 🔥 BARBER MODE (existing design unchanged)
  // ═══════════════════════════════════════════
  Widget _buildBarberMode() {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            "Mijozlar bronlari",
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            Obx(() {
              final userService = Get.find<UserService>();
              if (userService.userRole.value == 'barber') {
                return IconButton(
                  icon: Icon(Icons.person_rounded, color: AppTheme.primary),
                  onPressed: () => userService.toggleBarberMode(),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        body: Column(
          children: [
            _buildBarberTopSection(),
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMedium,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                isScrollable: true,
                tabs: const [
                  Tab(text: "Kutilmoqda"),
                  Tab(text: "Tasdiqlangan"),
                  Tab(text: "Jarayonda"),
                  Tab(text: "Bajarildi"),
                ],
              ),
            ),
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
                return TabBarView(
                  children: [
                    _buildBarberPendingList(),
                    _buildBarberConfirmedList(),
                    _buildBarberInProgressList(),
                    _buildBarberCompletedList(),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 🔥 PRO BARBER DASHBOARD TOP SECTION
  // ═══════════════════════════════════════════
  Widget _buildBarberTopSection() {
    return Column(
      children: [
        // ── Stats Cards ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Obx(
            () => Column(
              children: [
                Row(
                  children: [
                    _statCard(
                      Icons.people_rounded,
                      "Mijozlar",
                      "${controller.todayClientsCount.value}",
                      AppTheme.primary,
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      Icons.check_circle_rounded,
                      "Bajarildi",
                      "${controller.completedCount.value}",
                      AppTheme.success,
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      Icons.monetization_on_rounded,
                      "Bugun",
                      "${controller.todayEarnings.value}",
                      AppTheme.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statCard(
                      Icons.account_balance_wallet_rounded,
                      "Bu hafta",
                      "${controller.weeklyEarnings.value}",
                      const Color(0xFF5E60CE),
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      Icons.savings_rounded,
                      "Bu oy",
                      "${controller.monthlyEarnings.value}",
                      const Color(0xFF6930C3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

        // ── Queue Limit & Status ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                // Queue Limit
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
                              onPressed: controller.decrementLimit,
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
                              onPressed: controller.incrementLimit,
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

                // Active Status
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
                            color: isActive
                                ? AppTheme.success
                                : AppTheme.danger,
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
                              color: isActive
                                  ? AppTheme.danger
                                  : AppTheme.success,
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
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.03),

        // ── Navbat Section ──
        Obx(() {
          final current = controller.currentClient.value;
          final next = controller.nextClient.value;
          if (current == null && next == null) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                  if (current != null)
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
                            "Navbatdagi: ${current['client'] ?? 'Mijoz'} — ${current['time'] ?? ''}",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (next != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Keyingi: ${next['client'] ?? 'Mijoz'} — ${next['time'] ?? ''}",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.03);
        }),

        const SizedBox(height: 8),
      ],
    );
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

  // ═══════════════════════════════════════════
  // BARBER BOOKINGS TABS
  // ═══════════════════════════════════════════

  Widget _buildBarberPendingList() {
    return _buildBarberList(
      controller.barberPending,
      "Kutilayotgan bronlar yo'q",
      Icons.hourglass_empty_rounded,
      subtitle: "Yangi bron kelganda bu yerda ko'rinadi",
    );
  }

  Widget _buildBarberConfirmedList() {
    return _buildBarberList(
      controller.barberConfirmed,
      "Tasdiqlangan bronlar yo'q",
      Icons.check_circle_outline_rounded,
      subtitle: "Tasdiqlangan mijozlar bu yerda ko'rinadi",
    );
  }

  Widget _buildBarberInProgressList() {
    return _buildBarberList(
      controller.barberInProgress,
      "Hozircha jarayondagi mijoz yo'q",
      Icons.content_cut_rounded,
      subtitle: "Mijozga xizmat boshlaganda bu yer to'ldiriladi",
    );
  }

  Widget _buildBarberCompletedList() {
    return _buildBarberList(
      controller.barberCompleted,
      "Tugallangan bronlar yo'q",
      Icons.done_all_rounded,
      subtitle: "Mijozlar bilan ishlaganingizda bu yer to'ldiriladi",
    );
  }

  Widget _buildBarberList(
    RxList<Map<String, dynamic>> items,
    String emptyMsg,
    IconData icon, {
    String subtitle = "Ushbu ro'yxatda hozircha bronlar yo'q",
  }) {
    return Obx(() {
      if (items.isEmpty) {
        return _buildEmptyState(
          icon: icon,
          title: emptyMsg,
          subtitle: subtitle,
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
            return _buildBarberBookingCard(
              b,
            ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.05);
          },
        ),
      );
    });
  }

  Widget _buildBarberBookingCard(Map<String, dynamic> b) {
    final status = b['status'] ?? 'pending';
    final clientName = b['client'] ?? 'Mijoz';
    final service = b['service'] ?? 'Xizmat';
    final date = b['date'] ?? '';
    final time = b['time'] ?? '';
    final docId = b['id'] ?? '';
    final price = b['price'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor(status).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person_rounded, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      service,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textMedium,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(status),
                  style: GoogleFonts.poppins(
                    color: _statusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date/Time/Price row
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
          const SizedBox(height: 12),
          if (status == 'pending')
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    "Rad etish",
                    AppTheme.danger,
                    () => controller.rejectBooking(docId),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionBtn(
                    "Qabul qilish",
                    AppTheme.success,
                    () => controller.acceptBooking(docId),
                  ),
                ),
              ],
            ),
          if (status == 'confirmed')
            Row(
              children: [
                Expanded(
                  child: _goldActionBtn(
                    "🔥 Boshlash",
                    () => controller.startClient(docId),
                  ),
                ),
              ],
            ),
          if (status == 'in-progress')
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    "✓ Tugatish",
                    AppTheme.success,
                    () => controller.completeClient(docId),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _goldActionBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
