import 'package:get/get.dart';
import '../controllers/region_controller.dart';

class RegionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegionController>(() => RegionController());
  }
}
