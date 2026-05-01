import 'package:get/get.dart';
import '../controllers/force_update_controller.dart';

class ForceUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForceUpdateController>(() => ForceUpdateController());
  }
}
