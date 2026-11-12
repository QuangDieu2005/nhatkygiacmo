import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sleep_session_model.dart';
import '../models/sleep_statistics_model.dart';
import '../models/dream_model.dart';
import '../repositories/sleep_repository.dart';
import '../services/sleep_tracking_service.dart';

class SleepTrackingStartException implements Exception {
  const SleepTrackingStartException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SleepProvider extends ChangeNotifier {
  final SleepRepository _repository = SleepRepository.instance;
  final SleepTrackingService _trackingService = SleepTrackingService.instance;

  List<SleepSessionModel> _sessions = [];
  SleepSessionModel? _activeSession;
  SleepSessionModel? _pendingCompletedSession;
  bool _pendingRepositoryRecoveryFailed = false;
  SleepSessionModel? _lastCompletedSession;
  SleepStatisticsModel _statistics = SleepStatisticsModel.empty();

  bool _isLoading = false;
  bool _isStarting = false;
  bool _isStopping = false;
  Timer? _elapsedTimer;
  Duration _currentElapsed = Duration.zero;

  List<SleepSessionModel> get sessions => _sessions;
  SleepSessionModel? get activeSession => _activeSession;
  SleepSessionModel? get pendingCompletedSession => _pendingCompletedSession;
  bool get pendingRepositoryRecoveryFailed => _pendingRepositoryRecoveryFailed;
  bool get isPendingCompletedSessionSaved =>
      _trackingService.isPendingCompletedSessionSaved;
  SleepSessionModel? get lastCompletedSession => _lastCompletedSession;
  SleepStatisticsModel get statistics => _statistics;
  bool get isTracking => _activeSession != null;
  bool get isLoading => _isLoading;
  Duration get currentElapsed => _currentElapsed;

  Future<void> init() async {
    await _trackingService.init();
    final pending = _trackingService.pendingCompletedSession;
    _pendingCompletedSession = pending;
    _activeSession = pending == null ? _trackingService.activeSession : null;
    _pendingRepositoryRecoveryFailed = false;
    if (pending != null && _trackingService.isPendingCompletedSessionSaved) {
      try {
        // Re-apply the confirmed ID as an upsert so repositories that are
        // process-local can rebuild their current history from the durable snapshot.
        await _repository.addSession(pending);
        _lastCompletedSession = pending;
      } catch (_) {
        // Keep it pending, not active: its end time and duration are fixed.
        _pendingRepositoryRecoveryFailed = true;
        _currentElapsed = Duration(minutes: pending.totalMinutes);
      }
    }
    if (pending != null) {
      // A pending snapshot is already ended even when its active backup key
      // remains. Freeze the clock to the original snapshot duration.
      _currentElapsed = Duration(minutes: pending.totalMinutes);
    } else if (_activeSession != null) {
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
    if (_isStarting) {
      throw const SleepTrackingStartException('Đang bắt đầu theo dõi giấc ngủ.');
    }
    if (_isStopping) {
      throw const SleepTrackingStartException('Đang lưu phiên ngủ hiện tại.');
    }

    _isStarting = true;
    try {
      // Refresh persisted state before deciding whether a new session is safe.
      await _trackingService.init();
      final pending = _trackingService.pendingCompletedSession;
      _pendingCompletedSession = pending;
      _pendingRepositoryRecoveryFailed = false;
      _activeSession = pending == null ? _trackingService.activeSession : null;
      if (pending != null) {
        _currentElapsed = Duration(minutes: pending.totalMinutes);
        if (!_trackingService.isPendingCompletedSessionSaved) {
          notifyListeners();
          throw const SleepTrackingStartException(
            'Phiên ngủ trước chưa được lưu. Hãy kết thúc và thử lưu lại phiên đó trước.',
          );
        }

        try {
          // Rehydrate process-local history before deleting its durable snapshot.
          await _repository.addSession(pending);
        } catch (_) {
          _pendingRepositoryRecoveryFailed = true;
          notifyListeners();
          throw const SleepTrackingStartException(
            'Chưa thể khôi phục phiên đã lưu vào lịch sử. Hãy thử lại.',
          );
        }

        // Keep the completed result visible if cleanup or the next start fails.
        _lastCompletedSession = pending;
        try {
          await _trackingService.clearActiveSession();
        } catch (_) {
          notifyListeners();
          throw const SleepTrackingStartException(
            'Phiên trước đã lưu nhưng chưa thể dọn trạng thái cũ. Hãy thử lại.',
          );
        }
        _pendingCompletedSession = null;
        _currentElapsed = Duration.zero;
      } else if (_trackingService.activeSession != null) {
        _activeSession = _trackingService.activeSession;
        _startElapsedTimer();
        notifyListeners();
        throw const SleepTrackingStartException(
          'Đã có phiên ngủ cần được khôi phục trước khi bắt đầu phiên mới.',
        );
      } else if (isTracking) {
        throw const SleepTrackingStartException(
          'Phiên ngủ hiện tại vẫn đang theo dõi.',
        );
      }

      final session = await _trackingService.startSleepTracking(userId: userId);
      _activeSession = session;
      _startElapsedTimer();
      _lastCompletedSession = null;
      _pendingCompletedSession = null;
      _pendingRepositoryRecoveryFailed = false;
      notifyListeners();
    } finally {
      _isStarting = false;
    }
  }

  Future<SleepSessionModel?> stopTracking({String? notes, List<DreamModel>? dreams}) async {
    if (_isStopping || _isStarting ||
        (!isTracking && _pendingCompletedSession == null)) {
      return null;
    }
    _isStopping = true;
    try {
      final completed = await _trackingService.prepareCompletedSession(notes: notes);
      if (completed == null) return null;

      _pendingCompletedSession = completed;
      _activeSession = null;
      _pendingRepositoryRecoveryFailed = false;
      // The snapshot is immutable across retries, so freeze the elapsed display
      // at the same duration represented by that snapshot.
      _elapsedTimer?.cancel();
      _currentElapsed = Duration(minutes: completed.totalMinutes);
      notifyListeners();

      // Keep both provider and persisted active state intact unless saving succeeds.
      try {
        await _repository.addSession(completed);
        await _trackingService.markPendingCompletedSessionSaved();
        await _trackingService.clearActiveSession();
      } catch (_) {
        _pendingRepositoryRecoveryFailed =
            _trackingService.isPendingCompletedSessionSaved;
        notifyListeners();
        rethrow;
      }

      _elapsedTimer?.cancel();
      _activeSession = null;
      _pendingCompletedSession = null;
      _pendingRepositoryRecoveryFailed = false;
      _currentElapsed = Duration.zero;
      _lastCompletedSession = completed;
      _sessions = [
        completed,
        ..._sessions.where((session) => session.id != completed.id),
      ];
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
