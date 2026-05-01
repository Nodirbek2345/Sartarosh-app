import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../../core/services/user_service.dart';
import 'package:intl/intl.dart';

class ClientAnalyticsController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final userService = Get.find<UserService>();

  var isLoading = true.obs;

  // Stats
  var totalSpent = 0.0.obs;
  var monthlySpent = 0.0.obs;
  var topService = "".obs;
  var topBarberName = "".obs;

  // Cashback
  var totalVisits = 0.obs;
  var visitsLeftForFree = 0.obs;

  // Chart Data (Month Index -> Total Spent)
  // Indices: 1 (Jan) to 12 (Dec)
  var monthlyChartData = <int, double>{}.obs;

  // History List
  var historyList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      isLoading(true);
      final uid = userService.uid;

      final snapshot = await _firestore
          .collection('bookings')
          .where('clientUid', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .get();

      historyList.clear();
      double tSpent = 0.0;
      double mSpent = 0.0;
      int tVisits = snapshot.docs.length;

      Map<String, int> serviceCount = {};
      Map<String, int> barberCount = {};
      Map<int, double> chartData = {};

      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final double price = (data['price'] ?? 0.0).toDouble();
        final String serviceName = data['service'] ?? 'Xizmat';
        final String barberName = data['barberName'] ?? 'Usta';

        // Parse date
        DateTime? bookingDate;
        if (data['createdAt'] is Timestamp) {
          bookingDate = (data['createdAt'] as Timestamp).toDate();
        } else if (data['date'] != null) {
          try {
            bookingDate = DateTime.parse(data['date']);
          } catch (_) {}
        }

        if (bookingDate == null) continue;

        // Sum up total
        tSpent += price;

        // Sum up monthly limit
        if (bookingDate.month == now.month && bookingDate.year == now.year) {
          mSpent += price;
        }

        // Chart aggregation
        chartData[bookingDate.month] =
            (chartData[bookingDate.month] ?? 0) + price;

        // Service aggregation
        serviceCount[serviceName] = (serviceCount[serviceName] ?? 0) + 1;

        // Barber aggregation
        barberCount[barberName] = (barberCount[barberName] ?? 0) + 1;

        // Add to history
        historyList.add({
          'id': doc.id,
          'service': serviceName,
          'barberName': barberName,
          'price': price,
          'date': bookingDate,
        });
      }

      // Calculate Top Service
      if (serviceCount.isNotEmpty) {
        var topS = serviceCount.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        topService(topS.key);
      } else {
        topService("-");
      }

      // Calculate Top Barber
      if (barberCount.isNotEmpty) {
        var topB = barberCount.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        topBarberName(topB.key);
      } else {
        topBarberName("-");
      }

      totalSpent(tSpent);
      monthlySpent(mSpent);
      monthlyChartData(chartData);
      totalVisits(tVisits);

      // Calculate missing visits for free service (E.g. every 5th visit is free)
      int remainder = tVisits % 5;
      visitsLeftForFree(5 - remainder);
    } catch (e) {
      Get.log("Error fetching client analytics: $e");
    } finally {
      isLoading(false);
    }
  }

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: "so'm",
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy, HH:mm').format(date);
  }
}
