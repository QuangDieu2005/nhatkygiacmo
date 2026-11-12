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

class EditDreamScreen extends StatefulWidget {
  final String dreamId;

  const EditDreamScreen({super.key, required this.dreamId});

  @override
  State<EditDreamScreen> createState() => _EditDreamScreenState();
}

class _EditDreamScreenState extends State<EditDreamScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final TextEditingController _tagController = TextEditingController();

  late EmotionType _selectedEmotion;
  late DateTime _dreamDate;
  late int _clarityScore;
  late bool _isLucid;
  late List<String> _tags;
  bool _isInit = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final dream = context.read<DreamProvider>().getDreamById(widget.dreamId);
      if (dream != null) {
        _titleController = TextEditingController(text: dream.title);
        _contentController = TextEditingController(text: dream.content);
        _selectedEmotion = dream.emotion;
        _dreamDate = dream.dreamDate;
        _clarityScore = dream.clarityScore;
        _isLucid = dream.isLucid;
        _tags = List.from(dream.tags);
      } else {
        _titleController = TextEditingController();
        _contentController = TextEditingController();
        _selectedEmotion = EmotionType.neutral;
        _dreamDate = DateTime.now();
        _clarityScore = 3;
        _isLucid = false;
        _tags = [];
      }
      _isInit = true;
    }
  }

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

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedDream = DreamModel(
      id: widget.dreamId,
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

    final success = await context.read<DreamProvider>().updateDream(updatedDream);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật giấc mơ thành công ✨'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dream = context.watch<DreamProvider>().getDreamById(widget.dreamId);
    if (dream == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chỉnh sửa giấc mơ')),
        body: const Center(child: Text('Không tìm thấy giấc mơ')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa giấc mơ'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleUpdate,
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
                      Text(
                        'Thời gian: ${DateFormatter.formatDate(_dreamDate)}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dreamDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _dreamDate = picked);
                        },
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
                  validator: (val) => Validators.validateRequired(val, 'tiêu đề giấc mơ'),
                ),
                const SizedBox(height: 18),

                // Nội dung
                AppTextField(
                  controller: _contentController,
                  label: 'Chi tiết giấc mơ',
                  maxLines: 5,
                  validator: (val) => Validators.validateRequired(val, 'nội dung giấc mơ'),
                ),
                const SizedBox(height: 24),

                // Cảm xúc
                const Text(
                  'Cảm xúc sau khi tỉnh giấc',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: EmotionType.values.map((emotion) {
                    final isSelected = _selectedEmotion == emotion;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmotion = emotion),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? emotion.color.withOpacity(0.2) : AppColors.surface,
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

                // Độ rõ nét
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Độ rõ nét', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('$_clarityScore / 5', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
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

                // Lucid Dream
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Giấc mơ sáng suốt (Lucid Dream)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    value: _isLucid,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _isLucid = val),
                  ),
                ),
                const SizedBox(height: 20),

                // Tags
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _tagController,
                        label: 'Thêm thẻ phân loại',
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
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 36),

                AppButton(
                  label: 'Cập nhật giấc mơ',
                  icon: Icons.save_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleUpdate,
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
