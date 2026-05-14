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
        title: Obx(
          () => Text(
            controller.currentCategory.value == 'Barchasi'
                ? "Xizmatlar"
                : controller.currentCategory.value,
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
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
              child: Obx(() {
                if (controller.isLoading.value) {
                  return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Container(
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  )
                                  .animate(onPlay: (c) => c.repeat())
                                  .shimmer(
                                    duration: 1500.ms,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                          width: 140,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        )
                                        .animate(onPlay: (c) => c.repeat())
                                        .shimmer(
                                          duration: 1500.ms,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                    SizedBox(height: 8),
                                    Container(
                                          width: 100,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        )
                                        .animate(onPlay: (c) => c.repeat())
                                        .shimmer(
                                          duration: 1500.ms,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                if (controller.services.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.content_cut_rounded,
                            size: 48,
                            color: AppTheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Hozircha xizmatlar mavjud emas",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Ustalar xizmatlarini qo'shgandan so'ng bu yerda ko'rinadi",
                          style: TextStyle(
                            color: AppTheme.textMedium,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms);
                }

                return ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: controller.services.length,
                  itemBuilder: (context, index) {
                    final s = controller.services[index];
                    final minPrice = s['minPrice'] ?? 0;
                    final maxPrice = s['maxPrice'] ?? 0;
                    final barberCount = s['barberCount'] ?? 0;

                    String priceText;
                    if (minPrice == 0 && maxPrice == 0) {
                      priceText = "—";
                    } else if (minPrice == maxPrice) {
                      priceText = "${minPrice ~/ 1000} ming";
                    } else {
                      priceText =
                          "${minPrice ~/ 1000}—${maxPrice ~/ 1000} ming";
                    }

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
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
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                s['icon'] as IconData,
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
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: AppTheme.textMedium,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "${s['duration'] ?? 30} daqiqa",
                                        style: TextStyle(
                                          color: AppTheme.textMedium,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Icon(
                                        Icons.person_rounded,
                                        size: 13,
                                        color: AppTheme.textMedium,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "$barberCount usta",
                                        style: TextStyle(
                                          color: AppTheme.textMedium,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              priceText,
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(
                      delay: Duration(milliseconds: 100 + (index * 80)),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
