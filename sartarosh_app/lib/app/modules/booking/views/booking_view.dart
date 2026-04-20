import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/booking_controller.dart';
import '../../../../core/theme/app_theme.dart';

class BookingView extends GetView<BookingController> {
  const BookingView({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine exact colors based on the design
    final bgColor = AppTheme.isFemale ? AppTheme.darkBg : Color(0xFF141522);
    final cardColor = AppTheme.isFemale ? AppTheme.darkCard : Color(0xFF1D1F33);
    final goldColor = AppTheme.primary; // Gold

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 200,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: GestureDetector(
            onTap: () {
              if (controller.currentStep.value > 0) {
                controller.prevStep();
              } else {
                Get.back();
              }
            },
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: goldColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "Bron qilish",
                  style: GoogleFonts.playfairDisplay(
                    color: goldColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Icon(Icons.notifications_none_rounded, color: goldColor),
          SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundImage: CachedNetworkImageProvider(
              'https://i.pravatar.cc/100?u=user',
            ), // You can change this if needed
          ),
          SizedBox(width: 20),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.currentStep.value == 0) {
            return _step1(bgColor, cardColor, goldColor);
          } else {
            return _modernBookingForm(bgColor, cardColor, goldColor);
          }
        }),
      ),
    );
  }

  Widget _step1(Color bgColor, Color cardColor, Color goldColor) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Xizmatni tanlang",
            style: GoogleFonts.playfairDisplay(
              color: goldColor,
              fontSize: 22,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ).animate().fadeIn(),
          SizedBox(height: 6),
          Text(
            "Siz uchun eng yaxshi usta tanlandi",
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
          ).animate().fadeIn(delay: 100.ms),
          SizedBox(height: 16),
          Expanded(
            child: Obx(
              () => ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: controller.barbers.length,
                itemBuilder: (context, index) {
                  final b = controller.barbers[index];
                  final sel = controller.selectedBarber.value?['id'] == b['id'];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => controller.selectBarber(b),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sel ? goldColor : Colors.transparent,
                            width: 2,
                          ),
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
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    b['image'] ??
                                        'https://i.pravatar.cc/200?u=${b['id']}',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b['name'] ?? 'Usta',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    "⭐ ${b['rating'] ?? 5.0}  •  ${b['experience'] ?? 1} yil",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (sel)
                              Icon(
                                Icons.check_circle_rounded,
                                color: goldColor,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(
                    delay: Duration(milliseconds: 200 + (index * 60)),
                  );
                },
              ),
            ),
          ),
          _nextBtn(goldColor, "Davom etish", () => controller.nextStep()),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'YANVAR',
      'FEVRAL',
      'MART',
      'APREL',
      'MAY',
      'IYUN',
      'IYUL',
      'AVGUST',
      'SENTABR',
      'OKTABR',
      'NOYABR',
      'DEKABR',
    ];
    return months[month - 1];
  }

  Widget _modernBookingForm(Color bgColor, Color cardColor, Color goldColor) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SANA TANLANG
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sana tanlang",
                style: GoogleFonts.playfairDisplay(
                  color: goldColor,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Obx(() {
                final dt = controller.selectedDate.value;
                return Text(
                  "${_getMonthName(dt.month)} ${dt.year}",
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                );
              }),
            ],
          ).animate().fadeIn(delay: 100.ms),
          SizedBox(height: 12),
          // CALENDAR CARD
          _buildCalendarCard(cardColor, goldColor),

          SizedBox(height: 24),

          // VAQT TANLANG
          Text(
            "Vaqt tanlang",
            style: GoogleFonts.playfairDisplay(
              color: goldColor,
              fontSize: 20,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(delay: 200.ms),
          SizedBox(height: 12),
          _buildTimeSlots(goldColor),

          SizedBox(height: 24),

          // XIZMAT MA'LUMOTLARI
          Text(
            "Xizmat ma'lumotlari",
            style: GoogleFonts.playfairDisplay(
              color: goldColor,
              fontSize: 20,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(delay: 300.ms),
          SizedBox(height: 12),
          _buildServiceInfoCard(cardColor, goldColor),

          SizedBox(height: 24),

          // CONFIRM BUTTON
          Obx(
            () => GestureDetector(
              onTap:
                  controller.isSubmitting.value ||
                      controller.selectedTime.value.isEmpty
                  ? null
                  : () => controller.confirmBooking(),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: controller.selectedTime.value.isNotEmpty
                      ? goldColor
                      : goldColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: controller.selectedTime.value.isNotEmpty
                      ? [
                          BoxShadow(
                            color: goldColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    controller.isSubmitting.value
                        ? "Yuklanmoqda..."
                        : "Bronni tasdiqlash",
                    style: GoogleFonts.poppins(
                      color: controller.selectedTime.value.isNotEmpty
                          ? Color(0xFF141522)
                          : Colors.white60,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(Color cardColor, Color goldColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['DU', 'SE', 'CH', 'PA', 'JU', 'SH', 'YA']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.poppins(
                          color: goldColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 16),
          Obx(() {
            DateTime currentDate = controller.selectedDate.value;
            DateTime firstDayOfMonth = DateTime(
              currentDate.year,
              currentDate.month,
              1,
            );
            int offset = firstDayOfMonth.weekday - 1;
            int daysInMonth = DateTime(
              currentDate.year,
              currentDate.month + 1,
              0,
            ).day;

            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 4,
              ),
              itemCount: offset + daysInMonth,
              itemBuilder: (context, index) {
                if (index < offset) return SizedBox();
                int day = index - offset + 1;
                bool isSelected = currentDate.day == day;
                return GestureDetector(
                  onTap: () => controller.selectDate(
                    DateTime(currentDate.year, currentDate.month, day),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? goldColor : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: GoogleFonts.poppins(
                          color: isSelected
                              ? Color(0xFF141522)
                              : Colors.white70,
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w700
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

  Widget _buildTimeSlots(Color goldColor) {
    return Obx(() {
      if (controller.allTimes.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Hozircha bo'sh vaqt yo'q...",
              style: GoogleFonts.poppins(color: Colors.white60),
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => controller.selectNearestAvailableTime(),
            child: Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: goldColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, color: goldColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Eng yaqin bo'sh vaqtni tanlash",
                    style: GoogleFonts.poppins(
                      color: goldColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: controller.allTimes.map((t) {
              final isAvailable = controller.availableTimes.contains(t);
              final isSelected = controller.selectedTime.value == t;

              return GestureDetector(
                onTap: isAvailable ? () => controller.selectTime(t) : null,
                child: Container(
                  width: (MediaQuery.sizeOf(Get.context!).width - 70) / 3,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? goldColor
                        : (isAvailable ? Color(0xFF282A40) : Color(0xFF1B1D2C)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? goldColor
                          : (isAvailable ? Colors.white24 : Colors.transparent),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: goldColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      t,
                      style: GoogleFonts.poppins(
                        color: isSelected
                            ? Color(0xFF141522)
                            : (isAvailable ? Colors.white : Colors.white30),
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        decoration: isAvailable
                            ? TextDecoration.none
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 250.ms),
        ],
      );
    });
  }

  Widget _buildServiceInfoCard(Color cardColor, Color goldColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  controller.serviceName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text(
                "${NumberFormat('#,###', 'en_US').format(controller.servicePrice).replaceAll(',', ' ')} UZS",
                style: GoogleFonts.poppins(
                  color: goldColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Obx(
            () => Text(
              "Usta: ${controller.selectedBarber.value?['name'] ?? 'Noma\'lum'}",
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
            ),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.access_time_rounded, color: Colors.white60, size: 18),
              SizedBox(width: 6),
              Text(
                "${controller.serviceDurationMinutes} daqiqa",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 24),
              Icon(
                Icons.calendar_today_outlined,
                color: Colors.white60,
                size: 18,
              ),
              SizedBox(width: 6),
              Obx(() {
                final dt = controller.selectedDate.value;
                return Text(
                  "${dt.day} ${_getMonthName(dt.month).toLowerCase().capitalizeFirst}, ${dt.year}",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _nextBtn(Color goldColor, String label, VoidCallback? onTap) {
    return Padding(
      // Ensure extra padding unconditionally at the bottom
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(Get.context!).bottom + 20,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: onTap != null ? goldColor : goldColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: onTap != null
                ? [
                    BoxShadow(
                      color: goldColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: onTap != null ? Color(0xFF141522) : Colors.white60,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
