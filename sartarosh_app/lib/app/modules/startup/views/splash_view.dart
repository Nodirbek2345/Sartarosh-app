import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/splash_controller.dart';
import '../../../../core/theme/app_theme.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.darkGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 3),

              // Gold scissor icon
              Container(
                    padding: EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.goldGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.content_cut_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  )
                  .animate()
                  .scale(duration: 800.ms, curve: Curves.easeOutBack)
                  .fadeIn(),

              SizedBox(height: 40),

              Text(
                    "SARTAROSH",
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.3)
                  .shimmer(
                    duration: 1200.ms,
                    delay: 1000.ms,
                    color: Colors.white,
                    angle: 1,
                  ),

              SizedBox(height: 12),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "PREMIUM  BARBER  SERVICE",
                  style: GoogleFonts.poppins(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms),

              Spacer(flex: 2),

              Text(
                "Siz uchun qulay va sifatli xizmat",
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ).animate().fadeIn(delay: 1000.ms),

              SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
