import 'package:get/get.dart';
import '../controllers/client_analytics_controller.dart';

class ClientAnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClientAnalyticsController>(() => ClientAnalyticsController());
  }
}
