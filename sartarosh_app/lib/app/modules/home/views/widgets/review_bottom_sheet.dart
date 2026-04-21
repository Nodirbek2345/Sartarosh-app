import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewBottomSheet extends StatefulWidget {
  final Map<String, dynamic> booking;

  const ReviewBottomSheet({Key? key, required this.booking}) : super(key: key);

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  void _submitReview() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final bookingId = widget.booking['id'];
      final barberId = widget.booking['barberId'];
      final barberName =
          widget.booking['barberName'] ?? widget.booking['barber'];

      // 1. Update Booking
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'isRated': true,
            'rating': _rating,
            'reviewText': _commentController.text.trim(),
            'ratedAt': FieldValue.serverTimestamp(),
          });

      // 2. Update Barber's aggregate stats (optional but recommended)
      if (barberId != null) {
        final barberRef = FirebaseFirestore.instance
            .collection('barbers')
            .doc(barberId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(barberRef);
          if (snapshot.exists) {
            final data = snapshot.data()!;
            final currentTotalReviews = data['totalReviews'] ?? 0;
            final currentAverage = (data['averageRating'] ?? 5.0).toDouble();

            final newTotal = currentTotalReviews + 1;
            final newAverage =
                ((currentAverage * currentTotalReviews) + _rating) / newTotal;

            transaction.update(barberRef, {
              'totalReviews': newTotal,
              'averageRating': newAverage,
            });
          }
        });
      }

      Get.back(); // close modal
      Get.snackbar(
        "Katta Rahmat! 🎉",
        "Sizning fikringiz $barberName va boshqa mijozlar uchun juda muhim.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar("Xatolik", "Baho yuborishda xatolik yuz berdi");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _skipReview() async {
    // Optionally we can mark as skipped if we don't want to bother them again
    // For now we just dismiss
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final barberName =
        widget.booking['barberName'] ?? widget.booking['barber'] ?? 'Sartarosh';
    final serviceName = widget.booking['service'] ?? 'Xizmat';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.blue,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "Xizmat qanday bo'ldi?",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Yaqinda $barberName tomonidan bajarilgan \"$serviceName\" xizmatiga qanday baho berasiz?",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Rating Bar
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star_rounded, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 24),

            // Comment Box
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Sartarosh haqida fikringiz (ixtiyoriy)...",
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        "Baholash",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isSubmitting ? null : _skipReview,
              child: Text(
                "Keyinroq baholash",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
