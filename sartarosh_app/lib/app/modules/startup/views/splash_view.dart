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

              // Heartbeat barber pulse logo
              Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: AppTheme.gold.withValues(alpha: 0.3),
                          blurRadius: 60,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(80),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/barber_pulse.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .scale(duration: 800.ms, curve: Curves.easeOutBack)
                  .fadeIn()
                  .then()
                  .scale(
                    begin: Offset(1.0, 1.0),
                    end: Offset(1.08, 1.08),
                    duration: 700.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    begin: Offset(1.0, 1.0),
                    end: Offset(0.93, 0.93),
                    duration: 700.ms,
                    curve: Curves.easeInOut,
                  ),

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
