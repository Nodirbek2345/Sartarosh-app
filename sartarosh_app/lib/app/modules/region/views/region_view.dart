import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/region_controller.dart';
import '../../../../core/theme/app_theme.dart';

class RegionView extends GetView<RegionController> {
  const RegionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFFAF8F5), // Light cream background exactly as image
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── HEADER ───
              Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF1A1A1A),
                              size: 24,
                            ),
                          ),
                        ),
                        Spacer(),
                        Obx(
                          () => controller.isDetecting.value
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () => controller.detectLocation(),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.my_location_rounded,
                                          color: AppTheme.gold,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "GPS",
                                          style: GoogleFonts.poppins(
                                            color: Color(0xFF1A1A1A),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Viloyatingizni tanlang",
                      style: GoogleFonts.playfairDisplay(
                        color: Color(0xFF1A1A1A),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    SizedBox(height: 24),

                    // ─── SEARCH BAR ───
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF0EBE1), // Light grayish-cream
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        onChanged: (v) => controller.searchQuery.value = v,
                        style: GoogleFonts.poppins(
                          color: Color(0xFF1A1A1A),
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: "Viloyat qidirish...",
                          hintStyle: GoogleFonts.poppins(
                            color: Color(0xFF1A1A1A).withValues(alpha: 0.4),
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Color(0xFF1A1A1A).withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // ─── REGION LIST ───
              Expanded(
                child: Obx(() {
                  final items = controller.filteredRegions;
                  return ListView.builder(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final region = items[index];
                      return Obx(() {
                        final isSelected =
                            controller.selectedRegion.value == region['key'];
                        return GestureDetector(
                          onTap: () => controller.selectRegion(region['key']!),
                          child: AnimatedContainer(
                            duration: 250.ms,
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(0xFFF0EBE1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.gold
                                    : Colors.black.withValues(alpha: 0.02),
                                width: isSelected ? 1 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    region['name']!,
                                    style: GoogleFonts.poppins(
                                      color: isSelected
                                          ? AppTheme.gold
                                          : Color(0xFF1A1A1A),
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.check_rounded
                                      : Icons.chevron_right_rounded,
                                  color: isSelected
                                      ? AppTheme.gold
                                      : Color(
                                          0xFFE07A5F,
                                        ), // Orange accent chevron like image
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                        );
                      });
                    },
                  );
                }),
              ),

              // ─── BOTTOM BUTTON ───
              Padding(
                // Ensure dynamic clearance above home indicator/navigation bar
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.paddingOf(Get.context!).bottom + 20,
                ),
                child: GestureDetector(
                  onTap: () => controller.confirmAndGo(),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Davom etish",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
