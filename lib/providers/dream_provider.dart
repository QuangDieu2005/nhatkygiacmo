import 'package:flutter/material.dart';

import '../models/dream_model.dart';
import '../repositories/dream_repository.dart';

enum DreamRecordLoadStatus { idle, loading, loaded, error }

class DreamProvider extends ChangeNotifier {
  DreamProvider({DreamDataRepository? repository})
    : _repository = repository ?? DreamRepository.instance;

  final DreamDataRepository _repository;

  List<DreamModel> _dreams = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _hasSuccessfulLoad = false;
  String? _errorMessage;
  int _loadRequest = 0;
  final Map<String, DreamModel> _dreamDetails = {};
  final Map<String, DreamRecordLoadStatus> _dreamRecordStatuses = {};
  final Map<String, String> _dreamRecordErrors = {};
  final Map<String, Future<DreamModel?>> _dreamRecordRequests = {};
  String _searchQuery = '';
  EmotionType? _selectedEmotion;

  List<DreamModel> get allDreams => _dreams;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  bool get hasSuccessfulLoad => _hasSuccessfulLoad;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  EmotionType? get selectedEmotion => _selectedEmotion;

  DreamRecordLoadStatus dreamRecordLoadStatus(String id) =>
      _dreamRecordStatuses[id] ?? DreamRecordLoadStatus.idle;

  String? dreamRecordError(String id) => _dreamRecordErrors[id];

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
    final request = ++_loadRequest;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedDreams = await _repository.getAllDreams();
      if (request != _loadRequest) return;
      _dreams = loadedDreams;
      _isLoading = false;
      _hasLoaded = true;
      _hasSuccessfulLoad = true;
      notifyListeners();
    } catch (e) {
      if (request != _loadRequest) return;
      _isLoading = false;
      _hasLoaded = true;
      _errorMessage = 'Không thể tải danh sách giấc mơ';
      notifyListeners();
    }
  }

  Future<DreamModel?> loadDreamById(String id, {bool retry = false}) {
    final cached = getDreamById(id);
    if (cached != null) {
      _dreamRecordStatuses[id] = DreamRecordLoadStatus.loaded;
      _dreamRecordErrors.remove(id);
      return Future.value(cached);
    }

    final pending = _dreamRecordRequests[id];
    if (pending != null) return pending;

    final status = dreamRecordLoadStatus(id);
    if (!retry &&
        (status == DreamRecordLoadStatus.loaded ||
            status == DreamRecordLoadStatus.error)) {
      return Future.value(null);
    }

    _dreamRecordStatuses[id] = DreamRecordLoadStatus.loading;
    _dreamRecordErrors.remove(id);
    notifyListeners();

    final request = _repository
        .getDreamById(id)
        .then((dream) {
          if (dream != null && dream.id == id) {
            _dreamDetails[id] = dream;
          }
          _dreamRecordStatuses[id] = DreamRecordLoadStatus.loaded;
          _dreamRecordErrors.remove(id);
          notifyListeners();
          return dream?.id == id ? dream : null;
        })
        .catchError((Object error) {
          _dreamRecordStatuses[id] = DreamRecordLoadStatus.error;
          _dreamRecordErrors[id] = 'KhÃ´ng thá»ƒ táº£i giáº¥c mÆ¡ nÃ y';
          notifyListeners();
          return null;
        })
        .whenComplete(() {
          _dreamRecordRequests.remove(id);
        });
    _dreamRecordRequests[id] = request;
    return request;
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
      }
      if (_dreamDetails.containsKey(updatedDream.id)) {
        _dreamDetails[updatedDream.id] = updatedDream;
      }
      notifyListeners();
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
      _dreamDetails.remove(id);
      _dreamRecordStatuses.remove(id);
      _dreamRecordErrors.remove(id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa giấc mơ';
      notifyListeners();
      return false;
    }
  }

  DreamModel? getDreamById(String id) {
    final inList = _dreams.where((dream) => dream.id == id);
    if (inList.isNotEmpty) return inList.first;
    final detail = _dreamDetails[id];
    if (detail != null) return detail;
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
