import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/barber_services_controller.dart';
import '../../../../core/theme/app_theme.dart';

class BarberServicesView extends GetView<BarberServicesController> {
  const BarberServicesView({super.key});

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
          "Xizmatlarim va Narxlar",
          style: GoogleFonts.poppins(
            color: AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (controller.servicesList.isEmpty) {
          return Center(child: Text("Hech qanday xizmat topilmadi"));
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.servicesList.length,
                itemBuilder: (context, index) {
                  return _buildServiceCard(index).animate().fadeIn(
                    delay: Duration(milliseconds: 100 + (index * 50)),
                  );
                },
              ),
            ),
            _buildBottomSaveBtn(),
          ],
        );
      }),
    );
  }

  Widget _buildBottomSaveBtn() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.paddingOf(Get.context!).bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: controller.isSaving.value
            ? null
            : () => controller.saveSettings(),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: controller.isSaving.value ? null : AppTheme.goldGradient,
            color: controller.isSaving.value ? Colors.grey : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: controller.isSaving.value
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Saqlash",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(int index) {
    return Obx(() {
      final s = controller.servicesList[index];
      final isEnabled = s['isEnabled'] as bool;
      final price = s['price'] as int;
      final duration = s['duration'] as int;

      return Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled
                ? AppTheme.primary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          children: [
            // Head (Toggle)
            GestureDetector(
              onTap: () => controller.toggleService(index),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        IconData(s['icon'], fontFamily: 'MaterialIcons'),
                        color: isEnabled ? AppTheme.primary : Colors.grey,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            s['category'],
                            style: GoogleFonts.poppins(
                              color: AppTheme.textMedium,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isEnabled,
                      onChanged: (v) => controller.toggleService(index),
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        return states.contains(WidgetState.selected)
                            ? AppTheme.primary
                            : null;
                      }),
                      trackColor: WidgetStateProperty.resolveWith((states) {
                        return states.contains(WidgetState.selected)
                            ? AppTheme.primary.withValues(alpha: 0.2)
                            : null;
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // Base fields (animated expansion)
            AnimatedCrossFade(
              firstChild: SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Divider(
                      color: Colors.grey.withValues(alpha: 0.1),
                      height: 1,
                    ),
                    SizedBox(height: 16),
                    // Price Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Narxi (so'm)",
                            style: GoogleFonts.poppins(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        _counterBtn(
                          Icons.remove,
                          () => controller.updatePrice(index, price - 5000),
                        ),
                        Container(
                          width: 80,
                          alignment: Alignment.center,
                          child: Text(
                            NumberFormat(
                              '#,###',
                              'en_US',
                            ).format(price).replaceAll(',', ' '),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        _counterBtn(
                          Icons.add,
                          () => controller.updatePrice(index, price + 5000),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Duration Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Vaqt (daqiqa)",
                            style: GoogleFonts.poppins(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        _counterBtn(
                          Icons.remove,
                          () => controller.updateDuration(index, duration - 5),
                        ),
                        Container(
                          width: 80,
                          alignment: Alignment.center,
                          child: Text(
                            "$duration daq",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        _counterBtn(
                          Icons.add,
                          () => controller.updateDuration(index, duration + 5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: isEnabled
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: Duration(milliseconds: 250),
            ),
          ],
        ),
      );
    });
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 16, color: AppTheme.textDark),
      ),
    );
  }
}
