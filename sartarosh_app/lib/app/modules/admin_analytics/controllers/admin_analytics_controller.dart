import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsController extends GetxController {
  final _firestore = FirebaseFirestore.instance;

  var isLoading = true.obs;

  // Key Financial Metrics
  var totalRevenue = 0.0.obs;
  var adminNetIncome = 0.0.obs;
  var barberNetIncome = 0.0.obs;

  // Real-time Visit Trackers
  var todayBookingsCount = 0.obs;
  var yesterdayBookingsCount = 0.obs;

  // Chart Data: mapped by month (1=Jan, 12=Dec)
  var monthlyChartDataOborot = <int, double>{}.obs;
  var monthlyChartDataAdmin = <int, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchGlobalAnalytics();
  }

  Future<void> _fetchGlobalAnalytics() async {
    try {
      isLoading(true);

      // Fetch all global completed bookings
      final snapshot = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'completed')
          .get();

      double tRevenue = 0.0;
      int tToday = 0;
      int tYesterday = 0;

      Map<int, double> chartOborot = {};
      Map<int, double> chartAdmin = {};

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final double price = (data['price'] ?? 0.0).toDouble();

        DateTime? bookingDate;
        if (data['createdAt'] is Timestamp) {
          bookingDate = (data['createdAt'] as Timestamp).toDate();
        } else if (data['date'] != null) {
          try {
            bookingDate = DateTime.parse(data['date']);
          } catch (_) {}
        }

        if (bookingDate == null) continue;

        // Sum global revenue
        tRevenue += price;

        // Check for today vs yesterday
        final bDateStart = DateTime(
          bookingDate.year,
          bookingDate.month,
          bookingDate.day,
        );
        if (bDateStart.isAtSameMomentAs(todayStart)) {
          tToday++;
        } else if (bDateStart.isAtSameMomentAs(yesterdayStart)) {
          tYesterday++;
        }

        // Chart aggregation (Summing per month)
        chartOborot[bookingDate.month] =
            (chartOborot[bookingDate.month] ?? 0) + price;
        chartAdmin[bookingDate.month] =
            (chartAdmin[bookingDate.month] ?? 0) +
            (price * 0.1); // Assuming 10% cut
      }

      totalRevenue(tRevenue);
      adminNetIncome(tRevenue * 0.10); // 10% platform fee
      barberNetIncome(tRevenue * 0.90); // 90% goes to barbers

      todayBookingsCount(tToday);
      yesterdayBookingsCount(tYesterday);

      monthlyChartDataOborot(chartOborot);
      monthlyChartDataAdmin(chartAdmin);
    } catch (e) {
      Get.log("Admin Analytics Xatosi: $e");
    } finally {
      isLoading(false);
    }
  }

  String formatCurrency(double amount) {
    if (amount >= 1000000) {
      final val = amount / 1000000;
      return "${val.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M";
    }
    final format = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: "so'm",
      decimalDigits: 0,
    );
    return format.format(amount);
  }
}
