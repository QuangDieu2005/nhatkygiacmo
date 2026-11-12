import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/dream_provider.dart';
import '../../../providers/sleep_provider.dart';
import '../../../shared/widgets/dream_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/sleep_quality_indicator.dart';

enum HistoryFilter { all, week, month }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  HistoryFilter _currentFilter = HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _matchesFilter(DateTime date) {
    final now = DateTime.now();
    switch (_currentFilter) {
      case HistoryFilter.all:
        return true;
      case HistoryFilter.week:
        return now.difference(date).inDays <= 7;
      case HistoryFilter.month:
        return now.difference(date).inDays <= 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dreamProvider = context.watch<DreamProvider>();
    final sleepProvider = context.watch<SleepProvider>();

    final filteredDreams = dreamProvider.allDreams.where((d) => _matchesFilter(d.dreamDate)).toList();
    final filteredSessions = sleepProvider.sessions.where((s) => _matchesFilter(s.startTime)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử dữ liệu'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.auto_stories_rounded), text: 'Giấc mơ'),
            Tab(icon: Icon(Icons.bedtime_rounded), text: 'Phiên ngủ'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.nightSkyGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Bộ lọc thời gian: Tất cả, Tuần này, Tháng này
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', HistoryFilter.all),
                    const SizedBox(width: 8),
                    _buildFilterChip('7 ngày qua', HistoryFilter.week),
                    const SizedBox(width: 8),
                    _buildFilterChip('30 ngày qua', HistoryFilter.month),
                  ],
                ),
              ),

              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Lịch sử Giấc mơ
                    filteredDreams.isEmpty
                        ? const EmptyState(
                            icon: Icons.history_rounded,
                            title: 'Không có giấc mơ trong khoảng này',
                            message: 'Hãy chọn mốc thời gian khác để xem thêm',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: filteredDreams.length,
                            itemBuilder: (context, index) {
                              final dream = filteredDreams[index];
                              return DreamCard(
                                dream: dream,
                                onTap: () => context.push('${AppRoutes.dreamDetail}/${dream.id}'),
                              );
                            },
                          ),

                    // Tab 2: Lịch sử Phiên ngủ
                    filteredSessions.isEmpty
                        ? const EmptyState(
                            icon: Icons.nights_stay_outlined,
                            title: 'Không có phiên ngủ trong khoảng này',
                            message: 'Hãy kích hoạt theo dõi ngủ mỗi đêm để ghi lại nhật ký',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: filteredSessions.length,
                            itemBuilder: (context, index) {
                              final session = filteredSessions[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Row(
                                  children: [
                                    SleepQualityIndicator(score: session.qualityScore, size: 54),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormatter.formatDate(session.startTime),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${DateFormatter.formatTime(session.startTime)} - ${session.endTime != null ? DateFormatter.formatTime(session.endTime!) : "Chưa kết thúc"}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          DateFormatter.formatDurationMinutes(session.totalMinutes),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Sâu: ${session.deepSleepMinutes}m',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, HistoryFilter filter) {
    final isSelected = _currentFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _currentFilter = filter;
        });
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
      ),
    );
  }
}
