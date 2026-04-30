import 'package:sartarosh_app/core/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/notification_service.dart';
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
        backgroundColor: AppTheme.danger,
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
        clientId:
            '328525443303-d5moa5bimo799ts4regh44uuhu21nsen.apps.googleusercontent.com',
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
        final googleName = InputSanitizer.sanitizeText(
          user.displayName ?? 'Foydalanuvchi',
        );
        final inputPhone = InputSanitizer.sanitizePhone(phoneCtrl.text.trim());
        final userPhoto = user.photoURL ?? '';

        // 1. Phone collision check (Prevent Number hijacking)
        final phoneCheck = await _firestore
            .collection('users')
            .where('phone', isEqualTo: inputPhone)
            .get();

        if (phoneCheck.docs.isNotEmpty) {
          final existingAccountUid = phoneCheck.docs.first.id;
          if (existingAccountUid != user.uid) {
            // This phone belongs to a DIFFERENT Google account!
            isLoading.value = false;
            await googleSignIn.signOut();
            await FirebaseAuth.instance.signOut();

            Get.snackbar(
              "Xatolik",
              "Bu raqam ($inputPhone) boshqa hisobga ulangan! O'sha Google akkauntdan kiring.",
              backgroundColor: AppTheme.danger,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              duration: Duration(seconds: 5),
            );
            return;
          }
        }

        // Save UID first (critical for security)
        userService.updateUid(user.uid);

        // Save Google photo URL
        if (userPhoto.isNotEmpty) {
          userService.updatePhotoUrl(userPhoto);
        }

        // 2. Fetch User Document by UID
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        String savedRole = 'client';
        String finalName = googleName;
        String finalPhone = inputPhone;
        bool isReturningUser = false;

        final updateData = <String, dynamic>{
          'email': user.email ?? '',
          'photoUrl': userPhoto,
          'lastLogin': FieldValue.serverTimestamp(),
        };

        if (userDoc.exists) {
          // RESTORE EXISTING PROFILE! (Do NOT overwrite name/phone from input/google)
          isReturningUser = true;
          final data = userDoc.data()!;
          if (data.containsKey('role')) savedRole = data['role'] ?? 'client';

          if (data.containsKey('name') &&
              data['name'] != null &&
              data['name'].toString().trim().isNotEmpty) {
            finalName = data['name'];
          } else {
            // Extreme fallback: Check if they are a barber and pull name from there
            try {
              final barberDocs = await _firestore
                  .collection('barbers')
                  .where('uid', isEqualTo: user.uid)
                  .limit(1)
                  .get();
              if (barberDocs.docs.isNotEmpty) {
                final bName = barberDocs.docs.first.data()['name'];
                if (bName != null && bName.toString().trim().isNotEmpty) {
                  finalName = bName;
                } else {
                  finalName = googleName;
                }
              } else {
                finalName = googleName;
              }
            } catch (_) {
              finalName = googleName;
            }
          }

          if (data.containsKey('phone')) {
            finalPhone = data['phone'] ?? inputPhone;
          }
        } else {
          // BRAND NEW PROFILE
          updateData['uid'] = user.uid;
          updateData['name'] = finalName;
          updateData['phone'] = finalPhone;
          updateData['role'] = 'client';
          updateData['createdAt'] = FieldValue.serverTimestamp();
        }

        // Update Backend
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(updateData, SetOptions(merge: true));

        // 3. Update Local Storage and State correctly
        userService.updateUser(finalName, finalPhone);
        userService.setUserRole(savedRole);

        if (userDoc.exists) {
          final data = userDoc.data()!;
          if (data.containsKey('avatar') &&
              data['avatar'] != null &&
              data['avatar'].toString().isNotEmpty) {
            userService.updateAvatar(data['avatar']);
          }
        }

        // Ensure Barber mode is off when initially logging in to prevent ghost states
        if (userService.isBarberMode.value) {
          userService.toggleBarberMode();
        }

        // Upload FCM token for new user
        if (Get.isRegistered<NotificationService>()) {
          Get.find<NotificationService>().uploadTokenIfNeeded();
        }

        if (isReturningUser) {
          // PRO: For returning users — show name confirmation dialog
          // so they can fix their name immediately after reinstall
          final nameCtrl = TextEditingController(text: finalName);
          final confirmedName = await Get.dialog<String>(
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Qaytib kelganingiz bilan! 🎉",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ismingiz to'g'rimi? Kerak bo'lsa o'zgartiring:",
                    style: TextStyle(color: AppTheme.textMedium, fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Ismingiz",
                      prefixIcon: Icon(
                        Icons.person_rounded,
                        color: AppTheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppTheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: nameCtrl.text.trim()),
                  child: Text(
                    "Davom etish →",
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            barrierDismissible: false,
          );

          // If user edited the name, update everywhere
          if (confirmedName != null &&
              confirmedName.isNotEmpty &&
              confirmedName != finalName) {
            finalName = confirmedName;
            userService.updateUser(finalName, finalPhone);
          }

          Get.snackbar(
            "Muvaffaqiyatli!",
            "Xush kelibsiz, $finalName!",
            backgroundColor: Color(0xFFC9A96E),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );

          // Returning user → skip welcome, go straight to home
          Get.offAllNamed('/home');
        } else {
          // Brand new user → go through onboarding (role + gender selection)
          Get.snackbar(
            "Muvaffaqiyatli!",
            "Xush kelibsiz, $finalName!",
            backgroundColor: Color(0xFFC9A96E),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );

          Get.offAllNamed('/welcome');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "Xatolik yuz berdi";
      if (e.code == 'popup-closed-by-user') {
        message = "Kirish bekor qilindi";
      } else if (e.code == 'account-exists-with-different-credential') {
        message = "Bu akkaunt boshqa usulda ro'yxatdan o'tgan";
      } else {
        message = "Tizimga kirishda xatolik yuz berdi";
      }
      Get.snackbar(
        "Xatolik",
        message,
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Tizimga kirishda xatolik yuz berdi. Qaytadan urinib ko'ring.",
        backgroundColor: AppTheme.danger,
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
