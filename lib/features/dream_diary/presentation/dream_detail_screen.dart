import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/dream_model.dart';
import '../../../providers/dream_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';

class DreamDetailScreen extends StatefulWidget {
  final String dreamId;

  const DreamDetailScreen({super.key, required this.dreamId});

  @override
  State<DreamDetailScreen> createState() => _DreamDetailScreenState();
}

class _DreamDetailScreenState extends State<DreamDetailScreen> {
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _requestDream(widget.dreamId);
  }

  @override
  void didUpdateWidget(covariant DreamDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dreamId != widget.dreamId) {
      _isDeleting = false;
      _requestDream(widget.dreamId);
    }
  }

  void _requestDream(String id, {bool retry = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.dreamId != id) return;
      context.read<DreamProvider>().loadDreamById(id, retry: retry);
    });
  }

  Future<void> _confirmDelete(DreamProvider provider) async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.divider),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
          ),
        ),
        title: const Text('Xóa giấc mơ này?'),
        content: const Text(
          'Bản ghi sẽ bị xóa khỏi nhật ký. Bạn không thể hoàn tác thao tác này.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Giữ lại'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Xóa giấc mơ'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);

    try {
      final deleted = await provider.deleteDream(widget.dreamId);
      if (!mounted) return;
      setState(() => _isDeleting = false);

      if (deleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa giấc mơ khỏi nhật ký.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        _showDeleteError();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      _showDeleteError();
    }
  }

  void _showDeleteError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chưa thể xóa giấc mơ. Vui lòng thử lại.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DreamProvider>();
    final dream = provider.getDreamById(widget.dreamId);

    if (dream == null) {
      return switch (provider.dreamRecordLoadStatus(widget.dreamId)) {
        DreamRecordLoadStatus.error => _buildLoadError(
          provider.dreamRecordError(widget.dreamId) ??
              'Chưa thể tải giấc mơ này.',
        ),
        DreamRecordLoadStatus.loaded => _buildNotFound(),
        DreamRecordLoadStatus.idle ||
        DreamRecordLoadStatus.loading => _buildLoading(),
      };
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết giấc mơ')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360
                  ? 16.0
                  : 22.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDreamHeader(dream),
                        const SizedBox(height: 16),
                        _buildEmotionCard(dream),
                        const SizedBox(height: 16),
                        _buildInsightCards(dream),
                        const SizedBox(height: 24),
                        _buildSectionHeading(
                          icon: Icons.notes_rounded,
                          title: 'Câu chuyện giấc mơ',
                        ),
                        const SizedBox(height: 10),
                        _buildDreamContent(dream),
                        if (dream.tags.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSectionHeading(
                            icon: Icons.sell_outlined,
                            title: 'Thẻ phân loại',
                          ),
                          const SizedBox(height: 10),
                          _buildTags(
                            dream,
                            constraints.maxWidth - horizontalPadding * 2,
                          ),
                        ],
                        const SizedBox(height: 20),
                        _buildCreatedAt(dream),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.96),
            border: const Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isDeleting
                      ? null
                      : () =>
                            context.push('${AppRoutes.editDream}/${dream.id}'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'Chỉnh sửa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: AppColors.primaryLight,
                    side: BorderSide(
                      color: AppColors.primary.withOpacity(0.55),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isDeleting
                      ? null
                      : () => _confirmDelete(provider),
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(_isDeleting ? 'Đang xóa' : 'Xóa'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết giấc mơ')),
    body: const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.nightSkyGradient),
      child: Center(child: LoadingIndicator(message: 'Đang tải giấc mơ...')),
    ),
  );

  Widget _buildLoadError(String message) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết giấc mơ')),
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
      child: Center(
        child: EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Chưa tải được giấc mơ',
          message: message,
          actionLabel: 'Thử lại',
          onAction: () => _requestDream(widget.dreamId, retry: true),
        ),
      ),
    ),
  );

  Widget _buildNotFound() {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết giấc mơ')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(
                    Icons.auto_stories_outlined,
                    color: AppColors.primaryLight,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy giấc mơ này',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 7),
                Text(
                  'Bản ghi có thể đã được xóa khỏi nhật ký.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDreamHeader(DreamModel dream) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(
              Icons.nightlight_round,
              size: 25,
              color: AppColors.starGold.withOpacity(0.75),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primaryLight,
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'NHẬT KÝ GIẤC MƠ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryLight,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  dream.title,
                  softWrap: true,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontSize: 25, height: 1.25),
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      DateFormatter.formatDate(dream.dreamDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
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

  Widget _buildEmotionCard(DreamModel dream) {
    final color = dream.emotion.color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              dream.emotion.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cảm xúc khi thức dậy',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 3),
                Text(
                  dream.emotion.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCards(DreamModel dream) {
    return Row(
      children: [
        Expanded(
          child: _InsightCard(
            icon: Icons.visibility_rounded,
            label: 'Độ rõ nét',
            value: '${dream.clarityScore} / 5',
            accent: AppColors.starGold,
            detail: Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < dream.clarityScore
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: AppColors.starGold,
                  size: 15,
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InsightCard(
            icon: Icons.auto_awesome_rounded,
            label: 'Lucid dream',
            value: dream.isLucid ? 'Có' : 'Không',
            accent: dream.isLucid
                ? AppColors.primaryLight
                : AppColors.textSecondary,
            detail: Text(
              dream.isLucid ? 'Biết mình đang mơ' : 'Giấc mơ thông thường',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeading({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryLight),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildDreamContent(DreamModel dream) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: SelectionArea(
        child: Text(
          dream.content,
          softWrap: true,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(height: 1.7, letterSpacing: 0.1),
        ),
      ),
    );
  }

  Widget _buildTags(DreamModel dream, double availableWidth) {
    final maxChipWidth = (availableWidth - 16).clamp(120.0, 360.0).toDouble();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: dream.tags.map((tag) {
        return Container(
          constraints: BoxConstraints(maxWidth: maxChipWidth),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.tag_rounded,
                size: 14,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.primaryLight),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCreatedAt(DreamModel dream) {
    return Row(
      children: [
        const Icon(
          Icons.schedule_rounded,
          size: 14,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Được ghi lại ${DateFormatter.formatDateTime(dream.createdAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Widget detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: accent),
          ),
          const SizedBox(height: 4),
          detail,
        ],
      ),
    );
  }
}
