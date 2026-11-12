import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sleep_session_model.dart';
import '../models/sleep_statistics_model.dart';
import '../models/dream_model.dart';
import '../repositories/sleep_repository.dart';
import '../services/sleep_tracking_service.dart';

class SleepProvider extends ChangeNotifier {
  final SleepRepository _repository = SleepRepository.instance;
  final SleepTrackingService _trackingService = SleepTrackingService.instance;

  List<SleepSessionModel> _sessions = [];
  SleepSessionModel? _activeSession;
  SleepSessionModel? _lastCompletedSession;
  SleepStatisticsModel _statistics = SleepStatisticsModel.empty();

  bool _isLoading = false;
  Timer? _elapsedTimer;
  Duration _currentElapsed = Duration.zero;

  List<SleepSessionModel> get sessions => _sessions;
  SleepSessionModel? get activeSession => _activeSession;
  SleepSessionModel? get lastCompletedSession => _lastCompletedSession;
  SleepStatisticsModel get statistics => _statistics;
  bool get isTracking => _activeSession != null;
  bool get isLoading => _isLoading;
  Duration get currentElapsed => _currentElapsed;

  Future<void> init() async {
    await _trackingService.init();
    _activeSession = _trackingService.activeSession;
    if (_activeSession != null) {
      _startElapsedTimer();
    }
    await loadSessions();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    if (_activeSession != null) {
      _currentElapsed = DateTime.now().difference(_activeSession!.startTime);
    }
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeSession != null) {
        _currentElapsed = DateTime.now().difference(_activeSession!.startTime);
        notifyListeners();
      }
    });
  }

  Future<void> loadSessions({List<DreamModel>? dreams}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _repository.getAllSessions();
      _statistics = await _repository.getStatistics(dreams: dreams);
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startTracking({String userId = 'user_01'}) async {
    _lastCompletedSession = null;
    final session = await _trackingService.startSleepTracking(userId: userId);
    _activeSession = session;
    _startElapsedTimer();
    notifyListeners();
  }

  Future<SleepSessionModel?> stopTracking({String? notes, List<DreamModel>? dreams}) async {
    _elapsedTimer?.cancel();
    final completed = await _trackingService.stopSleepTracking(notes: notes);
    _activeSession = null;
    _currentElapsed = Duration.zero;

    if (completed != null) {
      _lastCompletedSession = completed;
      await _repository.addSession(completed);
      _sessions.insert(0, completed);
      _statistics = await _repository.getStatistics(dreams: dreams);
    }

    notifyListeners();
    return completed;
  }

  void clearLastCompletedSession() {
    _lastCompletedSession = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }
}
