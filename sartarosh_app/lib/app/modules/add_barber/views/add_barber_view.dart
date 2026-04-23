import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/add_barber_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/currency_formatter.dart';

class AddBarberView extends GetView<AddBarberController> {
  const AddBarberView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
          onPressed: () {
            if (controller.currentStep.value > 0) {
              controller.prevStep();
            } else {
              Get.back();
            }
          },
        ),
        title: Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Container(
                margin: EdgeInsets.symmetric(horizontal: 3),
                width: controller.currentStep.value == i ? 28 : 8,
                height: 6,
                decoration: BoxDecoration(
                  color: controller.currentStep.value >= i
                      ? AppTheme.primary
                      : AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          switch (controller.currentStep.value) {
            case 0:
              return _stepInfo();
            case 1:
              return _stepServices();
            case 2:
              return _stepPreview();
            default:
              return SizedBox();
          }
        }),
      ),
    );
  }

  // ─── STEP 1: PERSONAL INFO ───
  Widget _stepInfo() {
    final isFemale = Get.find<UserService>().targetGender.value == 'female';
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header icon
          GestureDetector(
            onTap: () => controller.pickImage(),
            child: Obx(
              () => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                  image: controller.selectedImagePath.value.isNotEmpty
                      ? DecorationImage(
                          image: FileImage(
                            File(controller.selectedImagePath.value),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: controller.selectedImagePath.value.isEmpty
                    ? Icon(
                        Icons.add_a_photo_rounded,
                        color: AppTheme.primary,
                        size: 32,
                      )
                    : null,
              ),
            ).animate().scale(duration: 400.ms),
          ),
          SizedBox(height: 20),
          Text(
            "Usta sifatida\nro'yxatdan o'ting",
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.textDark,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ).animate().fadeIn(),
          SizedBox(height: 8),
          Text(
            "O'z ma'lumotlaringizni kiriting",
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 28),
          _goldField(
            "To'liq ism *",
            isFemale ? "Nargiza Karimova" : "Sardor Karimov",
            Icons.person_rounded,
            controller.nameCtrl,
            200,
            inputType: TextInputType.name,
          ),
          SizedBox(height: 14),
          _goldField(
            "Telefon raqam *",
            "+998 90 123 45 67",
            Icons.phone_rounded,
            controller.phoneCtrl,
            300,
            inputType: TextInputType.phone,
          ),
          SizedBox(height: 14),
          Obx(
            () => _goldField(
              "Manzil *",
              "Toshkent, Chilonzor tumani, 7-mavze",
              Icons.location_on_rounded,
              controller.addressCtrl,
              400,
              suffixIcon: IconButton(
                icon: controller.isLocating.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      )
                    : Text("📍", style: TextStyle(fontSize: 18)),
                onPressed: controller.isLocating.value
                    ? null
                    : () => controller.fetchLocation(),
              ),
            ),
          ),
          SizedBox(height: 14),
          _goldField(
            "Tajriba (yil)",
            "Masalan: 3",
            Icons.workspace_premium_rounded,
            controller.expCtrl,
            450,
            inputType: TextInputType.number,
          ),
          SizedBox(height: 14),
          _goldField(
            "O'zingiz haqida",
            "Mijozlar uchun qisqacha tavsif...",
            Icons.edit_note_rounded,
            controller.aboutCtrl,
            500,
            maxLines: 3,
          ),
          SizedBox(height: 32),
          _goldBtn("Keyingisi →", () => controller.nextStep()),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── STEP 2: SERVICES & SCHEDULE ───
  Widget _stepServices() {
    final isFemale = Get.find<UserService>().targetGender.value == 'female';
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.content_cut_rounded,
              color: AppTheme.primary,
              size: 32,
            ),
          ).animate().scale(duration: 400.ms),
          SizedBox(height: 20),
          Text(
            "Xizmatlar va\nish vaqtingiz",
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.textDark,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ).animate().fadeIn(),
          SizedBox(height: 8),
          Text(
            "Narxlar va ish jadvalingizni kiriting",
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 28),

          // Prices section
          Text(
            "💈 Xizmat narxlari",
            style: GoogleFonts.poppins(
              color: AppTheme.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          _priceRow(
            isFemale ? "Soch turmaklash / Kesish *" : "Soch olish *",
            Icons.content_cut_rounded,
            controller.haircutPriceCtrl,
            200,
          ),
          SizedBox(height: 10),
          _priceRow(
            isFemale ? "Bo'yash / Ukladka" : "Soqol olish",
            isFemale
                ? Icons.face_retouching_natural_rounded
                : Icons.face_rounded,
            controller.beardPriceCtrl,
            280,
          ),
          SizedBox(height: 10),
          _priceRow(
            isFemale ? "Soch + Makiyaj" : "Soch + Soqol",
            Icons.auto_awesome_rounded,
            controller.comboPriceCtrl,
            360,
          ),

          SizedBox(height: 28),

          // Working hours
          Text(
            "🕐 Ish vaqti",
            style: GoogleFonts.poppins(
              color: AppTheme.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _timeCard("Ochilish", controller.openTime)),
              SizedBox(width: 14),
              Expanded(child: _timeCard("Yopilish", controller.closeTime)),
            ],
          ).animate().fadeIn(delay: 400.ms),

          SizedBox(height: 32),
          _goldBtn("Tekshirish →", () => controller.nextStep()),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── STEP 3: PREVIEW & SUBMIT ───
  Widget _stepPreview() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: AppTheme.success,
              size: 32,
            ),
          ).animate().scale(duration: 400.ms),
          SizedBox(height: 20),
          Text(
            "Ma'lumotlarni\ntasdiqlang",
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.textDark,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ).animate().fadeIn(),
          SizedBox(height: 8),
          Text(
            "Barcha ma'lumotlar to'g'ri ekanligini tekshiring",
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 24),

          // Preview card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar placeholder
                Obx(
                  () => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: controller.selectedImagePath.value.isEmpty
                          ? AppTheme.goldGradient
                          : null,
                      color: controller.selectedImagePath.value.isNotEmpty
                          ? Colors.grey[200]
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      image: controller.selectedImagePath.value.isNotEmpty
                          ? DecorationImage(
                              image: FileImage(
                                File(controller.selectedImagePath.value),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: controller.selectedImagePath.value.isEmpty
                        ? Center(
                            child: Text(
                              controller.nameCtrl.text.isNotEmpty
                                  ? controller.nameCtrl.text[0].toUpperCase()
                                  : "U",
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  controller.nameCtrl.text,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: AppTheme.textMedium,
                    ),
                    SizedBox(width: 4),
                    Text(
                      controller.addressCtrl.text,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textMedium,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 14,
                      color: AppTheme.textMedium,
                    ),
                    SizedBox(width: 4),
                    Text(
                      controller.phoneCtrl.text,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textMedium,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Divider(height: 28),
                _previewRow(
                  "Tajriba",
                  "${controller.expCtrl.text.isNotEmpty ? controller.expCtrl.text : '1'} yil",
                ),
                Obx(
                  () => _previewRow(
                    "Ish vaqti",
                    "${controller.openTime.value} — ${controller.closeTime.value}",
                  ),
                ),
                Divider(height: 20),
                ...controller.servicesList.map(
                  (s) => _previewRow(
                    s['name'],
                    "${(s['price'] / 1000).toStringAsFixed(0)} ming so'm",
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).scale(begin: Offset(0.97, 0.97)),

          SizedBox(height: 28),
          Obx(
            () => _goldBtn(
              controller.isSubmitting.value ? "Yuklanmoqda..." : "Tasdiqlash ✓",
              controller.isSubmitting.value
                  ? null
                  : () => controller.submitRegistration(),
            ),
          ),
          SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () => controller.prevStep(),
              child: Text(
                "← Orqaga qaytish",
                style: GoogleFonts.poppins(
                  color: AppTheme.textMedium,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.paddingOf(Get.context!).bottom + 20),
        ],
      ),
    );
  }

  // ─── SHARED WIDGETS ───

  Widget _goldField(
    String label,
    String hint,
    IconData icon,
    TextEditingController ctrl,
    int delay, {
    TextInputType? inputType,
    int? maxLines,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppTheme.textMedium,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
              ),
            ],
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: inputType,
            inputFormatters: [
              if (inputType == TextInputType.number)
                FilteringTextInputFormatter.digitsOnly,
              if (inputType == TextInputType.phone)
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
              if (inputType == TextInputType.name)
                FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
            ],
            maxLines: maxLines ?? 1,
            style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: AppTheme.textLight,
                fontSize: 14,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  icon,
                  color: AppTheme.primary.withValues(alpha: 0.6),
                  size: 22,
                ),
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }

  Widget _priceRow(
    String label,
    IconData icon,
    TextEditingController ctrl,
    int delay,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: AppTheme.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                color: AppTheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: "0",
                hintStyle: GoogleFonts.poppins(color: AppTheme.textLight),
                border: InputBorder.none,
                suffixText: " so'm",
                suffixStyle: GoogleFonts.poppins(
                  color: AppTheme.textLight,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }

  Widget _timeCard(String label, RxString time) {
    return GestureDetector(
      onTap: () async {
        final t = await showTimePicker(
          context: Get.context!,
          initialTime: TimeOfDay(
            hour: int.parse(time.value.split(':')[0]),
            minute: int.parse(time.value.split(':')[1]),
          ),
        );
        if (t != null) {
          final h = t.hour.toString().padLeft(2, '0');
          final m = t.minute.toString().padLeft(2, '0');
          time.value = "$h:$m";
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: AppTheme.textMedium,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 6),
            Obx(
              () => Text(
                time.value,
                style: GoogleFonts.poppins(
                  color: AppTheme.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 4),
            Icon(
              Icons.access_time_rounded,
              color: AppTheme.primary.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: AppTheme.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _goldBtn(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: onTap != null ? AppTheme.goldGradient : null,
          color: onTap == null
              ? AppTheme.textLight.withValues(alpha: 0.2)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
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
              color: onTap != null ? Colors.white : AppTheme.textMedium,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}
