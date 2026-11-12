import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../models/dream_model.dart';
import '../../../providers/dream_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class AddDreamScreen extends StatefulWidget {
  const AddDreamScreen({super.key});

  @override
  State<AddDreamScreen> createState() => _AddDreamScreenState();
}

class _AddDreamScreenState extends State<AddDreamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();

  EmotionType _selectedEmotion = EmotionType.happy;
  DateTime _dreamDate = DateTime.now();
  int _clarityScore = 4;
  bool _isLucid = false;
  final List<String> _tags = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _tagController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dreamDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dreamDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dream = DreamModel(
      id: 'dream_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_01',
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      emotion: _selectedEmotion,
      tags: _tags,
      clarityScore: _clarityScore,
      isLucid: _isLucid,
      dreamDate: _dreamDate,
      createdAt: DateTime.now(),
    );

    final success = await context.read<DreamProvider>().addDream(dream);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu giấc mơ thành công ✨'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi lại giấc mơ'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: const Text(
              'Lưu',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.nightSkyGradient,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Ngày mơ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: AppColors.primaryLight, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Thời gian: ${DateFormatter.formatDate(_dreamDate)}',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _pickDate,
                        child: const Text('Đổi ngày', style: TextStyle(color: AppColors.primaryLight)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Tiêu đề
                AppTextField(
                  controller: _titleController,
                  label: 'Tiêu đề giấc mơ',
                  hint: 'Ví dụ: Bay lượn trên thành phố sao...',
                  prefixIcon: Icons.title_rounded,
                  validator: (val) => Validators.validateRequired(val, 'tiêu đề giấc mơ'),
                ),
                const SizedBox(height: 18),

                // Nội dung
                AppTextField(
                  controller: _contentController,
                  label: 'Chi tiết giấc mơ',
                  hint: 'Kể lại những gì bạn đã thấy, đã nghe, những người đã gặp và cảm giác lúc đó...',
                  prefixIcon: Icons.edit_note_rounded,
                  maxLines: 5,
                  validator: (val) => Validators.validateRequired(val, 'nội dung giấc mơ'),
                ),
                const SizedBox(height: 24),

                // Chọn cảm xúc
                const Text(
                  'Cảm xúc sau khi tỉnh giấc',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: EmotionType.values.map((emotion) {
                    final isSelected = _selectedEmotion == emotion;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmotion = emotion),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? emotion.color.withOpacity(0.2)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? emotion.color : AppColors.divider,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emotion.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              emotion.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? emotion.color : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Độ rõ nét của giấc mơ (1 - 5)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Độ rõ nét của giấc mơ',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    Text(
                      '$_clarityScore / 5',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                    ),
                  ],
                ),
                Slider(
                  value: _clarityScore.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.divider,
                  onChanged: (val) => setState(() => _clarityScore = val.round()),
                ),
                const SizedBox(height: 12),

                // Switch Giấc mơ sáng suốt (Lucid Dream)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Giấc mơ sáng suốt (Lucid Dream)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    subtitle: const Text(
                      'Bạn ý thức được mình đang mơ trong khi ngủ',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    value: _isLucid,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _isLucid = val),
                  ),
                ),
                const SizedBox(height: 20),

                // Thêm Tags
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _tagController,
                        label: 'Thêm thẻ phân loại',
                        hint: 'Ví dụ: bay, nước, bạn bè...',
                        prefixIcon: Icons.tag_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: _addTag,
                      icon: const Icon(Icons.add_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text('#$tag'),
                        onDeleted: () => _removeTag(tag),
                        backgroundColor: AppColors.surfaceLight,
                        side: BorderSide.none,
                        deleteIconColor: AppColors.textMuted,
                        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 36),

                // Nút Lưu
                AppButton(
                  label: 'Lưu giấc mơ',
                  icon: Icons.check_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
