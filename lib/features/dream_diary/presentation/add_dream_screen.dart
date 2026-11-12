import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../models/dream_model.dart';
import '../../../providers/dream_provider.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'dream_form_widgets.dart';

class AddDreamScreen extends StatefulWidget {
  const AddDreamScreen({super.key});

  @override
  State<AddDreamScreen> createState() => _AddDreamScreenState();
}

class _AddDreamScreenState extends State<AddDreamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  EmotionType _selectedEmotion = EmotionType.happy;
  DateTime _dreamDate = DateUtils.dateOnly(DateTime.now());
  int _clarityScore = 4;
  bool _isLucid = false;
  final List<String> _tags = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    final tag = value.trim();
    if (tag.isEmpty || _tags.any((existing) => existing.toLowerCase() == tag.toLowerCase())) {
      return;
    }
    setState(() => _tags.add(tag));
  }

  Future<void> _handleSave() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final dream = DreamModel(
      id: 'dream_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_01',
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      emotion: _selectedEmotion,
      tags: List.unmodifiable(_tags),
      clarityScore: _clarityScore,
      isLucid: _isLucid,
      dreamDate: _dreamDate,
      createdAt: DateTime.now(),
    );

    try {
      final success = await context.read<DreamProvider>().addDream(dream);
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu giấc mơ thành công ✨'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        _showSaveError();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSaveError();
    }
  }

  void _showSaveError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chưa thể lưu giấc mơ. Vui lòng thử lại.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DreamFormPage(
      title: 'Giấc mơ mới',
      saveLabel: 'Lưu giấc mơ',
      isSaving: _isSaving,
      onSave: _handleSave,
      child: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            const DreamFormIntro(
              title: 'Ghi lại giấc mơ',
              description: 'Những chi tiết nhỏ hôm nay có thể trở thành ký ức quý giá.',
            ),
            DreamFormSectionTitle(title: 'Ngày giấc mơ'),
            DreamDatePickerField(
              date: _dreamDate,
              onDateChanged: (date) => setState(() => _dreamDate = date),
            ),
            const SizedBox(height: 22),
            const DreamFormSectionTitle(title: 'Tiêu đề'),
            AppTextField(
              controller: _titleController,
              label: 'Tiêu đề giấc mơ',
              hint: 'Ví dụ: Chuyến bay qua thành phố về đêm',
              prefixIcon: Icons.title_rounded,
              validator: (value) => Validators.validateRequired(value, 'tiêu đề giấc mơ'),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            const DreamFormSectionTitle(
              title: 'Câu chuyện giấc mơ',
              subtitle: 'Kể lại hình ảnh, âm thanh và cảm xúc bạn còn nhớ.',
            ),
            AppTextField(
              controller: _contentController,
              label: 'Nội dung',
              hint: 'Mình đang ở đâu? Điều gì đã xảy ra? Bạn cảm thấy thế nào?',
              prefixIcon: Icons.edit_note_rounded,
              maxLines: 7,
              validator: (value) => Validators.validateRequired(value, 'nội dung giấc mơ'),
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 22),
            const DreamFormSectionTitle(
              title: 'Cảm xúc khi thức dậy',
              subtitle: 'Chọn cảm xúc gần nhất với trải nghiệm của bạn.',
            ),
            DreamEmotionSelector(
              value: _selectedEmotion,
              onChanged: (emotion) => setState(() => _selectedEmotion = emotion),
            ),
            const SizedBox(height: 22),
            const DreamFormSectionTitle(title: 'Mức độ ghi nhớ'),
            DreamClaritySelector(
              value: _clarityScore,
              onChanged: (score) => setState(() => _clarityScore = score),
            ),
            const SizedBox(height: 16),
            DreamLucidCard(
              value: _isLucid,
              onChanged: (value) => setState(() => _isLucid = value),
            ),
            const SizedBox(height: 22),
            const DreamFormSectionTitle(
              title: 'Thẻ phân loại',
              subtitle: 'Thêm vài từ khóa để dễ tìm lại sau này.',
            ),
            DreamTagEditor(
              tags: _tags,
              onAdd: _addTag,
              onRemove: (tag) => setState(() => _tags.remove(tag)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
