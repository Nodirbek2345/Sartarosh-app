import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/input_sanitizer.dart';

/// UserService — foydalanuvchi holati va persist qiluvchi servis.
/// ⚠️ FlutterSecureStorage ISHLATILMAYDI — Android'da restart'da
///    Keystore kaliti yo'qolishi bilan barcha ma'lumotlarni o'chirib
///    yuborishi mumkin. Buning o'rniga SharedPreferences ishlatiladi.
class UserService extends GetxService {
  final name = "Mijoz".obs;
  final phone = "+998 -- --- -- --".obs;
  final isLogged = false.obs;
  final avatarBase64 = "".obs;
  final photoUrl = "".obs;
  final favoriteBarberIds = <String>[].obs;
  final isBarberMode = false.obs;
  final targetGender = 'male'.obs;

  final audienceProfile = ''.obs;
  final selectedRegion = ''.obs;
  final uid = ''.obs;
  final userRole = 'client'.obs;

  // GPS + Region dual-mode filter
  final filterMode = 'REGION'.obs;
  final userLat = 0.0.obs;
  final userLng = 0.0.obs;

  late SharedPreferences _prefs;

  String get currentUid {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    return firebaseUser?.uid ?? uid.value;
  }

  bool get isAuthenticated =>
      FirebaseAuth.instance.currentUser != null && isLogged.value;

  bool get hasLocation {
    if (filterMode.value == 'GPS') {
      return userLat.value != 0.0 && userLng.value != 0.0;
    }
    return selectedRegion.value.isNotEmpty;
  }

  // ─── Private helpers ───
  Future<void> _write(String key, String? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }

  String? _read(String key) => _prefs.getString(key);

  Future<void> _writeBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool _readBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  Future<UserService> init() async {
    _prefs = await SharedPreferences.getInstance();

    // ─── Load local ───
    name.value = _read('user_name') ?? "Mijoz";
    phone.value = _read('user_phone') ?? "+998 -- --- -- --";
    isLogged.value = _readBool('is_logged');
    avatarBase64.value = _read('user_avatar') ?? "";
    photoUrl.value = _read('user_photo_url') ?? "";

    final favListString = _read('favorite_barbers');
    if (favListString != null && favListString.isNotEmpty) {
      try {
        favoriteBarberIds.value = List<String>.from(jsonDecode(favListString));
      } catch (_) {
        favoriteBarberIds.value = [];
      }
    }

    isBarberMode.value = _readBool('is_barber_mode');
    targetGender.value = _read('target_gender') ?? 'male';
    audienceProfile.value = _read('audience_profile') ?? '';
    userRole.value = _read('user_role') ?? 'client';
    uid.value = _read('user_uid') ?? '';

    filterMode.value = _read('filter_mode') ?? 'REGION';
    selectedRegion.value = _read('selected_region') ?? '';
    userLat.value = _prefs.getDouble('user_lat') ?? 0.0;
    userLng.value = _prefs.getDouble('user_lng') ?? 0.0;

    // ─── Sync with Firebase Auth ───
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && uid.value.isEmpty) {
      uid.value = firebaseUser.uid;
      await _write('user_uid', firebaseUser.uid);
    }

    // ─── Auto-restore profile from Firestore ───
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
          final serverAudience = data['audienceProfile'] as String? ?? '';
          final serverRegion = data['region'] as String? ?? '';

          if (serverName.isNotEmpty && serverName != "Mijoz") {
            name.value = serverName;
            await _write('user_name', serverName);
          }
          if (serverPhone.isNotEmpty) {
            phone.value = serverPhone;
            await _write('user_phone', serverPhone);
          }
          if (serverRole.isNotEmpty) {
            userRole.value = serverRole;
            await _write('user_role', serverRole);
            if (serverRole == 'barber') {
              isBarberMode.value = true;
              await _writeBool('is_barber_mode', true);
            }
          }
          if (serverAvatar.isNotEmpty) {
            avatarBase64.value = serverAvatar;
            await _write('user_avatar', serverAvatar);
          }
          if (serverPhotoUrl.isNotEmpty) {
            photoUrl.value = serverPhotoUrl;
            await _write('user_photo_url', serverPhotoUrl);
          }
          if (serverTargetGender.isNotEmpty) {
            targetGender.value = serverTargetGender;
            await _write('target_gender', serverTargetGender);
          }
          if (serverAudience.isNotEmpty) {
            audienceProfile.value = serverAudience;
            await _write('audience_profile', serverAudience);
          }
          // Restore region from Firestore if local is empty
          if (selectedRegion.value.isEmpty && serverRegion.isNotEmpty) {
            selectedRegion.value = serverRegion;
            await _write('selected_region', serverRegion);
            await _write('filter_mode', 'REGION');
            filterMode.value = 'REGION';
          }

          isLogged.value = true;
          await _writeBool('is_logged', true);
        }
      } catch (_) {}
    }

    // ─── Auto role-recovery ───
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
          await _write('user_role', 'barber');
          await _writeBool('is_barber_mode', true);
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUid)
                .set({'role': 'barber'}, SetOptions(merge: true));
          } catch (_) {}
        }
      } catch (_) {}
    }

    // ─── Restore favorites from Firestore if local empty ───
    if (currentUid.isNotEmpty && favoriteBarberIds.isEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();
        if (userDoc.exists) {
          final favs = userDoc.data()?['favorites'];
          if (favs != null && favs is List) {
            favoriteBarberIds.value = List<String>.from(favs);
            await _write(
              'favorite_barbers',
              jsonEncode(favoriteBarberIds.toList()),
            );
          }
        }
      } catch (_) {}
    }

    // ─── One-time profile sync to Firestore ───
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
    await _write('favorite_barbers', jsonEncode(favoriteBarberIds.toList()));
    // Sync to Firestore so favorites persist across reinstalls
    if (currentUid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .set({
              'favorites': favoriteBarberIds.toList(),
            }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  bool isFavorite(String barberId) {
    return favoriteBarberIds.contains(barberId);
  }

  void updateAvatar(String base64Image) async {
    avatarBase64.value = base64Image;
    await _write('user_avatar', base64Image);

    if (currentUid.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();
        if (userDoc.exists) {
          await userDoc.reference.update({'avatar': base64Image});
        }

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
      } catch (_) {}
    }
  }

  void updatePhotoUrl(String url) async {
    photoUrl.value = url;
    await _write('user_photo_url', url);
  }

  void updateUid(String newUid) async {
    uid.value = newUid;
    await _write('user_uid', newUid);
  }

  void toggleBarberMode() async {
    isBarberMode.value = !isBarberMode.value;
    await _writeBool('is_barber_mode', isBarberMode.value);
  }

  void setTargetGender(String gender) async {
    targetGender.value = gender;
    await _write('target_gender', gender);
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

  Future<void> applyWelcomeMaleAudience() async {
    targetGender.value = 'male';
    audienceProfile.value = 'male_classic';
    await _write('target_gender', 'male');
    await _write('audience_profile', 'male_classic');
    final uidToUpdate = currentUid;
    if (uidToUpdate.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uidToUpdate)
            .set({
              'targetGender': 'male',
              'audienceProfile': 'male_classic',
              'exploreHint': 'nearby_barbers',
            }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> applyWelcomeFemaleAudience() async {
    targetGender.value = 'female';
    audienceProfile.value = 'female_beauty';
    await _write('target_gender', 'female');
    await _write('audience_profile', 'female_beauty');
    final uidToUpdate = currentUid;
    if (uidToUpdate.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uidToUpdate)
            .set({
              'targetGender': 'female',
              'audienceProfile': 'female_beauty',
              'exploreHint': 'salon_categories_priority',
            }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  void setRegion(String region) async {
    selectedRegion.value = region;
    await _write('selected_region', region);
    await _write('filter_mode', 'REGION');
    filterMode.value = 'REGION';

    if (currentUid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .set({'region': region}, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  void setGpsMode(double lat, double lng) async {
    filterMode.value = 'GPS';
    userLat.value = lat;
    userLng.value = lng;
    selectedRegion.value = '';

    await _write('filter_mode', 'GPS');
    await _prefs.setDouble('user_lat', lat);
    await _prefs.setDouble('user_lng', lng);
    await _write('selected_region', '');

    if (currentUid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .set({'lat': lat, 'lng': lng}, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  void setRegionMode(String region) async {
    filterMode.value = 'REGION';
    selectedRegion.value = region;
    userLat.value = 0.0;
    userLng.value = 0.0;

    await _write('filter_mode', 'REGION');
    await _write('selected_region', region);
    await _prefs.setDouble('user_lat', 0.0);
    await _prefs.setDouble('user_lng', 0.0);

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
    await _write('user_role', role);
    // Keep isBarberMode in sync with role
    final isBrb = role == 'barber';
    isBarberMode.value = isBrb;
    await _writeBool('is_barber_mode', isBrb);
  }

  void updateUser(String rawName, String rawPhone) async {
    final newName = InputSanitizer.sanitizeText(rawName);
    final newPhone = InputSanitizer.sanitizePhone(rawPhone);

    if (newName.isNotEmpty) {
      name.value = newName;
      await _write('user_name', newName);
    }
    if (newPhone.isNotEmpty) {
      phone.value = newPhone;
      await _write('user_phone', newPhone);
    }
    isLogged.value = true;
    await _writeBool('is_logged', true);

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
    // Preserve region/location settings across logout/re-login
    final savedRegion = selectedRegion.value;
    final savedFilterMode = filterMode.value;
    final savedGender = targetGender.value;

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
    audienceProfile.value = '';
    favoriteBarberIds.clear();

    // Clear all prefs then restore location settings
    await _prefs.clear();

    // Restore preserved settings
    selectedRegion.value = savedRegion;
    filterMode.value = savedFilterMode;
    targetGender.value = savedGender;
    await _write('selected_region', savedRegion);
    await _write('filter_mode', savedFilterMode);
    await _write('target_gender', savedGender);
  }
}
