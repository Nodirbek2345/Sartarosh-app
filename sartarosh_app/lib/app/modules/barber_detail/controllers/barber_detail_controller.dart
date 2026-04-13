import 'package:get/get.dart';

class BarberDetailController extends GetxController {
  late Map<String, dynamic> barber;

  @override
  void onInit() {
    super.onInit();
    barber = Get.arguments as Map<String, dynamic>? ?? {};
  }

  void bookNow() {
    Get.toNamed('/booking', arguments: barber);
  }
}
