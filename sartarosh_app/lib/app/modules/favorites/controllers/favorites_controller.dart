import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/user_service.dart';

class FavoritesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final isLoading = true.obs;
  final rxFavorites = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    ever(Get.find<UserService>().favoriteBarberIds, (_) => _fetchFavorites());
    _fetchFavorites();
  }

  void _fetchFavorites() async {
    isLoading.value = true;
    final ids = Get.find<UserService>().favoriteBarberIds;
    if (ids.isEmpty) {
      rxFavorites.clear();
      isLoading.value = false;
      return;
    }

    try {
      // Firestore whereIn supports max 10 items per query
      // Split into batches if needed
      final List<Map<String, dynamic>> allFavorites = [];

      for (int i = 0; i < ids.length; i += 10) {
        final batch = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
        final snap = await _firestore
            .collection('barbers')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snap.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          allFavorites.add(data);
        }
      }

      rxFavorites.value = allFavorites;
    } catch (e) {
      Get.snackbar("Xatolik", "Sevimlilarni yuklashda xatolik");
    } finally {
      isLoading.value = false;
    }
  }
}
