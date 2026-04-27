import 'package:get/get.dart';
import '../controllers/barber_services_controller.dart';

class BarberServicesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BarberServicesController>(() => BarberServicesController());
  }
}
