import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/client_analytics_controller.dart';
import '../../../../core/theme/app_theme.dart';

class ClientAnalyticsView extends GetView<ClientAnalyticsController> {
  const ClientAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          "Mening xarajatlarim",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textDark,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Re-initializes fetch
            controller.onInit();
            await Future.delayed(Duration(milliseconds: 800));
          },
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCashbackBanner().animate().fadeIn().slideY(begin: 0.2),
                SizedBox(height: 24),
                _buildStatsGrid()
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.2),
                SizedBox(height: 32),
                _buildChartSection()
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.2),
                SizedBox(height: 32),
                _buildHistorySection()
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.2),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCashbackBanner() {
    final left = controller.visitsLeftForFree.value;
    final total = controller.totalVisits.value;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withValues(alpha: 0.15),
            AppTheme.gold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: AppTheme.gold,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cashback & Bonus",
                  style: GoogleFonts.poppins(
                    color: AppTheme.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  left == 5
                      ? "Sizda bepul xizmat kafolatlangan! 🎁"
                      : "Yana $left ta tashrifdan so'ng 1 bepul xizmat kafolatlangan!",
                  style: GoogleFonts.poppins(
                    color: AppTheme.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Jami tashriflar: $total marta",
                  style: GoogleFonts.poppins(
                    color: AppTheme.textMedium,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        _buildStatCard(
          "Umumiy xarajat",
          controller.formatCurrency(controller.totalSpent.value),
          Icons.account_balance_wallet_rounded,
          AppTheme.textDark,
          Colors.white,
        ),
        _buildStatCard(
          "Bu oy",
          controller.formatCurrency(controller.monthlySpent.value),
          Icons.calendar_today_rounded,
          AppTheme.gold,
          AppTheme.gold.withValues(alpha: 0.1),
        ),
        _buildStatCard(
          "Eng ko'p xizmat",
          controller.topService.value,
          Icons.design_services_rounded,
          AppTheme.primary,
          AppTheme.primary.withValues(alpha: 0.1),
        ),
        _buildStatCard(
          "Sevimli usta",
          controller.topBarberName.value,
          Icons.person_rounded,
          Color(0xFF8D6E63),
          Color(0xFF8D6E63).withValues(alpha: 0.1),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: bgColor == Colors.white
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]
            : [],
        border: bgColor != Colors.white
            ? Border.all(color: color.withValues(alpha: 0.1))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textMedium,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: AppTheme.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    if (controller.monthlyChartData.isEmpty &&
        controller.totalSpent.value == 0) {
      return SizedBox.shrink();
    }

    final maxY = controller.monthlyChartData.values.isEmpty
        ? 100000.0
        : controller.monthlyChartData.values.reduce((a, b) => a > b ? a : b) *
              1.2;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Oylik xarajatlar",
            style: GoogleFonts.poppins(
              color: AppTheme.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY == 0 ? 10000 : maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          'Yan',
                          'Fev',
                          'Mar',
                          'Apr',
                          'May',
                          'Iyn',
                          'Iyl',
                          'Avg',
                          'Sen',
                          'Okt',
                          'Noy',
                          'Dek',
                        ];
                        if (value >= 1 && value <= 12) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              months[value.toInt() - 1],
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(6, (index) {
                  // Show last 6 months dynamically based on current month
                  final currentMonth = DateTime.now().month;
                  int targetMonth = currentMonth - 5 + index;
                  if (targetMonth <= 0) targetMonth += 12; // Handle year wrap

                  final val = controller.monthlyChartData[targetMonth] ?? 0.0;

                  return BarChartGroupData(
                    x: targetMonth,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: targetMonth == currentMonth
                            ? AppTheme.gold
                            : AppTheme.primary.withValues(alpha: 0.3),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (controller.historyList.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 48,
                color: AppTheme.textMedium.withValues(alpha: 0.5),
              ),
              SizedBox(height: 16),
              Text(
                "Xarajatlar tarixi yo'q",
                style: GoogleFonts.poppins(color: AppTheme.textMedium),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Oxirgi xarajatlar",
          style: GoogleFonts.poppins(
            color: AppTheme.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16),
        ...controller.historyList.map((item) {
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['service'],
                        style: GoogleFonts.poppins(
                          color: AppTheme.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "${item['barberName']} • ${controller.formatDate(item['date'])}",
                        style: GoogleFonts.poppins(
                          color: AppTheme.textMedium,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  controller.formatCurrency(item['price']),
                  style: GoogleFonts.poppins(
                    color: AppTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
