import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/dream_model.dart';
import '../../../providers/dream_provider.dart';

class DreamDetailScreen extends StatelessWidget {
  final String dreamId;

  const DreamDetailScreen({super.key, required this.dreamId});

  Future<void> _handleDelete(BuildContext context, DreamProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xác nhận xóa', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Bạn có chắc chắn muốn xóa giấc mơ này không? Hành động này không thể hoàn tác.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.deleteDream(dreamId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa giấc mơ'),
            backgroundColor: AppColors.error,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dreamProvider = context.watch<DreamProvider>();
    final dream = dreamProvider.getDreamById(dreamId);

    if (dream == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết giấc mơ')),
        body: const Center(
          child: Text('Không tìm thấy giấc mơ này', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final emotionColor = dream.emotion.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết giấc mơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('${AppRoutes.editDream}/$dreamId'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _handleDelete(context, dreamProvider),
          ),
        ],
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
                // Header Cảm xúc & Ngày tháng
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: emotionColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: emotionColor.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Text(dream.emotion.emoji, style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dream.emotion.label,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: emotionColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormatter.formatDateTime(dream.dreamDate),
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (dream.isLucid)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryLight),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: AppColors.starGold, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Lucid',
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tiêu đề giấc mơ
                Text(
                  dream.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Độ rõ nét
                Row(
                  children: [
                    const Text('Độ rõ nét: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < dream.clarityScore ? Icons.star_rounded : Icons.star_border_rounded,
                          color: AppColors.starGold,
                          size: 20,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Đường kẻ chia cắt
                const Divider(),
                const SizedBox(height: 20),

                // Nội dung câu chuyện giấc mơ
                const Text(
                  'Nội dung giấc mơ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    dream.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.7,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                // Tags nếu có
                if (dream.tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Thẻ phân loại',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dream.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
