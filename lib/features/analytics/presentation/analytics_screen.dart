import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/dream_model.dart';
import '../../../models/sleep_session_model.dart';
import '../../../models/sleep_statistics_model.dart';
import '../../../providers/dream_provider.dart';
import '../../../providers/sleep_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sleep = context.read<SleepProvider>();
      if (!sleep.isLoading && !sleep.hasLoadedSessions) {
        _reload(sleep);
      }
    });
  }

  Future<void> _reload(SleepProvider provider) {
    final dreams = context.read<DreamProvider>();
    return provider.loadSessions(
      dreams: dreams.hasSuccessfulLoad ? dreams.allDreams : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SleepProvider>();
    final dreamProvider = context.watch<DreamProvider>();
    final sessions =
        provider.sessions
            .where((session) => !session.isTracking && session.endTime != null)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê giấc ngủ')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => provider.loadSessions(
              dreams: dreamProvider.hasSuccessfulLoad
                  ? dreamProvider.allDreams
                  : null,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child:
                            (provider.isLoading ||
                                    !provider.hasLoadedStatistics) &&
                                !provider.hasSuccessfulStatisticsLoad &&
                                provider.statisticsErrorMessage == null &&
                                provider.sessionsErrorMessage == null
                            ? const _LoadingState()
                            : provider.sessionsErrorMessage != null ||
                                  provider.statisticsErrorMessage != null
                            ? _ErrorState(
                                message:
                                    provider.sessionsErrorMessage ??
                                    provider.statisticsErrorMessage!,
                                onRetry: () => _reload(provider),
                              )
                            : sessions.isEmpty
                            ? const _EmptyState()
                            : _AnalyticsContent(
                                sessions: sessions,
                                columns: width >= 560 ? 4 : 2,
                                statistics: provider.statistics,
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.sessions,
    required this.columns,
    required this.statistics,
  });

  final List<SleepSessionModel> sessions;
  final int columns;
  final SleepStatisticsModel statistics;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = sessions.fold<int>(
      0,
      (sum, item) => sum + item.totalMinutes,
    );
    final averageMinutes = (totalMinutes / sessions.length).round();
    final averageQuality =
        (sessions.fold<int>(0, (sum, item) => sum + item.qualityScore) /
                sessions.length)
            .round();
    final longest = sessions.reduce(
      (a, b) => a.totalMinutes >= b.totalMinutes ? a : b,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageIntro(),
        const SizedBox(height: 22),
        _MetricGrid(
          columns: columns,
          items: [
            _MetricData(
              icon: Icons.bedtime_rounded,
              label: 'Thời lượng trung bình',
              value: _formatDuration(averageMinutes),
              tint: AppColors.primaryLight,
            ),
            _MetricData(
              icon: Icons.auto_awesome_rounded,
              label: 'Chất lượng trung bình',
              value: '$averageQuality',
              suffix: '/100',
              tint: AppColors.starGold,
            ),
            _MetricData(
              icon: Icons.nights_stay_rounded,
              label: 'Đêm đã ghi nhận',
              value: '${sessions.length}',
              tint: AppColors.secondary,
            ),
            _MetricData(
              icon: Icons.hotel_rounded,
              label: 'Đêm dài nhất',
              value: _formatDuration(longest.totalMinutes),
              tint: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 28),
        _SectionTitle(
          title: 'Thời lượng ngủ',
          subtitle: 'Số giờ ngủ theo ngày bắt đầu phiên',
          icon: Icons.show_chart_rounded,
        ),
        const SizedBox(height: 12),
        _DurationChart(sessions: sessions),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Chất lượng giấc ngủ',
          subtitle: 'Điểm ghi nhận theo thang 0–100',
          icon: Icons.insights_rounded,
        ),
        const SizedBox(height: 12),
        _QualityChart(sessions: sessions),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Các giai đoạn ngủ',
          subtitle: 'Tổng thời lượng từ những phiên có ghi nhận giai đoạn',
          icon: Icons.donut_large_rounded,
        ),
        const SizedBox(height: 12),
        _SleepStages(sessions: sessions),
        const SizedBox(height: 24),
        if (statistics.emotionDistribution.isNotEmpty) ...[
          const _SectionTitle(
            title: 'Cảm xúc trong giấc mơ',
            subtitle: 'Phân bố cảm xúc từ các bản ghi được cung cấp',
            icon: Icons.favorite_outline_rounded,
          ),
          const SizedBox(height: 12),
          _EmotionChart(distribution: statistics.emotionDistribution),
          const SizedBox(height: 24),
        ],
        _ObservationCard(sessions: sessions, averageMinutes: averageMinutes),
      ],
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: AppColors.cardGradient,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.primary.withOpacity(.24)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(.16),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.nights_stay_rounded,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhịp nghỉ ngơi của bạn',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tổng hợp từ các phiên ngủ đã hoàn tất.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    this.suffix = '',
  });

  final IconData icon;
  final String label;
  final String value;
  final String suffix;
  final Color tint;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items, required this.columns});

  final List<_MetricData> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += columns) {
      final rowItems = items.skip(i).take(columns).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < rowItems.length; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(child: _MetricCard(data: rowItems[j])),
              ],
            ],
          ),
        ),
      );
      if (i + columns < items.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(data.icon, color: data.tint, size: 21),
        const SizedBox(height: 13),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (data.suffix.isNotEmpty)
                Text(
                  data.suffix,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          data.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: AppColors.primaryLight),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DurationChart extends StatelessWidget {
  const _DurationChart({required this.sessions});
  final List<SleepSessionModel> sessions;

  @override
  Widget build(BuildContext context) {
    final daily = _dailySessions(sessions);
    final maxHours = daily
        .map((entry) => entry.session.totalMinutes / 60)
        .fold<double>(0, (max, hours) => hours > max ? hours : max);
    final chartMax = (maxHours + 1).clamp(5, 12).toDouble();
    return _ChartCard(
      height: 220,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: chartMax,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    '${rod.toY.toStringAsFixed(1)} giờ',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ),
          gridData: _gridData(2),
          borderData: FlBorderData(show: false),
          titlesData: _chartTitles(
            maxY: chartMax,
            interval: 2,
            bottom: (value) => _dayLabel(daily, value),
          ),
          barGroups: [
            for (var i = 0; i < daily.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: daily[i].session.totalMinutes / 60,
                    width: daily.length > 5 ? 16 : 22,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(7),
                    ),
                    gradient: AppColors.sleepGradient,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: chartMax,
                      color: AppColors.surfaceLight.withOpacity(.45),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _QualityChart extends StatelessWidget {
  const _QualityChart({required this.sessions});
  final List<SleepSessionModel> sessions;

  @override
  Widget build(BuildContext context) {
    final daily = _dailySessions(sessions);
    return _ChartCard(
      height: 205,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map(
                    (spot) => LineTooltipItem(
                      '${spot.y.round()}/100',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          gridData: _gridData(25),
          borderData: FlBorderData(show: false),
          titlesData: _chartTitles(
            maxY: 100,
            interval: 25,
            bottom: (value) => _dayLabel(daily, value),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < daily.length; i++)
                  FlSpot(
                    i.toDouble(),
                    daily[i].session.qualityScore.toDouble(),
                  ),
              ],
              isCurved: true,
              color: AppColors.starGold,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.starGold,
                  strokeWidth: 2,
                  strokeColor: AppColors.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.starGold.withOpacity(.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepStages extends StatelessWidget {
  const _SleepStages({required this.sessions});
  final List<SleepSessionModel> sessions;

  @override
  Widget build(BuildContext context) {
    final recorded = sessions
        .where(
          (session) =>
              session.deepSleepMinutes +
                  session.lightSleepMinutes +
                  session.remSleepMinutes >
              0,
        )
        .toList();
    if (recorded.isEmpty) {
      return const _EmptyCard(
        icon: Icons.donut_large_rounded,
        message: 'Chưa có phiên nào ghi nhận thời lượng các giai đoạn ngủ.',
      );
    }
    final deep = recorded.fold<int>(
      0,
      (sum, item) => sum + item.deepSleepMinutes,
    );
    final light = recorded.fold<int>(
      0,
      (sum, item) => sum + item.lightSleepMinutes,
    );
    final rem = recorded.fold<int>(
      0,
      (sum, item) => sum + item.remSleepMinutes,
    );
    final total = deep + light + rem;
    final parts = [
      _StageData('Ngủ sâu', deep, AppColors.primaryLight),
      _StageData('Ngủ nông', light, AppColors.secondary),
      _StageData('REM', rem, AppColors.starGold),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 42,
                sectionsSpace: 3,
                sections: [
                  for (final part in parts)
                    if (part.minutes > 0)
                      PieChartSectionData(
                        value: part.minutes.toDouble(),
                        color: part.color,
                        radius: 28,
                        title: '${(part.minutes * 100 / total).round()}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final part in parts)
            if (part.minutes > 0) ...[
              _StageLegend(part: part, total: total),
              const SizedBox(height: 10),
            ],
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tổng hợp thời lượng đã ghi nhận; không phải phép đo y tế.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionChart extends StatelessWidget {
  const _EmotionChart({required this.distribution});
  final Map<EmotionType, int> distribution;

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold<int>(0, (sum, value) => sum + value);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 38,
                sectionsSpace: 3,
                sections: [
                  for (final entry in distribution.entries)
                    if (entry.value > 0)
                      PieChartSectionData(
                        value: entry.value.toDouble(),
                        color: entry.key.color,
                        radius: 28,
                        title: '${(entry.value * 100 / total).round()}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              for (final entry in distribution.entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: entry.key.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${entry.key.label} (${entry.value})',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageData {
  const _StageData(this.label, this.minutes, this.color);
  final String label;
  final int minutes;
  final Color color;
}

class _StageLegend extends StatelessWidget {
  const _StageLegend({required this.part, required this.total});
  final _StageData part;
  final int total;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: part.color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          part.label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ),
      Text(
        '${_formatDuration(part.minutes)} · ${(part.minutes * 100 / total).round()}%',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _ObservationCard extends StatelessWidget {
  const _ObservationCard({
    required this.sessions,
    required this.averageMinutes,
  });
  final List<SleepSessionModel> sessions;
  final int averageMinutes;

  @override
  Widget build(BuildContext context) {
    final latest = sessions.last;
    final earliest = sessions.first;
    final qualityTrend = latest.qualityScore - earliest.qualityScore;
    final trendText = qualityTrend == 0
        ? 'Điểm chất lượng ở hai bản ghi đầu và gần nhất bằng nhau.'
        : 'Điểm ở bản ghi gần nhất ${qualityTrend > 0 ? 'cao hơn' : 'thấp hơn'} '
              '${qualityTrend.abs()} điểm so với bản ghi đầu tiên.';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            color: AppColors.primaryLight,
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ghi nhận từ dữ liệu',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Trung bình ${_formatDuration(averageMinutes)} mỗi đêm trong '
                  '${sessions.length} đêm. $trendText',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: const EdgeInsets.fromLTRB(10, 18, 16, 12),
    decoration: _cardDecoration(),
    child: child,
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 100),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(
      children: [
        _EmptyCard(icon: Icons.cloud_off_rounded, message: message),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Thử tải lại'),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 60),
    child: _EmptyCard(
      icon: Icons.nights_stay_outlined,
      message: 'Chưa có phiên ngủ hoàn tất để tổng hợp.',
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 30),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

List<({DateTime date, SleepSessionModel session})> _dailySessions(
  List<SleepSessionModel> sessions,
) {
  final byDay = <DateTime, SleepSessionModel>{};
  for (final session in sessions) {
    final date = DateTime(
      session.startTime.year,
      session.startTime.month,
      session.startTime.day,
    );
    final previous = byDay[date];
    if (previous == null || session.totalMinutes > previous.totalMinutes) {
      byDay[date] = session;
    }
  }
  final entries = byDay.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final recent = entries.length > 7
      ? entries.sublist(entries.length - 7)
      : entries;
  return recent
      .map((entry) => (date: entry.key, session: entry.value))
      .toList();
}

String _dayLabel(
  List<({DateTime date, SleepSessionModel session})> days,
  double value,
) {
  final index = value.toInt();
  if (value != index.toDouble() || index < 0 || index >= days.length) return '';
  return '${days[index].date.day}/${days[index].date.month}';
}

FlGridData _gridData(double interval) => FlGridData(
  show: true,
  drawVerticalLine: false,
  horizontalInterval: interval,
  getDrawingHorizontalLine: (_) =>
      const FlLine(color: AppColors.divider, strokeWidth: 1),
);

FlTitlesData _chartTitles({
  required double maxY,
  required double interval,
  required String Function(double) bottom,
}) => FlTitlesData(
  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  leftTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 34,
      interval: interval,
      getTitlesWidget: (value, _) => Text(
        maxY <= 12 ? '${value.toInt()}h' : '${value.toInt()}',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
      ),
    ),
  ),
  bottomTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      interval: 1,
      reservedSize: 26,
      getTitlesWidget: (value, _) => Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Text(
          bottom(value),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ),
    ),
  ),
);

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours == 0) return '${remainder}p';
  if (remainder == 0) return '${hours}h';
  return '${hours}h ${remainder.toString().padLeft(2, '0')}p';
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: AppColors.divider),
);
