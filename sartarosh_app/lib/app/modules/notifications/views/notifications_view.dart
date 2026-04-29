import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/notifications_controller.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          "Bildirishnomalar",
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            if (controller.notifications.isNotEmpty) {
              return IconButton(
                icon: Icon(Icons.clear_all_rounded, color: AppTheme.primary),
                onPressed: () => _showClearDialog(),
              );
            }
            return SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: AppTheme.textLight,
                ),
                SizedBox(height: 16),
                Text(
                  "Sizda hozircha bildirishnomalar yo'q",
                  style: TextStyle(color: AppTheme.textMedium, fontSize: 16),
                ),
              ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.1),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8),
          physics: BouncingScrollPhysics(),
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final n = controller.notifications[index];
            final isRead = n['isRead'] ?? true;

            String dateFormatted = '';
            if (n['createdAt'] != null) {
              final ts = n['createdAt'] as Timestamp;
              dateFormatted = DateFormat(
                'dd.MM.yyyy HH:mm',
              ).format(ts.toDate());
            }

            return GestureDetector(
              onTap: () {
                if (!isRead) controller.markAsRead(n['docId']);
              },
              child:
                  Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead
                              ? Colors.white
                              : AppTheme.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRead
                                ? Colors.black.withValues(alpha: 0.05)
                                : AppTheme.primary.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getIconColor(
                                  n['type'],
                                ).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIcon(n['type']),
                                color: _getIconColor(n['type']),
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n['title'] ?? 'Bildirishnoma',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isRead
                                                ? FontWeight.w600
                                                : FontWeight.w800,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppTheme.danger,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    n['message'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isRead
                                          ? AppTheme.textMedium
                                          : AppTheme.textDark,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    dateFormatted,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 50 * index))
                      .slideX(begin: 0.05),
            );
          },
        );
      }),
    );
  }

  IconData _getIcon(String? type) {
    if (type == 'booking_created') return Icons.event_available_rounded;
    if (type == 'booking_confirmed') return Icons.check_circle_outline_rounded;
    if (type == 'booking_cancelled') return Icons.cancel_outlined;
    return Icons.notifications_active_rounded;
  }

  Color _getIconColor(String? type) {
    if (type == 'booking_created') return AppTheme.primary;
    if (type == 'booking_confirmed') return AppTheme.success;
    if (type == 'booking_cancelled') return AppTheme.danger;
    return AppTheme.textMedium;
  }

  void _showClearDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("O'chirish"),
        content: Text("Barcha bildirishnomalarni o'chirmoqchimisiz?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Yo'q")),
          TextButton(
            onPressed: () {
              Get.back();
              controller.clearAll();
            },
            child: Text("O'chirish", style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}
