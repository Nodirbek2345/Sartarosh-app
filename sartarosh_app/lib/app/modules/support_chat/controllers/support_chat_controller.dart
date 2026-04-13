import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/input_sanitizer.dart';

class SupportChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController textCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();

  final messages = <Map<String, dynamic>>[].obs;
  final isTyping = false.obs;

  late String userId;
  late String userName;

  @override
  void onInit() {
    super.onInit();
    final userService = Get.find<UserService>();
    userName = userService.name.value.isNotEmpty
        ? userService.name.value
        : 'Mijoz';
    // Use Firebase UID for secure identification
    userId = userService.currentUid.isNotEmpty
        ? userService.currentUid
        : 'anonymous_${DateTime.now().millisecondsSinceEpoch}';

    // Add default greeting from AI
    messages.add({
      'text':
          "Assalomu alaykum, $userName! 👋\n\nSartarosh ilovasi bo'yicha qanday muammoga duch keldingiz yoki qanday takliflaringiz bor?\n\nYozib qoldiring, biz tezda javob beramiz!",
      'sender': "ai",
      'time': DateTime.now(),
    });
  }

  Future<void> sendMessage() async {
    final rawText = textCtrl.text.trim();
    if (rawText.isEmpty) return;

    // Rate limiting - prevent spam messages
    if (!InputSanitizer.canPerformAction(cooldown: Duration(seconds: 2))) {
      return;
    }

    // Sanitize input
    final text = InputSanitizer.sanitizeText(rawText);
    if (text.isEmpty) return;

    // Limit message length
    final safeText = text.length > 1000 ? text.substring(0, 1000) : text;

    textCtrl.clear();

    // Add user message locally
    messages.add({'text': safeText, 'sender': 'user', 'time': DateTime.now()});
    _scrollToBottom();

    // Save user message to Firestore (for admin/backend)
    try {
      await _firestore.collection('support_messages').add({
        'userId': userId,
        'userName': userName,
        'text': safeText,
        'sender': 'user',
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    isTyping.value = true;
    _scrollToBottom();

    // Simulate AI thinking
    await Future.delayed(Duration(milliseconds: 1500));

    final aiResponse = _generateAiResponse(safeText);

    // Add AI response locally
    messages.add({'text': aiResponse, 'sender': 'ai', 'time': DateTime.now()});

    // Save AI response to Firestore
    try {
      await _firestore.collection('support_messages').add({
        'userId': userId,
        'userName': userName,
        'text': aiResponse,
        'sender': 'ai',
        'status': 'answered',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    isTyping.value = false;
    _scrollToBottom();
  }

  String _generateAiResponse(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('xato') ||
        lower.contains('ishlamayapti') ||
        lower.contains('bug') ||
        lower.contains('muammo')) {
      return "⚠️ Texnik xatolik haqida xabar berganingiz uchun rahmat!\n\nBizning texnik jamoamiz buni darhol ko'rib chiqadi. Muammo tez orada hal qilinadi. Agar tezkor yordam kerak bo'lsa, muammoni batafsilroq yozing.";
    }

    if (lower.contains('narx') ||
        lower.contains('qimmat') ||
        lower.contains('arzon') ||
        lower.contains('pul')) {
      return "💰 Narxlar bo'yicha fikringiz qabul qilindi!\n\nMa'muriyatimiz narxlar siyosatini doimiy ravishda tahlil qilib boradi. Sizning fikringiz biz uchun juda muhim!";
    }

    if (lower.contains('bron') ||
        lower.contains('vaqt') ||
        lower.contains('kutish')) {
      return "📅 Bronlash bo'yicha murojaatingiz qabul qilindi!\n\nBizning tizimda bron qilish 24/7 ishlaydi. Agar muammo bo'lsa, tafsilotlarini yozib qoldiring.";
    }

    if (lower.contains('rahmat') ||
        lower.contains('yaxshi') ||
        lower.contains('ajoyib') ||
        lower.contains('zo\'r')) {
      return "🙏 Rahmat! Sizning ijobiy fikringiz biz uchun katta ilhom!\n\nSartarosh ilovasini yanada yaxshilash ustida ishlaymiz. Biz bilan bo'lganingiz uchun minnatdormiz! ✨";
    }

    if (lower.contains('usta') ||
        lower.contains('sartarosh') ||
        lower.contains('barber')) {
      return "✂️ Ustalar bo'yicha murojaatingiz qabul qilindi!\n\nBizda faqat tajribali va sertifikatlangan ustalar ishlaydi. Qo'shimcha savollaringiz bo'lsa, bemalol yozing.";
    }

    return "✅ Xabaringiz muvaffaqiyatli qabul qilindi!\n\nFikr-mulohazangiz biz uchun juda muhim. Tez orada javob qaytaramiz. Boshqa savollaringiz bo'lsa, yozing! 😊";
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 150), () {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    textCtrl.dispose();
    scrollCtrl.dispose();
    super.onClose();
  }
}
