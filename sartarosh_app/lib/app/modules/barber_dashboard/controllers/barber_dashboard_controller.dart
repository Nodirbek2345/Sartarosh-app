import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/user_service.dart';
import 'package:flutter/material.dart';

class BarberDashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final todayBookings = <Map<String, dynamic>>[].obs;
  final allBookings = <Map<String, dynamic>>[].obs; // Barcha kunlar uchun
  final isActive = true.obs;
  final isLoading = true.obs;
  final queueLimit = 1.obs;
  final portfolioImages = <String>[].obs;

  // Stats
  final todayEarnings = 0.obs;
  final weeklyEarnings = 0.obs;
  final monthlyEarnings = 0.obs;
  final todayClientsCount = 0.obs;
  final completedCount = 0.obs;
  final pendingCount = 0.obs; // Kutilmoqda bronlar soni

  // Stream subscriptions for proper cleanup
  StreamSubscription? _bookingsSub;
  StreamSubscription? _allBookingsSub;
  StreamSubscription? _statusSub;

  // Cached barber document reference
  DocumentReference? _barberDocRef;
  String _barberId = ''; // barber document ID

  String get currentUid => Get.find<UserService>().currentUid;
  String get barberName => Get.find<UserService>().name.value;
  String get todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    _initAndListen();
  }

  Future<void> _initAndListen() async {
    await _initBarberRef();
    _listenTodayBookings();
    _listenAllBookings();
    _listenBarberStatus();
  }

  /// Cache the barber document reference using UID
  Future<void> _initBarberRef() async {
    final snapshot = await _firestore
        .collection('barbers')
        .where('uid', isEqualTo: currentUid)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      _barberDocRef = snapshot.docs.first.reference;
      _barberId = snapshot.docs.first.id;
    }
  }

  void _listenTodayBookings() {
    if (_barberId.isEmpty) {
      isLoading.value = false;
      return;
    }
    _bookingsSub = _firestore
        .collection('bookings')
        .where('barberId', isEqualTo: _barberId)
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

  /// Barcha kunlar uchun bronlarni tinglash (Bronlar tab uchun)
  void _listenAllBookings() {
    if (_barberId.isEmpty) return;
    _allBookingsSub = _firestore
        .collection('bookings')
        .where('barberId', isEqualTo: _barberId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['docId'] = doc.id;
            return data;
          }).toList();

          allBookings.value = list;
          pendingCount.value = list
              .where((b) => b['status'] == 'pending')
              .length;

          // Calculate Financials (Weekly/Monthly)
          int wEarnings = 0;
          int mEarnings = 0;
          final now = DateTime.now();
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfMonth = DateTime(now.year, now.month, 1);
          final startOfWeekNorm = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );

          for (var b in list) {
            if (b['status'] == 'completed') {
              try {
                DateTime bDate = DateFormat(
                  'yyyy-MM-dd',
                ).parse(b['date'] ?? '');
                int price = (b['price'] as num?)?.toInt() ?? 0;

                if (!bDate.isBefore(startOfMonth)) {
                  mEarnings += price;
                }
                if (!bDate.isBefore(startOfWeekNorm)) {
                  wEarnings += price;
                }
              } catch (_) {}
            }
          }
          weeklyEarnings.value = wEarnings;
          monthlyEarnings.value = mEarnings;
        });
  }

  void _listenBarberStatus() {
    _statusSub = _firestore
        .collection('barbers')
        .where('uid', isEqualTo: currentUid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final data = snapshot.docs.first.data();
            isActive.value = data['isActive'] ?? true;
            if (data.containsKey('queueLimit')) {
              queueLimit.value = data['queueLimit'] as int;
            }
            if (data.containsKey('portfolioImages')) {
              portfolioImages.value = List<String>.from(
                data['portfolioImages'] ?? [],
              );
            }
            // Cache reference if not already cached
            _barberDocRef ??= snapshot.docs.first.reference;
            if (_barberId.isEmpty) {
              _barberId = snapshot.docs.first.id;
            }
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
          .where('uid', isEqualTo: currentUid)
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
          .where('uid', isEqualTo: currentUid)
          .get();
      if (snapshot.docs.isNotEmpty) {
        _barberDocRef = snapshot.docs.first.reference;
        await _barberDocRef!.update({'queueLimit': val});
      }
    }
  }

  Future<void> acceptBooking(String docId) async {
    try {
      // Smart Accept: Auto-reject overlapping bookings
      final snapshot = await _firestore.collection('bookings').doc(docId).get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final date = data['date'];
        final time = data['time'];

        final overlaps = await _firestore
            .collection('bookings')
            .where('barberId', isEqualTo: _barberId)
            .where('date', isEqualTo: date)
            .where('time', isEqualTo: time)
            .where('status', isEqualTo: 'pending')
            .get();

        for (var doc in overlaps.docs) {
          if (doc.id != docId) {
            await doc.reference.update({'status': 'cancelled'});
          }
        }
      }

      await _firestore.collection('bookings').doc(docId).update({
        'status': 'confirmed',
      });
      Get.snackbar(
        "Muvaffaqiyatli",
        "Bron qabul qilindi",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Xatolik yuz berdi",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> rejectBooking(String docId) async {
    try {
      await _firestore.collection('bookings').doc(docId).update({
        'status': 'cancelled',
      });
      Get.snackbar(
        "Bekor qilindi",
        "Bron rad etildi",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Xatolik yuz berdi",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> startClient(String docId) async {
    try {
      // State Guard: Prevent multiple 'in-progress'
      final inProgressSnap = await _firestore
          .collection('bookings')
          .where('barberId', isEqualTo: _barberId)
          .where('date', isEqualTo: todayDate)
          .where('status', isEqualTo: 'in-progress')
          .get();

      if (inProgressSnap.docs.isNotEmpty) {
        Get.snackbar(
          "Xatolik",
          "Avval boshlangan mijozni yakunlang!",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      await _firestore.collection('bookings').doc(docId).update({
        'status': 'in-progress',
        'startedAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar(
        "Boshlandi",
        "Xizmat boshlandi",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Xizmatni boshlashda xatolik yuz berdi",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> completeClient(String docId) async {
    try {
      await _firestore.collection('bookings').doc(docId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar(
        "Tugallandi",
        "Xizmat muvaffaqiyatli yakunlandi",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Xizmatni tugatishda xatolik yuz berdi",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ============== PHOTO COMPRESSION & UPLOAD ==============
  final isUploadingPhoto = false.obs;

  Future<void> uploadProfileImage() async {
    isUploadingPhoto.value = true;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        isUploadingPhoto.value = false;
        return; // User cancelled
      }

      File nativeFile = File(pickedFile.path);

      // Compress Image (Pro optimization)
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
            nativeFile.absolute.path,
            targetPath,
            quality: 60,
            minWidth: 800,
            minHeight: 800,
          );

      if (compressedFile == null) {
        Get.snackbar("Xato", "Rasmni tayyorlashda xatolik");
        isUploadingPhoto.value = false;
        return;
      }

      final fileToUpload = File(compressedFile.path);

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('barbers')
          .child('${Get.find<UserService>().currentUid}.jpg');

      await storageRef.putFile(fileToUpload);
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore Barber Collection
      if (_barberDocRef != null) {
        await _barberDocRef!.update({'image': downloadUrl});
      } else {
        final snapshot = await _firestore
            .collection('barbers')
            .where('uid', isEqualTo: currentUid)
            .get();
        if (snapshot.docs.isNotEmpty) {
          _barberDocRef = snapshot.docs.first.reference;
          await _barberDocRef!.update({'image': downloadUrl});
        }
      }

      // Update Global User Service
      Get.find<UserService>().updatePhotoUrl(downloadUrl);

      Get.snackbar(
        "Muvaffaqiyatli",
        "Rasm yuklandi va SIQILDI",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Rasm yuklashda xatolik: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  // ============== PORTFOLIO COMPRESSION & UPLOAD ==============
  final isUploadingPortfolio = false.obs;

  Future<void> uploadPortfolioImage() async {
    isUploadingPortfolio.value = true;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        isUploadingPortfolio.value = false;
        return;
      }

      File nativeFile = File(pickedFile.path);

      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/portfolio_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
            nativeFile.absolute.path,
            targetPath,
            quality: 65,
            minWidth: 1080,
            minHeight: 1080,
          );

      if (compressedFile == null) {
        Get.snackbar("Xato", "Rasmni tayyorlashda xatolik");
        isUploadingPortfolio.value = false;
        return;
      }

      final fileToUpload = File(compressedFile.path);
      final fileName = 'portfolio_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('barbers')
          .child(Get.find<UserService>().currentUid)
          .child('portfolio')
          .child(fileName);

      await storageRef.putFile(fileToUpload);
      final downloadUrl = await storageRef.getDownloadURL();

      if (_barberDocRef != null) {
        await _barberDocRef!.update({
          'portfolioImages': FieldValue.arrayUnion([downloadUrl]),
        });
      }

      Get.snackbar(
        "Muvaffaqiyatli",
        "Portfolio rasm yuklandi",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Xatolik",
        "Portfolio rasm yuklashda xatolik: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isUploadingPortfolio.value = false;
    }
  }

  Future<void> deletePortfolioImage(String url) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Attempt to delete from storage. Ignore if fails (e.g. wrong url struct)
      try {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
      } catch (_) {}

      // Remove from firestore
      if (_barberDocRef != null) {
        await _barberDocRef!.update({
          'portfolioImages': FieldValue.arrayRemove([url]),
        });
      }

      Get.back(); // close dialog
      Get.snackbar("O'chirildi", "Rasm portfoliodan olib tashlandi");
    } catch (e) {
      Get.back();
      Get.snackbar("Xatolik", "Rasmni o'chirishda xatolik: $e");
    }
  }

  @override
  void onClose() {
    _bookingsSub?.cancel();
    _allBookingsSub?.cancel();
    _statusSub?.cancel();
    super.onClose();
  }
}
