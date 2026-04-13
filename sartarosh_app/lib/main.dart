import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/routes/app_pages.dart';
import 'core/theme/app_theme.dart';

import 'core/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync(() => UserService().init());

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
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

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
