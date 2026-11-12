import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/dream_model.dart';
import '../../../providers/dream_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'dream_list_card.dart';

class DreamListScreen extends StatefulWidget {
  const DreamListScreen({super.key});

  @override
  State<DreamListScreen> createState() => _DreamListScreenState();
}

class _DreamListScreenState extends State<DreamListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<DreamProvider>().searchQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DreamProvider>().loadDreams();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() => context.read<DreamProvider>().loadDreams();

  void _clearFilters(DreamProvider provider) {
    _searchController.clear();
    provider.setSearchQuery('');
    provider.setSelectedEmotion(null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DreamProvider>();
    final dreams = provider.filteredDreams;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primaryLight,
            backgroundColor: AppColors.surface,
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 22.0;
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 18),
                      sliver: SliverToBoxAdapter(child: _buildHeader(context)),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      sliver: SliverToBoxAdapter(child: _buildSearchField(provider)),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.only(top: 18, bottom: 8),
                      sliver: SliverToBoxAdapter(
                        child: _buildEmotionFilters(provider, horizontalPadding),
                      ),
                    ),
                    if (provider.isLoading && provider.allDreams.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: LoadingIndicator(message: 'Đang tải nhật ký giấc mơ...'),
                      )
                    else if (provider.errorMessage != null && provider.allDreams.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildErrorState(provider),
                      )
                    else if (dreams.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(provider),
                      )
                    else ...[
                      if (provider.errorMessage != null)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 10),
                          sliver: SliverToBoxAdapter(child: _buildInlineError(provider)),
                        ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 28),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final dream = dreams[index];
                              return DreamListCard(
                                dream: dream,
                                onTap: () => context.push(
                                  '${AppRoutes.dreamDetail}/${dream.id}',
                                ),
                              );
                            },
                            childCount: dreams.length,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Không gian của bạn', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 5),
              Text(
                'Nhật ký giấc mơ',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Lưu lại những câu chuyện và cảm xúc còn đọng lại sau mỗi đêm.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton.filled(
            tooltip: 'Thêm giấc mơ',
            onPressed: () => context.push(AppRoutes.addDream),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.18),
              foregroundColor: AppColors.primaryLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: AppColors.primary.withOpacity(0.28)),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(DreamProvider provider) {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: provider.setSearchQuery,
      decoration: InputDecoration(
        hintText: 'Tìm theo tiêu đề, nội dung hoặc tag',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: provider.searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Xóa tìm kiếm',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildEmotionFilters(DreamProvider provider, double horizontalPadding) {
    final selectedEmotion = provider.selectedEmotion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              Expanded(
                child: Text('Lọc theo cảm xúc', style: Theme.of(context).textTheme.titleMedium),
              ),
              Text(
                '${provider.filteredDreams.length} giấc mơ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            children: [
              _buildFilterChip(
                label: 'Tất cả',
                count: provider.allDreams.length,
                isSelected: selectedEmotion == null,
                onTap: () => provider.setSelectedEmotion(null),
              ),
              ...EmotionType.values.map((emotion) {
                final count = provider.allDreams.where((dream) => dream.emotion == emotion).length;
                return _buildFilterChip(
                  label: '${emotion.emoji} ${emotion.label}',
                  count: count,
                  color: emotion.color,
                  isSelected: selectedEmotion == emotion,
                  onTap: () => provider.setSelectedEmotion(emotion),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final accent = color ?? AppColors.primaryLight;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.surface.withOpacity(0.82),
        selectedColor: accent.withOpacity(0.18),
        side: BorderSide(color: isSelected ? accent.withOpacity(0.6) : AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        label: Text('$label  $count'),
        labelStyle: TextStyle(
          color: isSelected ? accent : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState(DreamProvider provider) {
    final hasActiveFilter = provider.searchQuery.trim().isNotEmpty ||
        provider.selectedEmotion != null;
    if (hasActiveFilter) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy giấc mơ',
        message: 'Thử từ khóa khác hoặc xóa bộ lọc để xem lại toàn bộ nhật ký.',
        actionLabel: 'Xóa bộ lọc',
        onAction: () => _clearFilters(provider),
      );
    }
    return EmptyState(
      icon: Icons.auto_stories_outlined,
      title: 'Chưa có giấc mơ nào',
      message: 'Ghi lại những hình ảnh và cảm xúc bạn còn nhớ sau khi thức dậy.',
      actionLabel: 'Ghi giấc mơ đầu tiên',
      onAction: () => context.push(AppRoutes.addDream),
    );
  }

  Widget _buildErrorState(DreamProvider provider) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Chưa tải được nhật ký',
      message: provider.errorMessage ?? 'Đã có lỗi khi tải dữ liệu.',
      actionLabel: 'Thử lại',
      onAction: () => provider.loadDreams(),
    );
  }

  Widget _buildInlineError(DreamProvider provider) {
    return Material(
      color: AppColors.error.withOpacity(0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => provider.loadDreams(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Không thể làm mới. Chạm để thử lại.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
                ),
              ),
              const Icon(Icons.refresh_rounded, color: AppColors.error, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
