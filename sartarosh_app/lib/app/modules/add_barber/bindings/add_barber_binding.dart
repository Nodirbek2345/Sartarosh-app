import 'package:get/get.dart';
import '../controllers/add_barber_controller.dart';

class AddBarberBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddBarberController>(() => AddBarberController());
  }
}
