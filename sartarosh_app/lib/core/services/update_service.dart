import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final doc = await _firestore.collection('settings').doc('app').get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final latestVersion = data['latestVersion'] as String?;
      final isRequired = data['isRequired'] as bool? ?? false;
      final updateUrl = data['updateUrl'] as String?;
      final releaseNotes =
          data['releaseNotes'] ??
          'Ilovaning yangi versiyasi ($latestVersion) chiqdi. Yangi imkoniyatlardan foydalanish hoziroq yuklab oling.';

      if (latestVersion != null &&
          _isUpdateAvailable(currentVersion, latestVersion)) {
        _showUpdateDialog(
          latestVersion: latestVersion,
          isRequired: isRequired,
          updateUrl:
              updateUrl ??
              "https://play.google.com/store/apps/details?id=com.sartarosh.app",
          releaseNotes: releaseNotes,
        );
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
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
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Obx(() {
          if (isDownloading.value) {
            // === NEW DARK UI: LOADING BAR (IMAGE 2) ===
            return Container(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.9), // Dark background
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Loading",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  Stack(
                    children: [
                      Container(
                        height: 24,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors
                              .transparent, // Background of the bar string
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: downloadProgress.value,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            "${(downloadProgress.value * 100).toStringAsFixed(0)}%",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          // === STANDARD UPDATE DIALOG (IMAGE 1) ===
          return Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.download_rounded,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Yangilanish mavjud!",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
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
                Text(
                  "Sizdagi versiya: $currentVersion",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isRequired)
                      TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          "KEYINROQ",
                          style: GoogleFonts.poppins(
                            color: Colors.black45,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    if (!isRequired) SizedBox(width: 8),
                    ElevatedButton(
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
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "YUKLAB OLISH",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
      barrierDismissible: !isRequired,
    );
  }
}
