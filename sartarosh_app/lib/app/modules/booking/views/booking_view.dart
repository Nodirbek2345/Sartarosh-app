import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/booking_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/image_helper.dart';

class BookingView extends GetView<BookingController> {
  const BookingView({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.isFemale ? AppTheme.darkBg : Color(0xFF0F1120);
    final cardColor = AppTheme.isFemale ? AppTheme.darkCard : Color(0xFF181A2E);
    final goldColor = AppTheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── PREMIUM APPBAR ───
            _buildPremiumAppBar(goldColor, bgColor),
            // ─── STEP PROGRESS ───
            _buildStepIndicator(goldColor),
            SizedBox(height: 8),
            // ─── BODY ───
            Expanded(
              child: Obx(() {
                if (controller.currentStep.value == 0) {
                  return _step1Barbers(bgColor, cardColor, goldColor);
                } else {
                  return _step2BookingForm(
                    bgColor,
                    cardColor,
                    goldColor,
                    context,
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // PREMIUM APPBAR
  // ═══════════════════════════════════════════════════════
  Widget _buildPremiumAppBar(Color gold, Color bg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (controller.currentStep.value > 0) {
                controller.prevStep();
              } else {
                Get.back();
              }
            },
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gold.withValues(alpha: 0.2)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: gold,
                size: 18,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bron qilish",
                  style: GoogleFonts.playfairDisplay(
                    color: gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Obx(
                  () => Text(
                    controller.currentStep.value == 0
                        ? "Usta tanlang"
                        : "Sana va vaqt",
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Service badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gold.withValues(alpha: 0.2),
                  gold.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.content_cut_rounded, color: gold, size: 14),
                SizedBox(width: 6),
                Text(
                  controller.serviceName.length > 10
                      ? "${controller.serviceName.substring(0, 10)}..."
                      : controller.serviceName,
                  style: GoogleFonts.poppins(
                    color: gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ═══════════════════════════════════════════════════════
  // STEP INDICATOR (PREMIUM ANIMATED)
  // ═══════════════════════════════════════════════════════
  Widget _buildStepIndicator(Color gold) {
    return Obx(() {
      final step = controller.currentStep.value;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _stepDot(0, step, gold, "Usta", Icons.person_rounded),
            _stepLine(step >= 1, gold),
            _stepDot(1, step, gold, "Bron", Icons.calendar_today_rounded),
          ],
        ),
      );
    }).animate().fadeIn(delay: 200.ms);
  }

  Widget _stepDot(
    int index,
    int current,
    Color gold,
    String label,
    IconData icon,
  ) {
    final isActive = current >= index;
    final isCurrent = current == index;
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: isCurrent ? 44 : 36,
            height: isCurrent ? 44 : 36,
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [gold, gold.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isActive ? null : Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: gold.withValues(alpha: 0.4),
                        blurRadius: 12,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isActive ? Color(0xFF0F1120) : Colors.white30,
              size: isCurrent ? 20 : 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: isActive ? gold : Colors.white30,
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepLine(bool isActive, Color gold) {
    return Container(
      width: 60,
      height: 2,
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(colors: [gold, gold.withValues(alpha: 0.3)])
            : null,
        color: isActive ? null : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // STEP 1: BARBER SELECT (PREMIUM)
  // ═══════════════════════════════════════════════════════
  Widget _step1Barbers(Color bg, Color card, Color gold) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          // Search-style header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gold.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: Colors.white30, size: 20),
                SizedBox(width: 12),
                Obx(
                  () => Text(
                    "${controller.barbers.length} ta usta topildi",
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "⭐ Reyting",
                    style: GoogleFonts.poppins(
                      color: gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
          SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.barbers.isEmpty) {
                return SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_search_rounded,
                          color: gold.withValues(alpha: 0.5),
                          size: 48,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Hozircha ustalar topilmadi",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Yaqin hududlardan ustalarni ko'rishingiz mumkin",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: card,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: gold.withValues(alpha: 0.3),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon: Icon(
                                Icons.location_on_rounded,
                                size: 18,
                                color: gold,
                              ),
                              label: Text(
                                "Hududni o'zgartirish",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () => Get.toNamed('/region'),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: card,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon: controller.isRefreshingBarbers.value
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                "Yangilash",
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                              onPressed: () => controller.refreshBarbers(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),
                      if (controller.suggestedBarbers.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "⭐ Tavsiya etilgan ustalar",
                            style: GoogleFonts.poppins(
                              color: gold,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        ...controller.suggestedBarbers.map(
                          (b) => Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: _buildBarberCardWidget(
                              b,
                              controller.selectedBarber.value?['id'] == b['id'],
                              b['isActive'] == true,
                              card,
                              gold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn();
              }

              return ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: controller.barbers.length,
                itemBuilder: (context, index) {
                  final b = controller.barbers[index];
                  final sel = controller.selectedBarber.value?['id'] == b['id'];
                  final isActive = b['isActive'] == true;

                  return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _buildBarberCardWidget(
                          b,
                          sel,
                          isActive,
                          card,
                          gold,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 150 + (index * 60)))
                      .slideX(begin: 0.05, end: 0);
                },
              );
            }),
          ),
          _premiumBtn(gold, "Davom etish →", () => controller.nextStep()),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // STEP 2: BOOKING FORM (PREMIUM)
  // ═══════════════════════════════════════════════════════

  String _getMonthName(int month) {
    const months = [
      'Yanvar',
      'Fevral',
      'Mart',
      'Aprel',
      'May',
      'Iyun',
      'Iyul',
      'Avgust',
      'Sentabr',
      'Oktabr',
      'Noyabr',
      'Dekabr',
    ];
    return months[month - 1];
  }

  Widget _step2BookingForm(
    Color bg,
    Color card,
    Color gold,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── SELECTED BARBER MINI CARD ───
          Obx(() {
            final b = controller.selectedBarber.value;
            if (b == null) return SizedBox();
            return Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gold.withValues(alpha: 0.12),
                    gold.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gold.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: ImageHelper.getBarberImage(
                          b['image']?.toString(),
                          b['id']?.toString() ?? 'unknown',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['name'] ?? 'Usta',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "⭐ ${b['rating'] ?? 5.0}  •  ${b['experience'] ?? 1} yil tajriba",
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.prevStep(),
                    child: Text(
                      "O'zgartirish",
                      style: GoogleFonts.poppins(
                        color: gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn();
          }),

          // ─── CALENDAR SECTION ───
          _sectionHeader(gold, "📅 Sana tanlang", "Istagan kuningizni bosing"),
          SizedBox(height: 8),
          // Month navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(() {
                final vm = controller.viewingMonth.value;
                final now = DateTime.now();
                final isCurrentMonth =
                    vm.year == now.year && vm.month == now.month;
                return Row(
                  children: [
                    GestureDetector(
                      onTap: isCurrentMonth
                          ? null
                          : () => controller.prevMonth(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: gold.withValues(
                            alpha: isCurrentMonth ? 0.05 : 0.15,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: isCurrentMonth ? Colors.white24 : gold,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      "${_getMonthName(vm.month)} ${vm.year}",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => controller.nextMonth(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: gold,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ).animate().fadeIn(delay: 100.ms),
          SizedBox(height: 12),
          _buildCalendarCard(card, gold),

          SizedBox(height: 24),

          // ─── TIME SLOTS ───
          _sectionHeader(
            gold,
            "🕐 Vaqt tanlang",
            "Bo'sh vaqtlardan birini tanlang",
          ),
          SizedBox(height: 12),
          _buildTimeSlots(card, gold),

          SizedBox(height: 24),

          // ─── SERVICE SUMMARY CARD ───
          _sectionHeader(gold, "📋 Xulosa", "Bron ma'lumotlarini tekshiring"),
          SizedBox(height: 12),
          _buildServiceInfoCard(card, gold),

          SizedBox(height: 24),

          // ─── PAYMENT METHOD ───
          _sectionHeader(
            gold,
            "💳 To'lov usuli",
            "To'lov qanday amalga oshiriladi?",
          ),
          SizedBox(height: 12),
          _buildPaymentMethodSelector(card, gold, context),

          SizedBox(height: 24),

          // ─── CONFIRM BUTTON ───
          Obx(
            () => _premiumBtn(
              gold,
              controller.isSubmitting.value
                  ? "Yuklanmoqda..."
                  : "✓ Bronni tasdiqlash",
              controller.isSubmitting.value ||
                      controller.selectedTime.value.isEmpty
                  ? null
                  : () => controller.confirmBooking(),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionHeader(Color gold, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.white30, fontSize: 12),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  // ═══════════════════════════════════════════════════════
  // CALENDAR CARD
  // ═══════════════════════════════════════════════════════
  Widget _buildCalendarCard(Color card, Color gold) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.poppins(
                          color: gold.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 12),
          Obx(() {
            DateTime currentDate = controller.selectedDate.value;
            DateTime vm = controller.viewingMonth.value;
            DateTime firstDayOfMonth = DateTime(vm.year, vm.month, 1);
            int offset = firstDayOfMonth.weekday - 1;
            int daysInMonth = DateTime(vm.year, vm.month + 1, 0).day;
            DateTime now = DateTime.now();
            bool isToday(int day) =>
                vm.year == now.year && vm.month == now.month && day == now.day;

            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 4,
              ),
              itemCount: offset + daysInMonth,
              itemBuilder: (context, index) {
                if (index < offset) return SizedBox();
                int day = index - offset + 1;
                DateTime cellDate = DateTime(vm.year, vm.month, day);

                bool isPast =
                    cellDate.year < now.year ||
                    (cellDate.year == now.year && cellDate.month < now.month) ||
                    (cellDate.year == now.year &&
                        cellDate.month == now.month &&
                        day < now.day);

                bool isSelected =
                    currentDate.year == cellDate.year &&
                    currentDate.month == cellDate.month &&
                    currentDate.day == cellDate.day;

                return GestureDetector(
                  onTap: isPast ? null : () => controller.selectDate(cellDate),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [gold, gold.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isToday(day) && !isSelected
                          ? gold.withValues(alpha: 0.1)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: gold.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: GoogleFonts.poppins(
                          color: isPast
                              ? Colors.white.withValues(alpha: 0.15)
                              : (isSelected
                                    ? Color(0xFF0F1120)
                                    : Colors.white70),
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  // ═══════════════════════════════════════════════════════
  // TIME SLOTS
  // ═══════════════════════════════════════════════════════
  Widget _buildTimeSlots(Color card, Color gold) {
    return Obx(() {
      if (controller.allTimes.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(Icons.schedule_rounded, color: Colors.white24, size: 40),
                SizedBox(height: 8),
                Text(
                  "Hozircha bo'sh vaqt yo'q",
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manual custom time input
          Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: controller.customTimeController,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
              keyboardType: TextInputType.datetime,
              maxLength: 5,
              decoration: InputDecoration(
                counterText: "",
                hintText: "Masalan: 13:45 yozing...",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.white24,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.keyboard_alt_rounded,
                  color: gold,
                  size: 20,
                ),
              ),
              onChanged: controller.onCustomTimeChanged,
            ),
          ).animate().fadeIn(delay: 150.ms),

          // Quick select — nearest available time
          GestureDetector(
                onTap: () => controller.selectNearestAvailableTime(),
                child: Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gold.withValues(alpha: 0.2),
                        gold.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: gold.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, color: gold, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "⚡ Eng yaqin bo'sh vaqt",
                        style: GoogleFonts.poppins(
                          color: gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 200.ms)
              .shimmer(
                delay: Duration(seconds: 1),
                duration: 1500.ms,
                color: gold.withValues(alpha: 0.15),
              ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: controller.allTimes.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              final isAvailable = controller.availableTimes.contains(t);
              final isSelected = controller.selectedTime.value == t;

              return GestureDetector(
                onTap: isAvailable ? () => controller.selectTime(t) : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: (MediaQuery.sizeOf(Get.context!).width - 62) / 4,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [gold, gold.withValues(alpha: 0.7)],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isAvailable
                              ? card
                              : Colors.white.withValues(alpha: 0.02)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? gold
                          : (isAvailable
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.transparent),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: gold.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      t,
                      style: GoogleFonts.poppins(
                        color: isSelected
                            ? Color(0xFF0F1120)
                            : (isAvailable
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.2)),
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        decoration: isAvailable
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 180 + (i * 20)));
            }).toList(),
          ),
        ],
      );
    });
  }

  // ═══════════════════════════════════════════════════════
  // SERVICE INFO CARD
  // ═══════════════════════════════════════════════════════
  Widget _buildServiceInfoCard(Color card, Color gold) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [card, gold.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.content_cut_rounded,
                      color: gold,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.serviceName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "${controller.serviceDurationMinutes} daqiqa",
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat(
                      '#,###',
                      'en_US',
                    ).format(controller.servicePrice).replaceAll(',', ' '),
                    style: GoogleFonts.poppins(
                      color: gold,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "so'm",
                    style: GoogleFonts.poppins(
                      color: gold.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          SizedBox(height: 16),
          Row(
            children: [
              _infoChip(
                Icons.person_rounded,
                "Usta",
                controller.selectedBarber.value?['name'] ?? '—',
                gold,
              ),
              SizedBox(width: 12),
              Obx(
                () => _infoChip(
                  Icons.calendar_today_rounded,
                  "Sana",
                  "${controller.selectedDate.value.day} ${_getMonthName(controller.selectedDate.value.month)}",
                  gold,
                ),
              ),
              SizedBox(width: 12),
              Obx(
                () => _infoChip(
                  Icons.schedule_rounded,
                  "Vaqt",
                  controller.selectedTime.value.isEmpty
                      ? "—"
                      : controller.selectedTime.value,
                  gold,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _infoChip(IconData icon, String label, String value, Color gold) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: gold.withValues(alpha: 0.6), size: 16),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white30, fontSize: 10),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // PREMIUM BUTTON
  // ═══════════════════════════════════════════════════════
  Widget _premiumBtn(Color gold, String label, VoidCallback? onTap) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(Get.context!).bottom + 12,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: onTap != null
                ? LinearGradient(
                    colors: [gold, gold.withValues(alpha: 0.8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: onTap == null ? Colors.white.withValues(alpha: 0.06) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: onTap != null
                ? [
                    BoxShadow(
                      color: gold.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: onTap != null ? Color(0xFF0F1120) : Colors.white30,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  // ═══════════════════════════════════════════════════════
  // PAYMENT SELECTOR (PREMIUM)
  // ═══════════════════════════════════════════════════════
  Widget _buildPaymentMethodSelector(
    Color card,
    Color gold,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () => _showPaymentBottomSheet(context, card, gold),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gold.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: gold,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    String methodText = "Naqd pul";
                    if (controller.selectedPaymentMethod.value == 'payme') {
                      methodText = "Payme";
                    }
                    return Text(
                      methodText,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }),
                  Text(
                    "Joyida to'lov",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white30),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  void _showPaymentBottomSheet(BuildContext context, Color card, Color gold) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.paddingOf(context).bottom + 24,
          ),
          decoration: BoxDecoration(
            color: Color(0xFF0F1120),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                "To'lov usulini tanlang",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 20),

              // 1. NAQD PUL (Active)
              GestureDetector(
                onTap: () {
                  controller.selectedPaymentMethod.value = 'cash';
                  Get.back();
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: gold),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.money_rounded, color: gold, size: 24),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Naqd pul",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Usta oldida joyida to'lanadi",
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle_rounded, color: gold),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBarberCardWidget(
    Map<String, dynamic> b,
    bool sel,
    bool isActive,
    Color card,
    Color gold,
  ) {
    return GestureDetector(
      onTap: () => controller.selectBarber(b),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: sel
              ? LinearGradient(
                  colors: [
                    gold.withValues(alpha: 0.15),
                    gold.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: sel ? null : card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: sel ? gold : Colors.white.withValues(alpha: 0.04),
            width: sel ? 1.5 : 1,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: gold.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Avatar with active indicator
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? gold : Colors.white.withValues(alpha: 0.1),
                      width: 2,
                    ),
                    image: DecorationImage(
                      image: ImageHelper.getBarberImage(
                        b['image']?.toString(),
                        b['id']?.toString() ?? 'unknown',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isActive)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                        border: Border.all(color: card, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          b['name'] ?? 'Usta',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (sel) ...[
                        SizedBox(width: 6),
                        Icon(Icons.verified_rounded, color: gold, size: 16),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD700),
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "${b['rating'] ?? 5.0}",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white30,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "${b['experience'] ?? 1} yil",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      if (b['location'] != null) ...[
                        SizedBox(width: 12),
                        Icon(
                          Icons.location_on_rounded,
                          color: Colors.white30,
                          size: 13,
                        ),
                        SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            "${b['location']}",
                            style: GoogleFonts.poppins(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Checkmark
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: sel
                    ? LinearGradient(
                        colors: [gold, gold.withValues(alpha: 0.7)],
                      )
                    : null,
                color: sel ? null : Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: sel
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(
                sel ? Icons.check_rounded : Icons.add_rounded,
                color: sel ? Color(0xFF0F1120) : Colors.white30,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
