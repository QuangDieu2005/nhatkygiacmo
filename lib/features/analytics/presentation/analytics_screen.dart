import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/dream_model.dart';
import '../../../models/sleep_statistics_model.dart';
import '../../../providers/sleep_provider.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/sleep_quality_indicator.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sleepProvider = context.watch<SleepProvider>();
    final stats = sleepProvider.statistics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân tích giấc ngủ'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.nightSkyGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thẻ chỉ số tổng quan
                _buildOverviewMetrics(stats),
                const SizedBox(height: 24),

                // Biểu đồ xu hướng ngủ (LineChart)
                SectionHeader(
                  title: 'Xu hướng ngủ tuần qua',
                  subtitle: 'Theo dõi sự ổn định trong chu kỳ giấc ngủ',
                ),
                const SizedBox(height: 12),
                _buildSleepTrendChart(stats),
                const SizedBox(height: 28),

                // Biểu đồ phân bổ cảm xúc giấc mơ (PieChart)
                SectionHeader(
                  title: 'Phân tích cảm xúc giấc mơ',
                  subtitle: 'Tỷ lệ các trạng thái cảm xúc đã ghi lại',
                ),
                const SizedBox(height: 12),
                _buildEmotionPieChart(stats),
                const SizedBox(height: 28),

                // Gợi ý cải thiện giấc ngủ
                SectionHeader(
                  title: 'Gợi ý cải thiện giấc ngủ',
                  subtitle: 'Được gợi ý dựa trên thói quen của bạn',
                ),
                const SizedBox(height: 12),
                _buildSleepTips(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewMetrics(SleepStatisticsModel stats) {
    return Row(
      children: [
        // Thời gian ngủ trung bình
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.access_time_rounded, color: AppColors.secondary, size: 24),
                const SizedBox(height: 14),
                Text(
                  '${stats.averageSleepHours}h',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Thời gian ngủ TB',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Điểm chất lượng TB
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.starGold, size: 24),
                    const SizedBox(height: 14),
                    Text(
                      '${stats.averageQualityScore}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Điểm chất lượng',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                SleepQualityIndicator(score: stats.averageQualityScore, size: 56),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSleepTrendChart(SleepStatisticsModel stats) {
    final weekly = stats.weeklyStats;
    if (weekly.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Chưa có dữ liệu thống kê', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < weekly.length; i++) {
      spots.add(FlSpot(i.toDouble(), weekly[i].hours));
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 24, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: LineChart(
        LineChartData(
          minY: 4,
          maxY: 11,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} giờ',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 2,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}h',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < weekly.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        weekly[index].dayLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: AppColors.primaryLight,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.35),
                    AppColors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionPieChart(SleepStatisticsModel stats) {
    final Map<EmotionType, int> distribution = stats.emotionDistribution;

    if (distribution.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Chưa có dữ liệu cảm xúc', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    final totalCount = distribution.values.fold<int>(0, (sum, val) => sum + val);

    final sections = distribution.entries.map((entry) {
      final percentage = (entry.value / totalCount) * 100;
      return PieChartSectionData(
        color: entry.key.color,
        value: entry.value.toDouble(),
        title: '${percentage.toInt()}%',
        radius: 46,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: distribution.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: entry.key.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key.label} (${entry.value})',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTips() {
    final tips = [
      {
        'icon': Icons.schedule_rounded,
        'title': 'Duy trì giờ ngủ cố định',
        'desc': 'Đi ngủ và thức dậy cùng một khung giờ mỗi ngày, kể cả cuối tuần.',
      },
      {
        'icon': Icons.phone_android_rounded,
        'title': 'Giảm ánh sáng xanh',
        'desc': 'Hạn chế sử dụng điện thoại và máy tính 30 phút trước khi ngủ.',
      },
      {
        'icon': Icons.spa_rounded,
        'title': 'Thư giãn trước khi ngủ',
        'desc': 'Nghe nhạc nhẹ nhàng, đọc sách hoặc thực hành hít thở sâu.',
      },
    ];

    return Column(
      children: tips.map((tip) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(tip['icon'] as IconData, color: AppColors.primaryLight, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tip['desc'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
