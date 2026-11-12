import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/dream_model.dart';
import '../../../shared/widgets/app_button.dart';

class DreamFormPage extends StatelessWidget {
  const DreamFormPage({
    super.key,
    required this.title,
    required this.saveLabel,
    required this.isSaving,
    required this.onSave,
    required this.child,
  });

  final String title;
  final String saveLabel;
  final bool isSaving;
  final VoidCallback onSave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
        child: SafeArea(bottom: false, child: child),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.96),
            border: const Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: AppButton(
            label: saveLabel,
            icon: Icons.check_rounded,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSave,
          ),
        ),
      ),
    );
  }
}

class DreamFormIntro extends StatelessWidget {
  const DreamFormIntro({super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.primaryLight, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DreamFormSectionTitle extends StatelessWidget {
  const DreamFormSectionTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class DreamDatePickerField extends StatefulWidget {
  const DreamDatePickerField({
    super.key,
    required this.date,
    required this.onDateChanged,
  });

  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<DreamDatePickerField> createState() => _DreamDatePickerFieldState();
}

class _DreamDatePickerFieldState extends State<DreamDatePickerField> {

  Future<void> _showPicker(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final currentDate = DateUtils.dateOnly(widget.date);
    final initialDate = currentDate.isAfter(today) ? today : currentDate;
    final theme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: today,
      builder: (context, child) => Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: AppColors.primaryLight,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) widget.onDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _showPicker(context),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    color: AppColors.primaryLight, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ngày giấc mơ', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 3),
                    Text(DateFormatter.formatDate(widget.date),
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              const Icon(Icons.edit_calendar_rounded,
                  color: AppColors.primaryLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class DreamEmotionSelector extends StatelessWidget {
  const DreamEmotionSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final EmotionType value;
  final ValueChanged<EmotionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: EmotionType.values.map((emotion) {
        final selected = value == emotion;
        return ChoiceChip(
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => onChanged(emotion),
          backgroundColor: AppColors.surface,
          selectedColor: emotion.color.withOpacity(0.16),
          side: BorderSide(
            color: selected ? emotion.color.withOpacity(0.7) : AppColors.divider,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          label: Text('${emotion.emoji}  ${emotion.label}'),
          labelStyle: TextStyle(
            color: selected ? emotion.color : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}

class DreamClaritySelector extends StatelessWidget {
  const DreamClaritySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  String get _description => switch (value) {
        1 => 'Mờ nhạt, chỉ nhớ vài chi tiết',
        2 => 'Nhớ được một số hình ảnh',
        3 => 'Khá rõ, nhớ phần chính',
        4 => 'Rõ ràng với nhiều chi tiết',
        _ => 'Rất sống động và chân thực',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_rounded, color: AppColors.starGold, size: 19),
              const SizedBox(width: 9),
              Expanded(child: Text('Độ rõ nét', style: Theme.of(context).textTheme.titleMedium)),
              Text('$value / 5', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.starGold,
              )),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$value / 5',
            onChanged: (score) => onChanged(score.round()),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(_description, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class DreamLucidCard extends StatelessWidget {
  const DreamLucidCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value ? AppColors.primary.withOpacity(0.5) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Giấc mơ sáng suốt', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text('Bạn biết mình đang mơ', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class DreamTagEditor extends StatefulWidget {
  const DreamTagEditor({
    super.key,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> tags;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<DreamTagEditor> createState() => _DreamTagEditorState();
}

class _DreamTagEditorState extends State<DreamTagEditor> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final tag = _controller.text.trim();
    if (tag.isEmpty) return;
    widget.onAdd(tag);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Thẻ phân loại',
                  hintText: 'Ví dụ: bay, biển, gia đình',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: IconButton.filled(
                tooltip: 'Thêm thẻ',
                onPressed: _submit,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        ),
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: widget.tags.map((tag) {
              return InputChip(
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190),
                  child: Text('#$tag', maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                onDeleted: () => widget.onRemove(tag),
                backgroundColor: AppColors.surfaceLight,
                deleteIconColor: AppColors.textSecondary,
                side: BorderSide.none,
                labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
