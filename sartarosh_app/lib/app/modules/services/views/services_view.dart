import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/services_controller.dart';
import '../../../../core/theme/app_theme.dart';

class ServicesView extends GetView<ServicesController> {
  const ServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Xizmatlar",
          style: TextStyle(
            color: AppTheme.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Iltimos, kerakli xizmatni tanlang",
              style: TextStyle(color: AppTheme.textMedium, fontSize: 15),
            ).animate().fadeIn(),
            SizedBox(height: 20),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: controller.services.length,
                  itemBuilder: (context, index) {
                    final s = controller.services[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _showDetail(s),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
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
                                padding: EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  IconData(
                                    s['icon'],
                                    fontFamily: 'MaterialIcons',
                                  ),
                                  color: AppTheme.primary,
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s['name'],
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      s['duration'] != null
                                          ? "${s['duration']} daqiqa"
                                          : "—",
                                      style: TextStyle(
                                        color: AppTheme.textMedium,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                s['price'] != null && s['price'] > 0
                                    ? "${(s['price'] as int) ~/ 1000} ming"
                                    : "—",
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(
                      delay: Duration(milliseconds: 100 + (index * 80)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> s) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Icon(
              IconData(s['icon'], fontFamily: 'MaterialIcons'),
              color: AppTheme.primary,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              s['name'],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              s['description'] ?? '',
              style: TextStyle(color: AppTheme.textMedium, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chip(
                  Icons.access_time_rounded,
                  s['duration'] != null ? "${s['duration']} daqiqa" : "—",
                ),
                SizedBox(width: 12),
                _chip(
                  Icons.payments_rounded,
                  s['price'] != null && s['price'] > 0
                      ? "${(s['price'] as int) ~/ 1000} ming so'm"
                      : "Narx belgilanmagan",
                ),
              ],
            ),
            SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                Get.back();
                Get.toNamed(
                  '/booking',
                  arguments: {'service': s['name'], 'price': s['price']},
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    "Tanlash",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 16),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
