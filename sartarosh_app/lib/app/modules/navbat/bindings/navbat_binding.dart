import 'package:get/get.dart';
import '../controllers/navbat_controller.dart';

class NavbatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavbatController>(() => NavbatController());
  }
}
