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
        // Removed .orderBy('createdAt') to bypass missing index crash
        .snapshots()
        .listen((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['docId'] = doc.id;
            return data;
          }).toList();

          // Client-side sort descending by createdAt
          list.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

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
