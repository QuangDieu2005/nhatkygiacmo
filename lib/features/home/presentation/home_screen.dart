import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/sleep_session_model.dart';
import '../../../models/sleep_statistics_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dream_provider.dart';
import '../../../providers/sleep_provider.dart';
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
    final latestSession = sleep.sessions.isNotEmpty ? sleep.sessions.first : null;
    final today = DateTime.now();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primaryLight,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await dream.loadDreams();
              await sleep.loadSessions(dreams: dream.allDreams);
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 22.0;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(auth.user?.name ?? 'Bạn', today),
                          const SizedBox(height: 26),
                          _buildSleepSummaryCard(
                            latestSession,
                            dream.allDreams.length,
                            sleep.isLoading,
                          ),
                          const SizedBox(height: 20),
                          _buildQuickActionButtons(context, sleep.isTracking),
                          const SizedBox(height: 30),
                          SectionHeader(
                            title: 'Giấc ngủ 7 ngày qua',
                            subtitle: 'Thời lượng theo từng đêm',
                            action: TextButton(
                              onPressed: () => context.go(AppRoutes.analytics),
                              child: const Text('Chi tiết'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildWeeklyBarChart(sleep.statistics),
                          const SizedBox(height: 28),
                          SectionHeader(
                            title: 'Giấc mơ gần đây',
                            action: TextButton(
                              onPressed: () => context.go(AppRoutes.dreamDiary),
                              child: const Text('Xem tất cả'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildRecentDreams(dream),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName, DateTime today) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '${DateFormatter.formatWeekday(today)}, ${DateFormatter.formatDate(today)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
          ),
          child: const Icon(
            Icons.nightlight_round,
            color: AppColors.starGold,
            size: 21,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepSummaryCard(
    SleepSessionModel? latestSession,
    int dreamCount,
    bool isLoading,
  ) {
    final hasSession = latestSession != null;
    final duration = hasSession
        ? '${(latestSession!.totalMinutes / 60).toStringAsFixed(1)}h'
        : '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.starGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.bedtime_rounded, color: AppColors.starGold, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng quan giấc ngủ', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      hasSession
                          ? 'Đêm ${DateFormatter.formatRelative(latestSession!.startTime)}'
                          : 'Đêm gần nhất',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isLoading && !hasSession)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  hasSession ? Icons.nights_stay_rounded : Icons.auto_awesome,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Thời lượng ngủ',
                  value: duration,
                  icon: Icons.schedule_rounded,
                  accent: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              if (hasSession)
                SleepQualityIndicator(score: latestSession!.qualityScore, size: 76)
              else
                _buildQualityEmptyState(),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Giấc mơ đã ghi',
                  value: '$dreamCount',
                  icon: Icons.auto_awesome_rounded,
                  accent: AppColors.primaryLight,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (!hasSession && !isLoading) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Chưa có phiên ngủ nào. Bắt đầu theo dõi để xem thống kê của bạn.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 2,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildQualityEmptyState() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface.withOpacity(0.72),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Icon(Icons.bedtime_outlined, color: AppColors.textMuted, size: 27),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context, bool isTrackingActive) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            title: isTrackingActive ? 'Đang theo dõi' : 'Theo dõi giấc ngủ',
            subtitle: isTrackingActive ? 'Chạm để xem phiên' : 'Bắt đầu phiên ngủ',
            icon: isTrackingActive ? Icons.bedtime_rounded : Icons.nights_stay_rounded,
            gradient: isTrackingActive
                ? const LinearGradient(colors: [Color(0xFFBD6676), Color(0xFF895A9D)])
                : AppColors.sleepGradient,
            onTap: () => context.go(AppRoutes.sleepTracking),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            title: 'Ghi giấc mơ',
            subtitle: 'Lưu lại đêm qua',
            icon: Icons.edit_note_rounded,
            gradient: AppColors.dreamGradient,
            onTap: () => context.push(AppRoutes.addDream),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyBarChart(SleepStatisticsModel stats) {
    final weekly = stats.weeklyStats;
    if (weekly.isEmpty) {
      return _EmptyPanel(
        icon: Icons.bar_chart_rounded,
        message: 'Chưa có dữ liệu giấc ngủ trong tuần này.',
      );
    }

    return Container(
      height: 224,
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 12,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)} giờ',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 27,
                interval: 4,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}h',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= weekly.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      weekly[index].dayLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  );
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
            final reachedGoal = stat.hours >= 7;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: stat.hours.clamp(0, 12).toDouble(),
                  gradient: reachedGoal ? AppColors.primaryGradient : AppColors.sleepGradient,
                  width: weekly.length > 5 ? 14 : 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 12,
                    color: AppColors.surfaceLight.withOpacity(0.42),
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
    if (dream.isLoading && dream.allDreams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (dream.allDreams.isEmpty) {
      return _EmptyPanel(
        icon: Icons.auto_awesome_outlined,
        message: 'Chưa có giấc mơ nào. Hãy ghi lại giấc mơ đầu tiên nhé!',
        action: TextButton.icon(
          onPressed: () => context.push(AppRoutes.addDream),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ghi giấc mơ'),
        ),
      );
    }

    return Column(
      children: dream.allDreams.take(3).map((entry) {
        return DreamCard(
          dream: entry,
          onTap: () => context.push('${AppRoutes.dreamDetail}/${entry.id}'),
        );
      }).toList(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.13),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: Colors.white, size: 21),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 10,
                          height: 1.25,
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
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 25),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}
