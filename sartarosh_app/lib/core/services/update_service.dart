import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/theme/app_theme.dart';

class UpdateService extends GetxService {
  String currentVersion = "1.0.0";
  final isDownloading = false.obs;
  final downloadProgress = 0.0.obs;

  Future<UpdateService> init() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
    } catch (_) {}
    return this;
  }

  void checkUpdate() async {
    try {
      final dio = Dio();
      // Ochiq Github User Content orqali pubspec ni to'g'ridan-to'g'ri tekshiramiz.
      // Bu API limit (60/soat) cheklovini to'liq chetlab o'tadi!
      final response = await dio.get(
        'https://raw.githubusercontent.com/Nodirbek2345/Sartarosh-app/refs/heads/master/sartarosh_app/pubspec.yaml',
      );

      final content = response.data?.toString() ?? '';

      // "version: 3.3.2+224" -> "3.3.2" niamiz
      final versionMatch = RegExp(
        r'version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
      ).firstMatch(content);

      if (versionMatch == null) return;

      final latestVersion = versionMatch.group(1);

      // Har doim eng so'nggi reliz uchun ochiq APK manzili
      final updateUrl =
          'https://github.com/Nodirbek2345/Sartarosh-app/releases/latest/download/app-release.apk';

      final releaseNotes =
          'Ilovaning yangi ($latestVersion) versiyasi mavjud! Xatolar tuzatildi va tezlik oshirildi. Iltimos, darhol yangilang.';

      if (latestVersion != null &&
          _isUpdateAvailable(currentVersion, latestVersion)) {
        _showUpdateDialog(
          latestVersion: latestVersion,
          isRequired: true, // Force update for the new version
          updateUrl: updateUrl,
          releaseNotes: releaseNotes,
        );
      }
    } catch (e) {
      debugPrint("Raw Github Update check failed: $e");
    }
  }

  bool _isUpdateAvailable(String current, String latest) {
    // Basic semver check
    final currentParts = current
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final latestParts = latest
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    for (int i = 0; i < 3; i++) {
      final cur = i < currentParts.length ? currentParts[i] : 0;
      final lat = i < latestParts.length ? latestParts[i] : 0;
      if (lat > cur) return true;
      if (lat < cur) return false;
    }
    return false;
  }

  Future<void> _downloadAndInstallApp(String url) async {
    isDownloading.value = true;
    downloadProgress.value = 0.0;
    try {
      var dir = await getExternalStorageDirectory();
      dir ??= await getTemporaryDirectory();
      final filePath = '${dir.path}/sartarosh_update.apk';

      final dio = Dio();
      // Dio automatically handles 302 redirects for Github Releases
      await dio.download(
        url,
        filePath,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
          }
        },
      );

      await OpenFilex.open(filePath);
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Ilovani yuklab olishda xatolik yuz berdi. Internetni tekshiring.",
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    } finally {
      isDownloading.value = false;
    }
  }

  void _showUpdateDialog({
    required String latestVersion,
    required bool isRequired,
    required String updateUrl,
    required String releaseNotes,
  }) {
    isDownloading.value = false;
    downloadProgress.value = 0.0;

    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Obx(() {
            if (isDownloading.value) {
              // === NEW PREMIUM LIGHT UI: LOADING BAR ===
              return Container(
                padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_download_rounded,
                      color: Color(0xFFD4AF37), // Premium Gold
                      size: 64,
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Yangilanish yuklanmoqda...",
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Iltimos, dasturdan chiqmang va internetni o'chirmang.",
                      style: GoogleFonts.poppins(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    Stack(
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: downloadProgress.value,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      "${(downloadProgress.value * 100).toStringAsFixed(0)}%",
                      style: GoogleFonts.poppins(
                        color: Color(0xFFD4AF37),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            // === STANDARD UPDATE DIALOG (COMPACT REDESIGN) ===
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: Color(0xFFD4AF37),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    "Yangi versiya mavjud!",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // New Version Info
                  Text(
                    "Versiya: $latestVersion",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Current Version
                  Text(
                    "Sizdagi versiya: $currentVersion",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (updateUrl.toLowerCase().endsWith('.apk') ||
                            updateUrl.contains('github.com')) {
                          _downloadAndInstallApp(updateUrl);
                        } else {
                          final uri = Uri.parse(updateUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                          if (!isRequired) Get.back();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Hozir yangilash",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ), // Dialog ends
      ), // PopScope ends
      barrierDismissible: false,
    );
  }
}
