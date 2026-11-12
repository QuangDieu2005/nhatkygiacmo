import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/sleep_session_model.dart';

class SleepTrackingService {
  SleepTrackingService._();
  static final SleepTrackingService instance = SleepTrackingService._();

  SleepSessionModel? _activeSession;
  SleepSessionModel? _pendingCompletedSession;
  bool _pendingCompletedSessionSaved = false;
  bool _isStarting = false;

  SleepSessionModel? get activeSession => _activeSession;
  SleepSessionModel? get pendingCompletedSession => _pendingCompletedSession;
  bool get isPendingCompletedSessionSaved => _pendingCompletedSessionSaved;
  bool get isTracking => _activeSession != null || _pendingCompletedSession != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _activeSession = null;
    _pendingCompletedSession = null;
    _pendingCompletedSessionSaved = false;
    final sessionJson = prefs.getString(AppConstants.prefActiveSession);
    if (sessionJson != null) {
      try {
        _activeSession = SleepSessionModel.fromJson(jsonDecode(sessionJson) as Map<String, dynamic>);
      } catch (_) {
        _activeSession = null;
      }
    }

    final pendingJson = prefs.getString(AppConstants.prefPendingCompletedSession);
    if (pendingJson != null) {
      try {
        final decoded = jsonDecode(pendingJson) as Map<String, dynamic>;
        final snapshot = decoded[AppConstants.pendingSleepSnapshotField];
        if (snapshot is Map<String, dynamic>) {
          _pendingCompletedSession = SleepSessionModel.fromJson(snapshot);
          _pendingCompletedSessionSaved =
              decoded[AppConstants.pendingSleepRepositorySavedField] == true;
        } else {
          // Read pending snapshots written before the durable status envelope.
          _pendingCompletedSession = SleepSessionModel.fromJson(decoded);
          _pendingCompletedSessionSaved = false;
        }
      } catch (_) {
        _pendingCompletedSession = null;
        _pendingCompletedSessionSaved = false;
      }
    }
  }

  Future<SleepSessionModel> startSleepTracking({String userId = 'user_01'}) async {
    if (_isStarting) {
      throw StateError('A sleep tracking start is already in progress.');
    }
    if (isTracking) {
      throw StateError('An active or pending sleep session must be resolved first.');
    }

    _isStarting = true;
    try {
      final now = DateTime.now();
      final session = SleepSessionModel(
        id: 'session_${now.millisecondsSinceEpoch}',
        userId: userId,
        startTime: now,
        isTracking: true,
        createdAt: now,
      );

      final prefs = await SharedPreferences.getInstance();
      final persisted = await prefs.setString(
        AppConstants.prefActiveSession,
        jsonEncode(session.toJson()),
      );
      if (!persisted) {
        throw StateError('Could not persist the active sleep session.');
      }

      _activeSession = session;
      return session;
    } finally {
      _isStarting = false;
    }
  }

  /// Builds a completed snapshot without ending or persisting the active state.
  /// The snapshot is persisted and reused until [clearActiveSession] succeeds.
  Future<SleepSessionModel?> prepareCompletedSession({String? notes}) async {
    final prefs = await SharedPreferences.getInstance();

    if (_pendingCompletedSession == null) {
      final savedPending = prefs.getString(AppConstants.prefPendingCompletedSession);
      if (savedPending != null) {
        try {
          final decoded = jsonDecode(savedPending) as Map<String, dynamic>;
          final snapshot = decoded[AppConstants.pendingSleepSnapshotField];
          if (snapshot is Map<String, dynamic>) {
            _pendingCompletedSession = SleepSessionModel.fromJson(snapshot);
            _pendingCompletedSessionSaved =
                decoded[AppConstants.pendingSleepRepositorySavedField] == true;
          } else {
            _pendingCompletedSession = SleepSessionModel.fromJson(decoded);
            _pendingCompletedSessionSaved = false;
          }
        } catch (_) {
          _pendingCompletedSession = null;
          _pendingCompletedSessionSaved = false;
        }
      }
    }

    if (_pendingCompletedSession != null) {
      final pendingJson = _encodePendingSnapshot();
      final persisted = await prefs.setString(
        AppConstants.prefPendingCompletedSession,
        pendingJson,
      );
      if (!persisted) {
        throw StateError('Could not persist the pending completed sleep session.');
      }
      return _pendingCompletedSession;
    }

    if (_activeSession == null) return null;

    final endTime = DateTime.now();
    final duration = endTime.difference(_activeSession!.startTime);
    final durationMinutes = duration.inMinutes;

    // Tính điểm chất lượng dựa trên thời lượng (ngủ 7-9h đạt điểm cao nhất)
    int qualityScore = _calculateQualityScore(durationMinutes);

    final completedSession = _activeSession!.copyWith(
      endTime: endTime,
      durationMinutes: durationMinutes,
      qualityScore: qualityScore,
      notes: notes,
      isTracking: false,
      deepSleepMinutes: (durationMinutes * 0.25).toInt(),
      lightSleepMinutes: (durationMinutes * 0.55).toInt(),
      remSleepMinutes: (durationMinutes * 0.20).toInt(),
    );

    // Keep this exact value in memory before awaiting storage so retries in the
    // same process cannot generate a different endTime or duration.
    _pendingCompletedSession = completedSession;
    final persisted = await prefs.setString(
      AppConstants.prefPendingCompletedSession,
      _encodePendingSnapshot(),
    );
    if (!persisted) {
      throw StateError('Could not persist the pending completed sleep session.');
    }

    return completedSession;
  }

  /// Records that the repository accepted the pending snapshot. This marker
  /// lets startup distinguish a completed session from one that needs retry.
  Future<void> markPendingCompletedSessionSaved() async {
    if (_pendingCompletedSession == null) {
      throw StateError('There is no pending completed sleep session to mark.');
    }
    final prefs = await SharedPreferences.getInstance();
    _pendingCompletedSessionSaved = true;
    final saved = await prefs.setString(
      AppConstants.prefPendingCompletedSession,
      _encodePendingSnapshot(),
    );
    if (!saved) {
      _pendingCompletedSessionSaved = false;
      throw StateError('Could not persist the repository confirmation marker.');
    }
  }

  /// Clears active and pending state only after the repository save succeeds.
  Future<void> clearActiveSession() async {
    if (_activeSession == null && _pendingCompletedSession == null) return;
    if (_pendingCompletedSession != null && !_pendingCompletedSessionSaved) {
      throw StateError('Cannot clear an active session before its snapshot is saved.');
    }
    final prefs = await SharedPreferences.getInstance();
    final activeRemoved = await prefs.remove(AppConstants.prefActiveSession);
    if (!activeRemoved && prefs.containsKey(AppConstants.prefActiveSession)) {
      throw StateError('Could not clear the persisted active sleep session.');
    }
    final pendingRemoved = await prefs.remove(AppConstants.prefPendingCompletedSession);
    if (!pendingRemoved && prefs.containsKey(AppConstants.prefPendingCompletedSession)) {
      throw StateError('Could not clear the pending completed sleep session.');
    }
    _activeSession = null;
    _pendingCompletedSession = null;
    _pendingCompletedSessionSaved = false;
  }

  String _encodePendingSnapshot() => jsonEncode({
        AppConstants.pendingSleepSnapshotField: _pendingCompletedSession!.toJson(),
        AppConstants.pendingSleepRepositorySavedField: _pendingCompletedSessionSaved,
      });

  int _calculateQualityScore(int durationMinutes) {
    final hours = durationMinutes / 60.0;
    if (hours < 3) return 30;
    if (hours < 5) return 55;
    if (hours >= 7 && hours <= 9) return 92;
    if (hours > 6 && hours < 7) return 80;
    if (hours > 9 && hours <= 10) return 82;
    return 65;
  }
}
