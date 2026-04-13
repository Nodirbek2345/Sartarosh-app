import 'package:get/get.dart';
import '../controllers/barber_dashboard_controller.dart';

class BarberDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BarberDashboardController>(() => BarberDashboardController());
  }
}
