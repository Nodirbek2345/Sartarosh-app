import 'package:get/get.dart';
import '../controllers/admin_analytics_controller.dart';

class AdminAnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminAnalyticsController>(() => AdminAnalyticsController());
  }
}
