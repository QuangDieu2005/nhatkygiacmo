import 'package:flutter/material.dart';
import '../models/dream_model.dart';
import '../repositories/dream_repository.dart';

class DreamProvider extends ChangeNotifier {
  final DreamRepository _repository = DreamRepository.instance;

  List<DreamModel> _dreams = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  EmotionType? _selectedEmotion;

  List<DreamModel> get allDreams => _dreams;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  EmotionType? get selectedEmotion => _selectedEmotion;

  List<DreamModel> get filteredDreams {
    var list = List<DreamModel>.from(_dreams);

    if (_selectedEmotion != null) {
      list = list.where((d) => d.emotion == _selectedEmotion).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((d) {
        return d.title.toLowerCase().contains(q) ||
            d.content.toLowerCase().contains(q) ||
            d.tags.any((tag) => tag.toLowerCase().contains(q));
      }).toList();
    }

    return list;
  }

  Future<void> loadDreams() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dreams = await _repository.getAllDreams();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể tải danh sách giấc mơ';
      notifyListeners();
    }
  }

  Future<bool> addDream(DreamModel dream) async {
    try {
      await _repository.addDream(dream);
      _dreams.insert(0, dream);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể thêm giấc mơ';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDream(DreamModel updatedDream) async {
    try {
      await _repository.updateDream(updatedDream);
      final index = _dreams.indexWhere((d) => d.id == updatedDream.id);
      if (index != -1) {
        _dreams[index] = updatedDream;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật giấc mơ';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDream(String id) async {
    try {
      await _repository.deleteDream(id);
      _dreams.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa giấc mơ';
      notifyListeners();
      return false;
    }
  }

  DreamModel? getDreamById(String id) {
    try {
      return _dreams.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedEmotion(EmotionType? emotion) {
    _selectedEmotion = emotion;
    notifyListeners();
  }
}
