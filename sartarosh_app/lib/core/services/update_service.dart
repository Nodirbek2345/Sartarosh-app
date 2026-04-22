import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

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
      // YALANG'OCH pubspec o'rniga, to'g'ridan-to'g'ri so'nggi RELIZNI tekshiramiz.
      // Shunda Github Actions to'liq qurib, ob'ektni qo'shmaguncha yangilanish chiqmaydi!
      final response = await dio.get(
        'https://api.github.com/repos/Nodirbek2345/Sartarosh-app/releases/latest',
      );

      final latestTag = response.data['tag_name'] as String?;
      final releaseName = response.data['name'] as String?;
      final assets = response.data['assets'] as List?;

      if (latestTag == null || assets == null || assets.isEmpty) return;

      // Extract version from tag_name or release_name using regex e.g. "v1.0.14" -> "1.0.14"
      // If the tag is something else, we can fallback to extracting from release body or name
      final bodyText = response.data['body']?.toString() ?? "";
      final searchString = "$latestTag $releaseName $bodyText";
      final versionMatch = RegExp(
        r'([0-9]+\.[0-9]+\.[0-9]+)',
      ).firstMatch(searchString);

      if (versionMatch == null) return;

      final latestVersion = versionMatch.group(1);

      // We must make sure there is an apk asset inside this release
      String? apkDownloadUrl;
      for (var asset in assets) {
        final dlUrl = asset['browser_download_url'] as String?;
        if (dlUrl != null && dlUrl.endsWith('.apk')) {
          apkDownloadUrl = dlUrl;
          break;
        }
      }

      if (apkDownloadUrl == null) return; // No APK built yet for this release

      final updateUrl = apkDownloadUrl; // Directly use the APK url
      final releaseNotes = response.data['body']?.toString().isNotEmpty == true
          ? response.data['body'].toString()
          : 'Ilovaning yangi versiyasi ($latestVersion) chiqdi. Yangi imkoniyatlardan foydalanish hoziroq yuklab oling.';

      if (latestVersion != null &&
          _isUpdateAvailable(currentVersion, latestVersion)) {
        _showUpdateDialog(
          latestVersion: latestVersion,
          isRequired: false, // We will force it anyway in the UI
          updateUrl: updateUrl,
          releaseNotes: releaseNotes,
        );
      }
    } catch (e) {
      debugPrint("Update check from GitHub failed: $e");
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

  Future<String> _resolveGithubUrl(String url) async {
    if (url.contains('github.com') && !url.endsWith('.apk')) {
      try {
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2) {
          final owner = pathSegments[0];
          final repo = pathSegments[1];
          final apiUrl =
              "https://api.github.com/repos/$owner/$repo/releases/latest";
          final dio = Dio();
          final response = await dio.get(apiUrl);
          final assets = response.data['assets'] as List?;
          if (assets != null) {
            for (var asset in assets) {
              final dlUrl = asset['browser_download_url'] as String?;
              if (dlUrl != null && dlUrl.endsWith('.apk')) {
                return dlUrl;
              }
            }
          }
        }
      } catch (e) {
        debugPrint("GitHub release URL ni resolve qilishda xatolik: $e");
      }
    }
    return url;
  }

  Future<void> _downloadAndInstallApp(String url) async {
    isDownloading.value = true;
    downloadProgress.value = 0.0;
    try {
      final resolvedUrl = await _resolveGithubUrl(url);

      var dir = await getExternalStorageDirectory();
      dir ??= await getTemporaryDirectory();
      final filePath = '${dir.path}/sartarosh_update.apk';

      final dio = Dio();
      await dio.download(
        resolvedUrl,
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
        "Ilovani yuklab olishda xatolik yuz berdi. URL ni tekshiring.",
        backgroundColor: Colors.redAccent,
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

            // === STANDARD UPDATE DIALOG (IMAGE 1) - PREMIUM REDESIGN ===
            return Container(
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFD4AF37).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      color: Color(0xFFD4AF37),
                      size: 48,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Yangi versiya mavjud!",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    releaseNotes,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(height: 8),
                  Text(
                    "Sizdagi versiya: $currentVersion",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Agar URL .apk bilan tugasa YOKI Github Releases bo'lsa
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
                        backgroundColor: Color(0xFFD4AF37),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Hozir yangilash",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Removed the trailing ] because we simplified Row to SizedBox.
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
