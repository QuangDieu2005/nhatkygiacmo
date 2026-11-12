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
  bool _isStarting = false;
  bool _isStopping = false;
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
    if (_isStarting || _isStopping || isTracking || _trackingService.isTracking) return;
    _isStarting = true;
    _lastCompletedSession = null;
    try {
      final session = await _trackingService.startSleepTracking(userId: userId);
      _activeSession = session;
      _startElapsedTimer();
      notifyListeners();
    } finally {
      _isStarting = false;
    }
  }

  Future<SleepSessionModel?> stopTracking({String? notes, List<DreamModel>? dreams}) async {
    if (_isStopping || _isStarting || !isTracking) return null;
    _isStopping = true;
    try {
      final completed = await _trackingService.prepareCompletedSession(notes: notes);
      if (completed == null) return null;

      // Keep both provider and persisted active state intact unless saving succeeds.
      await _repository.addSession(completed);
      await _trackingService.clearActiveSession();

      _elapsedTimer?.cancel();
      _activeSession = null;
      _currentElapsed = Duration.zero;
      _lastCompletedSession = completed;
      if (!_sessions.any((session) => session.id == completed.id)) {
        _sessions.insert(0, completed);
      }
      try {
        _statistics = await _repository.getStatistics(dreams: dreams);
      } catch (_) {
        // The completed session is already saved; a statistics refresh must not
        // turn a successful save into a failed stop operation.
      }
      notifyListeners();
      return completed;
    } finally {
      _isStopping = false;
    }
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
