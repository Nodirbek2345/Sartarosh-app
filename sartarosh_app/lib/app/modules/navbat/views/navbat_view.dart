import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/navbat_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';

class NavbatView extends GetView<NavbatController> {
  const NavbatView({super.key});

  @override
  Widget build(BuildContext context) {
    final isBarber = Get.find<UserService>().userRole.value == 'barber';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Navbat",
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: isBarber ? _buildBarberRedirect() : _buildClientQueue(),
    );
  }

  Widget _buildBarberRedirect() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_horiz_rounded, size: 50, color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(
            "Usta paneliga o'tilmoqda...",
            style: GoogleFonts.poppins(color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildClientQueue() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.activeQueueBookings.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: controller.activeQueueBookings.length,
        itemBuilder: (context, index) {
          final b = controller.activeQueueBookings[index];
          return _buildQueueCard(
            b,
          ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
        },
      );
    });
  }

  Widget _buildQueueCard(Map<String, dynamic> booking) {
    final isQueue = booking['isQueue'] ?? false;
    final status = booking['status'];
    final time = booking['time'] ?? '';
    final barberName = booking['barberName'] ?? 'Usta';
    final serviceName = booking['serviceName'] ?? 'Xizmat turi';
    final queuePos = booking['queuePosition'] ?? 0;
    final waitMin = booking['estimatedWait'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: status == 'in_progress'
            ? Border.all(color: AppTheme.success, width: 2)
            : Border.all(color: Colors.transparent),
      ),
      child: Column(
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      status == 'in_progress'
                          ? Icons.content_cut_rounded
                          : Icons.person_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barberName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        serviceName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.textMedium,
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
                    color: isQueue ? AppTheme.primary : AppTheme.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isQueue ? "Jonli navbat" : time,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Queue Details
          if (status == 'in_progress')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.content_cut_rounded,
                    color: AppTheme.success,
                    size: 18,
                  ).animate(onPlay: (c) => c.repeat()).shake(),
                  const SizedBox(width: 8),
                  Text(
                    "Sizning xizmatingiz boshlandi",
                    style: GoogleFonts.poppins(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else if (isQueue)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF6F0),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _queueStat(
                    "Navbatingiz",
                    "$queuePos",
                    Icons.people_outline_rounded,
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  _queueStat(
                    "Taxminiy kutish",
                    "~$waitMin daq",
                    Icons.access_time_rounded,
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF6F0),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppTheme.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Iltimos, $time da keling",
                    style: GoogleFonts.poppins(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _queueStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.textMedium),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
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
              Icons.queue_rounded,
              size: 50,
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 20),
          Text(
            "Siz navbatda emassiz",
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Ustalardan jonli navbat olishingiz yoki vaqt bo'yicha bron qilishingiz mumkin",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Get.offNamed(
              '/home',
            ), // Home'ning Search qismiga o'tish kabi ham ishlatilishi mumkin
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Usta topish",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
