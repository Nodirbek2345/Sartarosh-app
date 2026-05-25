import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:ui';
import 'app/routes/app_pages.dart';
import 'core/theme/app_theme.dart';

import 'core/services/user_service.dart';
import 'core/services/update_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Barcha Flutter Xatolarini ushlash (Release uchun)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('⚠️ FlutterError: ${details.exceptionAsString()}');
  };

  // Barcha Dart Asinxron xatolarini ushlash (App qulashini oldini oladi)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('⚠️ PlatformError: $error');
    debugPrint('$stack');
    return true;
  };

  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyAzt8n0nHnj_JdoC3ZN5xjEXFX2yO4yWvY",
        appId: "1:328525443303:web:cf3bb05758bed9cc25f242",
        messagingSenderId: "328525443303",
        projectId: "sartarosh-eaf90",
        authDomain: "sartarosh-eaf90.firebaseapp.com",
        storageBucket: "sartarosh-eaf90.firebasestorage.app",
      ),
    );
    // OTA orqali (GitHub Releases) o'rnatilganda Play Integrity ishlamaydi va
    // "permission-denied" xatosini beradi. Shuning uchun App Check vaqtincha olib tushildi.
    // await FirebaseAppCheck.instance.activate();
  } catch (e) {
    debugPrint('⚠️ Firebase init error: $e');
  }

  await Get.putAsync(() => UserService().init());
  await Get.putAsync(() => UpdateService().init());
  await Get.putAsync(() => NotificationService().init());

  runApp(
    GetMaterialApp(
      title: "Sartarosh",
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      theme: AppTheme.luxuryTheme,
      defaultTransition: Transition.fade,
    ),
  );
}
