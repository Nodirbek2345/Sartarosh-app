import 'dart:io';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateController extends GetxController {
  final _playStoreUrl = ''.obs;
  final _appStoreUrl = ''.obs;
  final updateMessage =
      'Sizning ilovangiz eskirgan. Iltimos, davom etish uchun yangilang.'.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map<String, dynamic>;
      _playStoreUrl.value = args['play_store_url'] ?? '';
      _appStoreUrl.value = args['app_store_url'] ?? '';

      if (args['update_message'] != null &&
          args['update_message'].toString().isNotEmpty) {
        updateMessage.value = args['update_message'];
      }
    }
  }

  void openStore() async {
    String url = Platform.isIOS ? _appStoreUrl.value : _playStoreUrl.value;
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Xatolik', 'Ilova do\'konini ochib bo\'lmadi');
      }
    } else {
      Get.snackbar('Xatolik', 'Do\'kon havolasi topilmadi');
    }
  }
}
