import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/dream_model.dart';
import '../../../providers/dream_provider.dart';
import '../../../shared/widgets/dream_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';

class DreamListScreen extends StatefulWidget {
  const DreamListScreen({super.key});

  @override
  State<DreamListScreen> createState() => _DreamListScreenState();
}

class _DreamListScreenState extends State<DreamListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dreamProvider = context.watch<DreamProvider>();
    final filteredDreams = dreamProvider.filteredDreams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký giấc mơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryLight, size: 28),
            onPressed: () => context.push(AppRoutes.addDream),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.nightSkyGradient,
        ),
        child: Column(
          children: [
            // Ô tìm kiếm
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => dreamProvider.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tiêu đề, nội dung, #tag...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            dreamProvider.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Bộ lọc cảm xúc dạng Chips trượt ngang
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(
                    label: 'Tất cả (${dreamProvider.allDreams.length})',
                    isSelected: dreamProvider.selectedEmotion == null,
                    onTap: () => dreamProvider.setSelectedEmotion(null),
                  ),
                  ...EmotionType.values.map((emotion) {
                    final count = dreamProvider.allDreams
                        .where((d) => d.emotion == emotion)
                        .length;
                    return _buildFilterChip(
                      label: '${emotion.emoji} ${emotion.label} ($count)',
                      color: emotion.color,
                      isSelected: dreamProvider.selectedEmotion == emotion,
                      onTap: () => dreamProvider.setSelectedEmotion(emotion),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Danh sách các giấc mơ
            Expanded(
              child: dreamProvider.isLoading
                  ? const LoadingIndicator(message: 'Đang tải những giấc mơ...')
                  : filteredDreams.isEmpty
                      ? EmptyState(
                          icon: Icons.auto_stories_outlined,
                          title: dreamProvider.searchQuery.isNotEmpty
                              ? 'Không tìm thấy kết quả'
                              : 'Chưa có giấc mơ nào',
                          message: dreamProvider.searchQuery.isNotEmpty
                              ? 'Thử tìm với từ khóa khác hoặc xóa bộ lọc cảm xúc'
                              : 'Hãy ghi lại giấc mơ đầu tiên của bạn để không lãng quên ký ức tiềm thức',
                          actionLabel: dreamProvider.searchQuery.isNotEmpty
                              ? 'Xóa tìm kiếm'
                              : 'Ghi lại giấc mơ',
                          onAction: () {
                            if (dreamProvider.searchQuery.isNotEmpty) {
                              _searchController.clear();
                              dreamProvider.setSearchQuery('');
                              dreamProvider.setSelectedEmotion(null);
                            } else {
                              context.push(AppRoutes.addDream);
                            }
                          },
                        )
                      : RefreshIndicator(
                          onRefresh: () => dreamProvider.loadDreams(),
                          child: ListView.builder(
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
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = color ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.surface,
        selectedColor: activeColor.withOpacity(0.2),
        checkmarkColor: activeColor,
        side: BorderSide(
          color: isSelected ? activeColor : AppColors.divider,
          width: 1,
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? activeColor : AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }
}
