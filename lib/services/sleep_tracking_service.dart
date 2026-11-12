import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/sleep_session_model.dart';

class SleepTrackingService {
  SleepTrackingService._();
  static final SleepTrackingService instance = SleepTrackingService._();

  SleepSessionModel? _activeSession;

  SleepSessionModel? get activeSession => _activeSession;
  bool get isTracking => _activeSession != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(AppConstants.prefActiveSession);
    if (sessionJson != null) {
      try {
        _activeSession = SleepSessionModel.fromJson(jsonDecode(sessionJson) as Map<String, dynamic>);
      } catch (_) {
        _activeSession = null;
      }
    }
  }

  Future<SleepSessionModel> startSleepTracking({String userId = 'user_01'}) async {
    final session = SleepSessionModel(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      startTime: DateTime.now(),
      isTracking: true,
      createdAt: DateTime.now(),
    );

    _activeSession = session;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefActiveSession, jsonEncode(session.toJson()));

    return session;
  }

  /// Builds a completed snapshot without ending or persisting the active state.
  /// The caller must save it to the repository before calling [clearActiveSession].
  Future<SleepSessionModel?> prepareCompletedSession({String? notes}) async {
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

    return completedSession;
  }

  /// Clears the recoverable active session after its completed snapshot is saved.
  Future<void> clearActiveSession() async {
    if (_activeSession == null) return;
    final prefs = await SharedPreferences.getInstance();
    final removed = await prefs.remove(AppConstants.prefActiveSession);
    if (!removed && prefs.containsKey(AppConstants.prefActiveSession)) {
      throw StateError('Could not clear the persisted active sleep session.');
    }
    _activeSession = null;
  }

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
