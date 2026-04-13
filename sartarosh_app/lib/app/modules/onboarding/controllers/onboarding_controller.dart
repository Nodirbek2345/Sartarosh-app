import 'package:get/get.dart';

class OnboardingController extends GetxController {
  final currentPage = 0.obs;

  final pages = [
    {
      'icon': 0xe14f, // content_cut
      'title': "Sizga mos xizmatni tanlang",
      'subtitle': "Eng yaxshi ustalarni bir joyda toping",
      'button': "Davom etish",
    },
    {
      'icon': 0xe935, // calendar_month
      'title': "Qulay va tez bron qiling",
      'subtitle': "Bir necha bosqichda vaqtni belgilang",
      'button': "Davom etish",
    },
    {
      'icon': 0xe838, // star
      'title': "Sifatli xizmatdan bahramand bo'ling",
      'subtitle': "Siz uchun eng yaxshi tajriba",
      'button': "Boshlash",
    },
  ];

  void next() {
    if (currentPage.value < 2) {
      currentPage.value++;
    } else {
      Get.offAllNamed('/phone-login');
    }
  }
}
