import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/user_service.dart';

class NotificationsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final notifications = <Map<String, dynamic>>[].obs;
  final unreadCount = 0.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _listenNotifications();
  }

  void _listenNotifications() {
    final userService = Get.find<UserService>();
    final uid = userService.currentUid;
    if (uid.isEmpty) {
      isLoading.value = false;
      return;
    }

    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['docId'] = doc.id;
            return data;
          }).toList();

          final newUnreadCount = list.where((n) => n['isRead'] == false).length;

          if (!isLoading.value && newUnreadCount > unreadCount.value) {
            HapticFeedback.vibrate();
          }

          notifications.value = list;
          unreadCount.value = newUnreadCount;
          isLoading.value = false;
        });
  }

  Future<void> markAsRead(String docId) async {
    try {
      await _firestore.collection('notifications').doc(docId).update({
        'isRead': true,
      });
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final unreadDocs = notifications.where((n) => n['isRead'] == false);
      final batch = _firestore.batch();
      for (var n in unreadDocs) {
        final ref = _firestore.collection('notifications').doc(n['docId']);
        batch.update(ref, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      final batch = _firestore.batch();
      for (var n in notifications) {
        final ref = _firestore.collection('notifications').doc(n['docId']);
        batch.delete(ref);
      }
      await batch.commit();
    } catch (_) {}
  }
}
