import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
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
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            tabs: [
              Tab(text: "Faol"),
              Tab(text: "Tarix"),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          return TabBarView(
            children: [
              _buildList(controller.activeBookings, isActive: true),
              _buildList(controller.pastBookings, isActive: false),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> items, {
    required bool isActive,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.event_available_rounded : Icons.history_rounded,
              size: 64,
              color: AppTheme.textLight,
            ),
            SizedBox(height: 16),
            Text(
              isActive ? "Hozircha faol bronlar yo'q" : "Bronlar tarixi bo'sh",
              style: TextStyle(color: AppTheme.textMedium, fontSize: 16),
            ),
          ],
        ),
      ).animate().fadeIn();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      physics: BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final b = items[index];
        final status = b['status'] ?? 'pending';
        return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _statusColor(status).withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _statusIcon(status),
                          color: _statusColor(status),
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b['service'] ?? 'Xizmat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${b['barberName'] ?? '—'}",
                              style: TextStyle(
                                color: AppTheme.textMedium,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
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
                          SizedBox(width: 4),
                          Text(
                            "${b['date'] ?? '—'} • ${b['time'] ?? ''}",
                            style: TextStyle(
                              color: AppTheme.textMedium,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${((b['price'] ?? 0) ~/ 1000)} ming so'm",
                        style: TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (isActive && status == 'confirmed')
                    Container(
                      margin: EdgeInsets.only(top: 14),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppTheme.primary,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Hizmat tasdiqlandi. Iltimos o'z vaqtida keling.",
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                size: 16,
                                color: AppTheme.textDark,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Naqd to'lov: Xizmatdan so'ng joyida to'laysiz.",
                                  style: TextStyle(
                                    color: AppTheme.textDark,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 14),
                  if (isActive &&
                      (status == 'pending' || status == 'confirmed'))
                    GestureDetector(
                      onTap: () {
                        Get.dialog(
                          AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text("Bekor qilish"),
                            content: Text(
                              "Haqiqatan ham ushbu bronni bekor qilmoqchimisiz?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: Text("Yo'q"),
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
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "Bekor qilish",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!isActive)
                    GestureDetector(
                      onTap: () => controller.rebook(b),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Qayta bron qilish",
                            style: TextStyle(
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
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Color(0xFF16A34A); // Green as requested
      case 'in-progress':
        return AppTheme.primary;
      case 'completed':
        return Color(0xFF16A34A);
      case 'cancelled':
        return Color(0xFFDC2626);
      case 'no-show':
      case 'penalty':
        return Color(0xFF475569);
      default:
        return Color(0xFFD97706);
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
        return 'Bekor qilingan';
      case 'penalty':
        return 'Kech bekor qilingan';
      case 'no-show':
        return 'Kelmadi';
      default:
        return status;
    }
  }
}
