import 'package:get/get.dart';
import '../controllers/barber_detail_controller.dart';

class BarberDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<BarberDetailController>(BarberDetailController());
  }
}
