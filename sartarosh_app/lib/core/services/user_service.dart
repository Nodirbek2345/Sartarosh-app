import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/input_sanitizer.dart';

class UserService extends GetxService {
  final name = "Mijoz".obs;
  final phone = "+998 -- --- -- --".obs;
  final isLogged = false.obs;
  final avatarBase64 = "".obs;
  final photoUrl = "".obs;
  final favoriteBarberIds = <String>[].obs;
  final isBarberMode = false.obs;
  final targetGender = 'male'.obs;
  final selectedRegion = ''.obs;
  final uid = ''.obs;
  final userRole = 'client'.obs;

  // GPS + Region dual-mode filter
  final filterMode = 'REGION'.obs; // 'GPS' or 'REGION'
  final userLat = 0.0.obs;
  final userLng = 0.0.obs;

  late FlutterSecureStorage _storage;

  String get currentUid {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    return firebaseUser?.uid ?? uid.value;
  }

  bool get isAuthenticated =>
      FirebaseAuth.instance.currentUser != null && isLogged.value;

  Future<UserService> init() async {
    _storage = const FlutterSecureStorage();

    name.value = await _storage.read(key: 'user_name') ?? "Mijoz";
    phone.value = await _storage.read(key: 'user_phone') ?? "+998 -- --- -- --";
    isLogged.value = (await _storage.read(key: 'is_logged')) == 'true';
    avatarBase64.value = await _storage.read(key: 'user_avatar') ?? "";
    photoUrl.value = await _storage.read(key: 'user_photo_url') ?? "";

    final favListString = await _storage.read(key: 'favorite_barbers');
    if (favListString != null && favListString.isNotEmpty) {
      try {
        favoriteBarberIds.value = List<String>.from(jsonDecode(favListString));
      } catch (e) {
        favoriteBarberIds.value = [];
      }
    }

    isBarberMode.value = (await _storage.read(key: 'is_barber_mode')) == 'true';
    targetGender.value = await _storage.read(key: 'target_gender') ?? 'male';
    selectedRegion.value = await _storage.read(key: 'selected_region') ?? '';
    userRole.value = await _storage.read(key: 'user_role') ?? 'client';
    uid.value = await _storage.read(key: 'user_uid') ?? '';
    filterMode.value = await _storage.read(key: 'filter_mode') ?? 'REGION';
    final storedLat = await _storage.read(key: 'user_lat');
    final storedLng = await _storage.read(key: 'user_lng');
    if (storedLat != null) userLat.value = double.tryParse(storedLat) ?? 0.0;
    if (storedLng != null) userLng.value = double.tryParse(storedLng) ?? 0.0;

    // Sync with Firebase Auth
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && uid.value.isEmpty) {
      uid.value = firebaseUser.uid;
      await _storage.write(key: 'user_uid', value: firebaseUser.uid);
    }

    // PRO: Auto-restore profile from Firestore after reinstall/device change
    // ALWAYS pull saved profile data from Firestore on app start to ensure UI
    // strictly mirrors the database (single source of truth).
    if (currentUid.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final serverName = data['name'] as String? ?? '';
          final serverPhone = data['phone'] as String? ?? '';
          final serverRole = data['role'] as String? ?? 'client';
          final serverAvatar = data['avatar'] as String? ?? '';
          final serverPhotoUrl = data['photoUrl'] as String? ?? '';
          final serverTargetGender = data['targetGender'] as String? ?? '';

          if (serverName.isNotEmpty && serverName != "Mijoz") {
            name.value = serverName;
            await _storage.write(key: 'user_name', value: serverName);
          }
          if (serverPhone.isNotEmpty) {
            phone.value = serverPhone;
            await _storage.write(key: 'user_phone', value: serverPhone);
          }
          if (serverRole.isNotEmpty) {
            userRole.value = serverRole;
            await _storage.write(key: 'user_role', value: serverRole);
          }
          if (serverAvatar.isNotEmpty) {
            avatarBase64.value = serverAvatar;
            await _storage.write(key: 'user_avatar', value: serverAvatar);
          }
          if (serverPhotoUrl.isNotEmpty) {
            photoUrl.value = serverPhotoUrl;
            await _storage.write(key: 'user_photo_url', value: serverPhotoUrl);
          }
          if (serverTargetGender.isNotEmpty) {
            targetGender.value = serverTargetGender;
            await _storage.write(
              key: 'target_gender',
              value: serverTargetGender,
            );
          }

          // Mark as logged in since Firestore profile exists
          isLogged.value = true;
          await _storage.write(key: 'is_logged', value: 'true');
        }
      } catch (_) {}
    }

    // PRO: Auto role-recovery — fix desync for users stuck as 'client'
    if (currentUid.isNotEmpty && userRole.value == 'client') {
      try {
        final barberCheck = await FirebaseFirestore.instance
            .collection('barbers')
            .where('uid', isEqualTo: currentUid)
            .limit(1)
            .get();
        if (barberCheck.docs.isNotEmpty) {
          userRole.value = 'barber';
          isBarberMode.value = true;
          await _storage.write(key: 'user_role', value: 'barber');
          await _storage.write(key: 'is_barber_mode', value: 'true');
          // Also sync to Firestore users collection
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUid)
                .set({'role': 'barber'}, SetOptions(merge: true));
          } catch (_) {}
        }
      } catch (_) {}
    }

    // PRO: One-time migration — push local profile to Firestore
    // This covers the case where user set a custom name on an older version
    // that only saved to local storage. Now we auto-sync it to Firestore
    // BEFORE they potentially delete the app.
    if (currentUid.isNotEmpty &&
        isLogged.value &&
        name.value != "Mijoz" &&
        name.value.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();
        if (userDoc.exists) {
          final serverName = userDoc.data()?['name'] ?? '';
          // If local name differs from server name → push local to server
          if (serverName != name.value) {
            final Map<String, dynamic> syncData = {'name': name.value};
            if (phone.value.isNotEmpty && phone.value != "+998 -- --- -- --") {
              syncData['phone'] = phone.value;
            }
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUid)
                .set(syncData, SetOptions(merge: true));
          }
        }
      } catch (_) {}
    }

    return this;
  }

  void toggleFavorite(String barberId) async {
    if (favoriteBarberIds.contains(barberId)) {
      favoriteBarberIds.remove(barberId);
    } else {
      favoriteBarberIds.add(barberId);
    }
    await _storage.write(
      key: 'favorite_barbers',
      value: jsonEncode(favoriteBarberIds.toList()),
    );
  }

  bool isFavorite(String barberId) {
    return favoriteBarberIds.contains(barberId);
  }

  void updateAvatar(String base64Image) async {
    avatarBase64.value = base64Image;
    await _storage.write(key: 'user_avatar', value: base64Image);

    if (currentUid.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();
        if (userDoc.exists) {
          await userDoc.reference.update({'avatar': base64Image});
        }

        // Sync to barber profile as well if they are a barber
        if (userRole.value == 'barber') {
          final barberSnapshot = await FirebaseFirestore.instance
              .collection('barbers')
              .where('uid', isEqualTo: currentUid)
              .get();
          if (barberSnapshot.docs.isNotEmpty) {
            await barberSnapshot.docs.first.reference.update({
              'image': base64Image,
            });
          }
        }
      } catch (e) {
        // Exception intentionally ignored for minor avatar sync issues
      }
    }
  }

  void updatePhotoUrl(String url) async {
    photoUrl.value = url;
    await _storage.write(key: 'user_photo_url', value: url);
  }

  void updateUid(String newUid) async {
    uid.value = newUid;
    await _storage.write(key: 'user_uid', value: newUid);
  }

  void toggleBarberMode() async {
    isBarberMode.value = !isBarberMode.value;
    await _storage.write(
      key: 'is_barber_mode',
      value: isBarberMode.value.toString(),
    );
  }

  void setTargetGender(String gender) async {
    targetGender.value = gender;
    await _storage.write(key: 'target_gender', value: gender);
    final uidToUpdate = currentUid;
    if (uidToUpdate.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uidToUpdate)
            .set({'targetGender': gender}, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  void setRegion(String region) async {
    selectedRegion.value = region;
    await _storage.write(key: 'selected_region', value: region);
  }

  /// Switch to GPS mode — clears region, stores coords
  void setGpsMode(double lat, double lng) async {
    filterMode.value = 'GPS';
    userLat.value = lat;
    userLng.value = lng;
    selectedRegion.value = '';
    await _storage.write(key: 'filter_mode', value: 'GPS');
    await _storage.write(key: 'user_lat', value: lat.toString());
    await _storage.write(key: 'user_lng', value: lng.toString());
    await _storage.write(key: 'selected_region', value: '');

    if (currentUid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .set({'region': ''}, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Switch to Region mode — clears GPS coords
  void setRegionMode(String region) async {
    filterMode.value = 'REGION';
    selectedRegion.value = region;
    userLat.value = 0.0;
    userLng.value = 0.0;
    await _storage.write(key: 'filter_mode', value: 'REGION');
    await _storage.write(key: 'selected_region', value: region);
    await _storage.write(key: 'user_lat', value: '0.0');
    await _storage.write(key: 'user_lng', value: '0.0');

    if (currentUid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .set({'region': region}, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  void setUserRole(String role) async {
    userRole.value = role;
    await _storage.write(key: 'user_role', value: role);
  }

  void updateUser(String rawName, String rawPhone) async {
    final newName = InputSanitizer.sanitizeText(rawName);
    final newPhone = InputSanitizer.sanitizePhone(rawPhone);

    if (newName.isNotEmpty) {
      name.value = newName;
      await _storage.write(key: 'user_name', value: newName);
    }
    if (newPhone.isNotEmpty) {
      phone.value = newPhone;
      await _storage.write(key: 'user_phone', value: newPhone);
    }
    isLogged.value = true;
    await _storage.write(key: 'is_logged', value: 'true');

    // PRO FIX: Sync to Firestore so reinstalling app doesn't lose the custom name/phone
    if (currentUid.isNotEmpty) {
      try {
        final Map<String, dynamic> updateData = {};
        if (newName.isNotEmpty) updateData['name'] = newName;
        if (newPhone.isNotEmpty) updateData['phone'] = newPhone;

        if (updateData.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .set(updateData, SetOptions(merge: true));

          // If the user is also a barber, sync their name to the barber doc as well
          if (userRole.value == 'barber') {
            final snap = await FirebaseFirestore.instance
                .collection('barbers')
                .where('uid', isEqualTo: currentUid)
                .limit(1)
                .get();
            if (snap.docs.isNotEmpty) {
              if (newName.isNotEmpty) {
                await snap.docs.first.reference.update({'name': newName});
              }
            }
          }
        }
      } catch (_) {}
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    name.value = "Mijoz";
    phone.value = "+998 -- --- -- --";
    isLogged.value = false;
    isBarberMode.value = false;
    userRole.value = 'client';
    uid.value = '';
    avatarBase64.value = '';
    photoUrl.value = '';
    targetGender.value = 'male';
    selectedRegion.value = '';
    filterMode.value = 'REGION';
    userLat.value = 0.0;
    userLng.value = 0.0;
    favoriteBarberIds.clear();
    await _storage.deleteAll();
  }
}
