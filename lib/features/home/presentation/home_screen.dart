import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dream_provider.dart';
import '../../../providers/sleep_provider.dart';
import '../../../models/sleep_session_model.dart';
import '../../../models/sleep_statistics_model.dart';
import '../../../shared/widgets/dream_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/sleep_quality_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dreamProvider = context.read<DreamProvider>();
      final sleepProvider = context.read<SleepProvider>();
      dreamProvider.loadDreams().then((_) {
        if (mounted) {
          sleepProvider.loadSessions(dreams: dreamProvider.allDreams);
        }
      });
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 14) return 'Chào buổi trưa';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sleep = context.watch<SleepProvider>();
    final dream = context.watch<DreamProvider>();

    final userName = auth.user?.name ?? 'Bạn';
    final latestSession = sleep.sessions.isNotEmpty ? sleep.sessions.first : null;
    final stats = sleep.statistics;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.nightSkyGradient,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await dream.loadDreams();
              await sleep.loadSessions(dreams: dream.allDreams);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Lời chào & Ngày hiện tại
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()}, $userName ✨',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormatter.formatWeekday(DateTime.now())}, ${DateFormatter.formatDate(DateTime.now())}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.primaryLight,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Card Tổng quan giấc ngủ đêm qua & Thống kê nhanh
                  _buildSleepSummaryCard(latestSession, stats),
                  const SizedBox(height: 24),

                  // 2 Nút hành động chính: Bắt đầu theo dõi ngủ & Ghi giấc mơ
                  _buildQuickActionButtons(context, sleep.isTracking),
                  const SizedBox(height: 28),

                  // Biểu đồ giấc ngủ 7 ngày qua
                  SectionHeader(
                    title: 'Giấc ngủ 7 ngày qua',
                    subtitle: 'Thời lượng ngủ tính theo giờ mỗi đêm',
                    action: TextButton(
                      onPressed: () => context.go(AppRoutes.analytics),
                      child: const Text('Chi tiết', style: TextStyle(color: AppColors.primaryLight)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWeeklyBarChart(stats),
                  const SizedBox(height: 28),

                  // Giấc mơ gần nhất
                  SectionHeader(
                    title: 'Giấc mơ gần đây',
                    action: TextButton(
                      onPressed: () => context.go(AppRoutes.dreamDiary),
                      child: const Text('Xem tất cả', style: TextStyle(color: AppColors.primaryLight)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentDreams(dream),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSleepSummaryCard(SleepSessionModel? latestSession, SleepStatisticsModel stats) {
    final durationHours = latestSession != null
        ? (latestSession.totalMinutes / 60.0).toStringAsFixed(1)
        : '0.0';
    final qualityScore = latestSession?.qualityScore ?? 0;
    final totalDreams = stats.totalRecordedDreams;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bedtime, color: AppColors.starGold, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Đêm qua của bạn',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  latestSession != null ? DateFormatter.formatRelative(latestSession.startTime) : 'Chưa có dữ liệu',
                  style: const TextStyle(fontSize: 11, color: AppColors.primaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Thời lượng ngủ
              Column(
                children: [
                  Text(
                    '${durationHours}h',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Thời lượng ngủ',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),

              // Vòng tròn điểm chất lượng
              SleepQualityIndicator(score: qualityScore, size: 84),

              // Số giấc mơ
              Column(
                children: [
                  Text(
                    '$totalDreams',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Giấc mơ ghi lại',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context, bool isTrackingActive) {
    return Row(
      children: [
        // Nút Theo dõi giấc ngủ
        Expanded(
          child: GestureDetector(
            onTap: () => context.go(AppRoutes.sleepTracking),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                gradient: isTrackingActive
                    ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                    : AppColors.sleepGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isTrackingActive ? AppColors.error : AppColors.secondary)
                        .withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTrackingActive ? Icons.stop_rounded : Icons.bedtime_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTrackingActive ? 'Đang ngủ...' : 'Theo dõi ngủ',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTrackingActive ? 'Chạm để dừng' : 'Bắt đầu phiên',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Nút Ghi lại giấc mơ
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.addDream),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                gradient: AppColors.dreamGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ghi giấc mơ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lưu giữ cảm xúc',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyBarChart(SleepStatisticsModel stats) {
    final weekly = stats.weeklyStats;
    if (weekly.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Chưa có đủ dữ liệu giấc ngủ', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return Container(
      height: 210,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 12,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(1)} giờ',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 4,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}h',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 4,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(weekly.length, (index) {
            final stat = weekly[index];
            final isGood = stat.hours >= 7.0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: stat.hours,
                  gradient: isGood
                      ? AppColors.primaryGradient
                      : const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                        ),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 12,
                    color: AppColors.surfaceLight.withOpacity(0.4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRecentDreams(DreamProvider dream) {
    final recentDreams = dream.allDreams.take(3).toList();

    if (recentDreams.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Text(
          'Chưa có giấc mơ nào. Hãy ghi lại giấc mơ đầu tiên nhé!',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }

    return Column(
      children: recentDreams.map((d) {
        return DreamCard(
          dream: d,
          onTap: () => context.push('${AppRoutes.dreamDetail}/${d.id}'),
        );
      }).toList(),
    );
  }
}
