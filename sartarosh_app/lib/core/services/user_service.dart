import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final uid = ''.obs;
  final userRole = 'client'.obs;

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

    // Sync with Firebase Auth
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && uid.value.isEmpty) {
      uid.value = firebaseUser.uid;
      await _storage.write(key: 'user_uid', value: firebaseUser.uid);
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
  }

  void setRegion(String region) async {
    selectedRegion.value = region;
    await _storage.write(key: 'selected_region', value: region);
  }

  void setUserRole(String role) async {
    userRole.value = role;
    await _storage.write(key: 'user_role', value: role);
  }

  void updateUser(String newName, String newPhone) async {
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
    favoriteBarberIds.clear();
    await _storage.deleteAll();
  }
}
