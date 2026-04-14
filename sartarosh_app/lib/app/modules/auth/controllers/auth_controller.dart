import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/input_sanitizer.dart';

class AuthController extends GetxController {
  final phoneCtrl = TextEditingController();
  final isLoading = false.obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Validate phone and go to Google Sign-In step
  void goToGoogleStep() {
    final sanitizedPhone = InputSanitizer.sanitizePhone(phoneCtrl.text);
    if (!InputSanitizer.isValidPhone(sanitizedPhone)) {
      Get.snackbar(
        "Xatolik",
        "Iltimos, to'g'ri raqam kiriting (9+ raqam)",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.toNamed('/otp');
  }

  /// Google Sign-In via Native Google SDK
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      // Trigger Native Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the login flow
        isLoading.value = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      if (user != null) {
        final userService = Get.find<UserService>();
        final userName = InputSanitizer.sanitizeText(
          user.displayName ?? 'Foydalanuvchi',
        );
        final userPhone = InputSanitizer.sanitizePhone(phoneCtrl.text.trim());
        final userPhoto = user.photoURL ?? '';

        // Save UID first (critical for security)
        userService.updateUid(user.uid);
        userService.updateUser(userName, userPhone);

        // Save Google photo URL
        if (userPhoto.isNotEmpty) {
          userService.updatePhotoUrl(userPhoto);
        }

        // Save to Firestore backend with UID as document key
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': userName,
          'phone': userPhone,
          'email': user.email ?? '',
          'photoUrl': userPhoto,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        Get.snackbar(
          "Muvaffaqiyatli!",
          "Xush kelibsiz, $userName!",
          backgroundColor: Color(0xFFC9A96E),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Go to welcome (gender selection)
        Get.offAllNamed('/welcome');
      }
    } on FirebaseAuthException catch (e) {
      String message = "Xatolik yuz berdi";
      if (e.code == 'popup-closed-by-user') {
        message = "Kirish bekor qilindi";
      } else if (e.code == 'account-exists-with-different-credential') {
        message = "Bu akkaunt boshqa usulda ro'yxatdan o'tgan";
      } else {
        message = "Firebase xatolik: ${e.code}";
      }
      Get.snackbar(
        "Xatolik",
        message,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Xatolik yuz berdi: ${e.toString()}",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 6),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void goToHome() {
    Get.offAllNamed('/home');
  }

  @override
  void onClose() {
    phoneCtrl.dispose();
    super.onClose();
  }
}
