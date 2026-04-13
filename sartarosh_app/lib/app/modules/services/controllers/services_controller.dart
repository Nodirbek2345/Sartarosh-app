import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServicesController extends GetxController {
  final selectedService = Rxn<Map<String, dynamic>>();

  final services = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadServicesFromFirebase();
  }

  void _loadServicesFromFirebase() {
    FirebaseFirestore.instance.collection('services').snapshots().listen((
      querySnapshot,
    ) {
      services.value = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'price': data['price'] ?? 0,
          'duration': data['duration'] ?? 30,
          'description': data['category'] ?? '',
          // Dynamic icon matching or fallback
          'icon': 0xe14f,
        };
      }).toList();
    });
  }

  void selectService(Map<String, dynamic> service) {
    selectedService.value = service;
  }
}
