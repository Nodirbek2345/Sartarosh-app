import 'package:cloud_firestore/cloud_firestore.dart';

/// Usta + sana + vaqt bo'yicha atomik band (Firestore transaksiyasi bilan).
/// `booking_time_locks` hujjati — bron bekor/yakun bo'lganda o'chiriladi.
abstract final class BookingSlotLock {
  static String docId(String barberId, String dateStr, String timeVal) {
    final safeTime = timeVal.replaceAll(':', '-');
    return '${barberId}_${dateStr}_$safeTime';
  }

  static DocumentReference<Map<String, dynamic>> ref(
    FirebaseFirestore fs,
    String barberId,
    String dateStr,
    String timeVal,
  ) {
    return fs.collection('booking_time_locks').doc(
          docId(barberId, dateStr, timeVal),
        );
  }

  static Future<void> release(
    FirebaseFirestore fs,
    String barberId,
    String dateStr,
    String timeVal,
  ) async {
    if (barberId.isEmpty || dateStr.isEmpty || timeVal.isEmpty) return;
    try {
      await ref(fs, barberId, dateStr, timeVal).delete();
    } catch (_) {}
  }

  static Future<void> releaseFromBookingData(
    FirebaseFirestore fs,
    Map<String, dynamic> data,
  ) async {
    final bid = data['barberId']?.toString() ?? '';
    final d = data['date']?.toString() ?? '';
    final t = data['time']?.toString() ?? '';
    await release(fs, bid, d, t);
  }
}
