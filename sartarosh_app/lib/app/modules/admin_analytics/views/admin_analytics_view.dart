import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/admin_analytics_controller.dart';
import '../../../../core/theme/app_theme.dart';

class AdminAnalyticsView extends GetView<AdminAnalyticsController> {
  const AdminAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Daromad",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              "Moliyaviy ko'rsatkichlar",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.background,
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
            onPressed: () => controller.onInit(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainCardsHorizontal().animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 24),
              _buildDailyMetrics()
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .slideY(begin: 0.1),
              const SizedBox(height: 32),
              _buildChartSection()
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.1),
              const SizedBox(height: 48), // Bottom padding scroll space
            ],
          ),
        );
      }),
    );
  }

  // Horizontal scroll for the 3 main metric cards
  Widget _buildMainCardsHorizontal() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildRevenueCard(
            title: "Umumiy Oborot",
            subtitle: "Tizimdagi barcha to'lovlar",
            amount: controller.formatCurrency(controller.totalRevenue.value),
            icon: Icons.account_balance_wallet_rounded,
            bgColor: const Color(0xFF14192B), // Dark blue/black
            textColor: Colors.white,
            iconBg: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 16),
          _buildRevenueCard(
            title: "Sof Daromad",
            subtitle: "Admin komissiyasi ehtimoli",
            amount: controller.formatCurrency(controller.adminNetIncome.value),
            icon: Icons.trending_up_rounded,
            bgColor: AppTheme.gold, // Gold
            textColor: Colors.white,
            iconBg: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 16),
          _buildRevenueCard(
            title: "Sartaroshlar Ulushi",
            subtitle: "Ustalarga tegishli tushum",
            amount: controller.formatCurrency(controller.barberNetIncome.value),
            icon: Icons.payments_rounded,
            bgColor: Colors.white,
            textColor: AppTheme.textDark,
            iconBg: AppTheme.primary.withValues(alpha: 0.1),
            subtitleColor: AppTheme.textMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard({
    required String title,
    required String subtitle,
    required String amount,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    Color? subtitleColor,
    required Color iconBg,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: bgColor == Colors.white
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: bgColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: bgColor == Colors.white
                      ? AppTheme.primary
                      : Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: textColor.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            amount,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: subtitleColor ?? textColor.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildSmallCountCard(
            "Bugungi bronlar",
            "${controller.todayBookingsCount.value} ta",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSmallCountCard(
            "Kechagi bronlar",
            "${controller.yesterdayBookingsCount.value} ta",
          ),
        ),
      ],
    );
  }

  Widget _buildSmallCountCard(String title, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.textMedium.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.poppins(
              color: AppTheme.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    if (controller.monthlyChartDataOborot.isEmpty &&
        controller.totalRevenue.value == 0) {
      return const SizedBox.shrink(); // Empty state hidden nicely
    }

    // Determine max Y scale dynamically from Oborot
    final maxY = controller.monthlyChartDataOborot.values.isEmpty
        ? 100000.0
        : controller.monthlyChartDataOborot.values.reduce(
                (a, b) => a > b ? a : b,
              ) *
              1.3;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Oylik tushumlar dinamikasi",
                      style: GoogleFonts.poppins(
                        color: AppTheme.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "Oborot va Admin foizi o'sishi",
                      style: GoogleFonts.poppins(
                        color: AppTheme.textMedium,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Legend
              Row(
                children: [
                  _legendItem(
                    AppTheme.textMedium.withValues(alpha: 0.2),
                    "Oborot",
                  ),
                  const SizedBox(width: 12),
                  _legendItem(AppTheme.gold, "Daromad"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: maxY == 0 ? 100000 : maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final val = rod.toY;
                      return BarTooltipItem(
                        controller.formatCurrency(val),
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
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
                                fontSize: 11,
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5 > 0 ? maxY / 5 : 10000,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.textMedium.withValues(alpha: 0.1),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(6, (index) {
                  // Last 6 months offset
                  final currentMonth = DateTime.now().month;
                  int targetMonth = currentMonth - 5 + index;
                  if (targetMonth <= 0) targetMonth += 12;

                  final valOborot =
                      controller.monthlyChartDataOborot[targetMonth] ?? 0.0;
                  final valAdmin =
                      controller.monthlyChartDataAdmin[targetMonth] ?? 0.0;

                  return BarChartGroupData(
                    x: targetMonth,
                    barRods: [
                      BarChartRodData(
                        toY: valOborot,
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: valAdmin,
                        color: AppTheme.gold,
                        width: 14,
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

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppTheme.textMedium,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
