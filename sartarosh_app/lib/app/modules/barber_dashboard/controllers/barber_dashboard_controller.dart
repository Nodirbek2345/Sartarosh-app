import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/user_service.dart';

class BarberDashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final todayBookings = <Map<String, dynamic>>[].obs;
  final isActive = true.obs;
  final isLoading = true.obs;
  final queueLimit = 1.obs;

  // Stats
  final todayEarnings = 0.obs;
  final todayClientsCount = 0.obs;
  final completedCount = 0.obs;

  // Stream subscriptions for proper cleanup
  StreamSubscription? _bookingsSub;
  StreamSubscription? _statusSub;

  // Cached barber document reference
  DocumentReference? _barberDocRef;

  String get barberName => Get.find<UserService>().name.value;
  String get todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    _initBarberRef();
    _listenTodayBookings();
    _listenBarberStatus();
  }

  /// Cache the barber document reference to avoid repeated queries
  Future<void> _initBarberRef() async {
    final snapshot = await _firestore
        .collection('barbers')
        .where('name', isEqualTo: barberName)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      _barberDocRef = snapshot.docs.first.reference;
    }
  }

  void _listenTodayBookings() {
    _bookingsSub = _firestore
        .collection('bookings')
        .where('barberName', isEqualTo: barberName)
        .where('date', isEqualTo: todayDate)
        .snapshots()
        .listen((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['docId'] = doc.id;
            return data;
          }).toList();

          // Sort by time
          list.sort((a, b) => (a['time'] ?? '').compareTo(b['time'] ?? ''));
          todayBookings.value = list;

          // Stats
          todayClientsCount.value = list.length;
          completedCount.value = list
              .where((b) => b['status'] == 'completed')
              .length;
          todayEarnings.value = list
              .where((b) => b['status'] == 'completed')
              .fold<int>(
                0,
                (total, b) => total + ((b['price'] as num?)?.toInt() ?? 0),
              );

          isLoading.value = false;
          _checkAutoTurnOff();
        });
  }

  void _listenBarberStatus() {
    _statusSub = _firestore
        .collection('barbers')
        .where('name', isEqualTo: barberName)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final data = snapshot.docs.first.data();
            isActive.value = data['isActive'] ?? true;
            if (data.containsKey('queueLimit')) {
              queueLimit.value = data['queueLimit'] as int;
            }
            // Cache reference if not already cached
            _barberDocRef ??= snapshot.docs.first.reference;
            _checkAutoTurnOff();
          }
        });
  }

  Future<void> _checkAutoTurnOff() async {
    if (isActive.value &&
        todayClientsCount.value >= queueLimit.value &&
        queueLimit.value > 0) {
      isActive.value = false;
      if (_barberDocRef != null) {
        await _barberDocRef!.update({'isActive': false});
      }
    }
  }

  Future<void> toggleActiveStatus() async {
    if (_barberDocRef != null) {
      await _barberDocRef!.update({'isActive': !isActive.value});
    } else {
      // Fallback: find and update
      final snapshot = await _firestore
          .collection('barbers')
          .where('name', isEqualTo: barberName)
          .get();
      if (snapshot.docs.isNotEmpty) {
        _barberDocRef = snapshot.docs.first.reference;
        await _barberDocRef!.update({'isActive': !isActive.value});
      }
    }
  }

  void incrementLimit() {
    if (queueLimit.value < 99) {
      queueLimit.value++;
      _syncQueueLimit(queueLimit.value);
      _checkAutoTurnOff();
    }
  }

  void decrementLimit() {
    if (queueLimit.value > 1) {
      queueLimit.value--;
      _syncQueueLimit(queueLimit.value);
      _checkAutoTurnOff();
    }
  }

  Future<void> _syncQueueLimit(int val) async {
    if (_barberDocRef != null) {
      await _barberDocRef!.update({'queueLimit': val});
    } else {
      final snapshot = await _firestore
          .collection('barbers')
          .where('name', isEqualTo: barberName)
          .get();
      if (snapshot.docs.isNotEmpty) {
        _barberDocRef = snapshot.docs.first.reference;
        await _barberDocRef!.update({'queueLimit': val});
      }
    }
  }

  Future<void> acceptBooking(String docId) async {
    await _firestore.collection('bookings').doc(docId).update({
      'status': 'confirmed',
    });
  }

  Future<void> rejectBooking(String docId) async {
    await _firestore.collection('bookings').doc(docId).update({
      'status': 'cancelled',
    });
  }

  Future<void> startClient(String docId) async {
    await _firestore.collection('bookings').doc(docId).update({
      'status': 'in-progress',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeClient(String docId) async {
    await _firestore.collection('bookings').doc(docId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void onClose() {
    _bookingsSub?.cancel();
    _statusSub?.cancel();
    super.onClose();
  }
}
