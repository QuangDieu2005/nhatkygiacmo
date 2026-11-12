import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../models/dream_model.dart';
import '../../../providers/dream_provider.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'dream_form_widgets.dart';

class EditDreamScreen extends StatefulWidget {
  final String dreamId;

  const EditDreamScreen({super.key, required this.dreamId});

  @override
  State<EditDreamScreen> createState() => _EditDreamScreenState();
}

class _EditDreamScreenState extends State<EditDreamScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _titleController;
  TextEditingController? _contentController;
  DreamModel? _originalDream;
  EmotionType _selectedEmotion = EmotionType.neutral;
  DateTime _dreamDate = DateUtils.dateOnly(DateTime.now());
  int _clarityScore = 3;
  bool _isLucid = false;
  List<String> _tags = [];
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final dream = context.read<DreamProvider>().getDreamById(widget.dreamId);
    if (dream != null) {
      _originalDream = dream;
      _titleController = TextEditingController(text: dream.title);
      _contentController = TextEditingController(text: dream.content);
      _selectedEmotion = dream.emotion;
      _dreamDate = dream.dreamDate;
      _clarityScore = dream.clarityScore;
      _isLucid = dream.isLucid;
      _tags = List<String>.from(dream.tags);
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _titleController?.dispose();
    _contentController?.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    final tag = value.trim();
    if (tag.isEmpty || _tags.any((existing) => existing.toLowerCase() == tag.toLowerCase())) {
      return;
    }
    setState(() => _tags.add(tag));
  }

  Future<void> _handleUpdate() async {
    final original = _originalDream;
    final titleController = _titleController;
    final contentController = _contentController;
    if (_isSaving || original == null || titleController == null || contentController == null) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    final updatedDream = original.copyWith(
      title: titleController.text.trim(),
      content: contentController.text.trim(),
      emotion: _selectedEmotion,
      tags: List.unmodifiable(_tags),
      clarityScore: _clarityScore,
      isLucid: _isLucid,
      dreamDate: _dreamDate,
    );

    try {
      final success = await context.read<DreamProvider>().updateDream(updatedDream);
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật giấc mơ thành công ✨'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        _showUpdateError();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showUpdateError();
    }
  }

  void _showUpdateError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chưa thể cập nhật giấc mơ. Vui lòng thử lại.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerDream = context.watch<DreamProvider>().getDreamById(widget.dreamId);
    final original = _originalDream;
    final titleController = _titleController;
    final contentController = _contentController;
    if (!_initialized || providerDream == null || original == null ||
        titleController == null || contentController == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Chỉnh sửa giấc mơ'),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      color: AppColors.primaryLight, size: 38),
                  const SizedBox(height: 14),
                  Text(
                    'Không tìm thấy giấc mơ này.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quay lại danh sách và chọn một giấc mơ khác.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return DreamFormPage(
      title: 'Chỉnh sửa giấc mơ',
      saveLabel: 'Lưu thay đổi',
      isSaving: _isSaving,
      onSave: _handleUpdate,
      child: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            const DreamFormIntro(
              title: 'Chỉnh sửa nhật ký',
              description: 'Cập nhật những chi tiết bạn vừa nhớ thêm.',
            ),
            const DreamFormSectionTitle(title: 'Ngày giấc mơ'),
            DreamDatePickerField(
              date: _dreamDate,
              onDateChanged: (date) => setState(() => _dreamDate = date),
            ),
            const SizedBox(height: 22),
            const DreamFormSectionTitle(title: 'Tiêu đề'),
            AppTextField(
              controller: titleController,
              label: 'Tiêu đề giấc mơ',
              hint: 'Đặt tên ngắn gọn cho giấc mơ',
              prefixIcon: Icons.title_rounded,
              validator: (value) => Validators.validateRequired(value, 'tiêu đề giấc mơ'),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            const DreamFormSectionTitle(
              title: 'Câu chuyện giấc mơ',
              subtitle: 'Chỉnh sửa nội dung nhưng giữ lại những gì bạn muốn nhớ.',
            ),
            AppTextField(
              controller: contentController,
              label: 'Nội dung',
              hint: 'Kể lại những hình ảnh và cảm xúc còn nhớ...',
              prefixIcon: Icons.edit_note_rounded,
              maxLines: 7,
              validator: (value) => Validators.validateRequired(value, 'nội dung giấc mơ'),
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 22),
            const DreamFormSectionTitle(title: 'Cảm xúc khi thức dậy'),
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
              subtitle: 'Các thẻ hiện tại được giữ lại; bạn có thể thêm hoặc xóa.',
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
