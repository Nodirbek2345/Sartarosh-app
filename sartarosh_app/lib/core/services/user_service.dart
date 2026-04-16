import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final uid = ''.obs; // Firebase Auth UID for secure queries
  final userRole = 'client'.obs; // 'client' or 'barber'

  late SharedPreferences _prefs;

  /// Get current Firebase Auth UID (live)
  String get currentUid {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    return firebaseUser?.uid ?? uid.value;
  }

  /// Check if user is truly authenticated
  bool get isAuthenticated =>
      FirebaseAuth.instance.currentUser != null && isLogged.value;

  Future<UserService> init() async {
    _prefs = await SharedPreferences.getInstance();
    name.value = _prefs.getString('user_name') ?? "Mijoz";
    phone.value = _prefs.getString('user_phone') ?? "+998 -- --- -- --";
    isLogged.value = _prefs.getBool('is_logged') ?? false;
    avatarBase64.value = _prefs.getString('user_avatar') ?? "";
    photoUrl.value = _prefs.getString('user_photo_url') ?? "";
    favoriteBarberIds.value = _prefs.getStringList('favorite_barbers') ?? [];
    isBarberMode.value = _prefs.getBool('is_barber_mode') ?? false;
    targetGender.value = _prefs.getString('target_gender') ?? 'male';
    selectedRegion.value = _prefs.getString('selected_region') ?? '';
    userRole.value = _prefs.getString('user_role') ?? 'client';
    uid.value = _prefs.getString('user_uid') ?? '';

    // Sync with Firebase Auth if available
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && uid.value.isEmpty) {
      uid.value = firebaseUser.uid;
      await _prefs.setString('user_uid', firebaseUser.uid);
    }

    return this;
  }

  void toggleFavorite(String barberId) async {
    if (favoriteBarberIds.contains(barberId)) {
      favoriteBarberIds.remove(barberId);
    } else {
      favoriteBarberIds.add(barberId);
    }
    await _prefs.setStringList('favorite_barbers', favoriteBarberIds.toList());
  }

  bool isFavorite(String barberId) {
    return favoriteBarberIds.contains(barberId);
  }

  void updateAvatar(String base64Image) async {
    avatarBase64.value = base64Image;
    await _prefs.setString('user_avatar', base64Image);
  }

  void updatePhotoUrl(String url) async {
    photoUrl.value = url;
    await _prefs.setString('user_photo_url', url);
  }

  void updateUid(String newUid) async {
    uid.value = newUid;
    await _prefs.setString('user_uid', newUid);
  }

  void toggleBarberMode() async {
    isBarberMode.value = !isBarberMode.value;
    await _prefs.setBool('is_barber_mode', isBarberMode.value);
  }

  void setTargetGender(String gender) async {
    targetGender.value = gender;
    await _prefs.setString('target_gender', gender);
  }

  void setRegion(String region) async {
    selectedRegion.value = region;
    await _prefs.setString('selected_region', region);
  }

  void setUserRole(String role) async {
    userRole.value = role;
    await _prefs.setString('user_role', role);
  }

  void updateUser(String newName, String newPhone) async {
    if (newName.isNotEmpty) {
      name.value = newName;
      await _prefs.setString('user_name', newName);
    }
    if (newPhone.isNotEmpty) {
      phone.value = newPhone;
      await _prefs.setString('user_phone', newPhone);
    }
    isLogged.value = true;
    await _prefs.setBool('is_logged', true);
  }

  Future<void> logout() async {
    // Sign out from Firebase Auth
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    name.value = "Mijoz";
    phone.value = "+998 -- --- -- --";
    isLogged.value = false;
    isBarberMode.value = false;
    userRole.value = 'client';
    uid.value = '';
    favoriteBarberIds.clear();
    await _prefs.clear();
  }
}
