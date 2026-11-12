import '../models/sleep_session_model.dart';
import '../models/sleep_statistics_model.dart';
import '../models/dream_model.dart';

class SleepRepository {
  SleepRepository._();
  static final SleepRepository instance = SleepRepository._();

  final List<SleepSessionModel> _sessions = [
    SleepSessionModel(
      id: 'session_1',
      userId: 'user_01',
      startTime: DateTime.now().subtract(const Duration(hours: 15)),
      endTime: DateTime.now().subtract(const Duration(hours: 7)),
      durationMinutes: 480, // 8h
      qualityScore: 92,
      deepSleepMinutes: 120,
      lightSleepMinutes: 260,
      remSleepMinutes: 100,
      notes: 'Ngủ rất ngon và thức dậy sảng khoái.',
      createdAt: DateTime.now().subtract(const Duration(hours: 15)),
    ),
    SleepSessionModel(
      id: 'session_2',
      userId: 'user_01',
      startTime: DateTime.now().subtract(const Duration(days: 1, hours: 16)),
      endTime: DateTime.now().subtract(const Duration(days: 1, hours: 8, minutes: 30)),
      durationMinutes: 450, // 7.5h
      qualityScore: 85,
      deepSleepMinutes: 110,
      lightSleepMinutes: 240,
      remSleepMinutes: 100,
      notes: 'Thức dậy một lần giữa đêm uống nước.',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 16)),
    ),
    SleepSessionModel(
      id: 'session_3',
      userId: 'user_01',
      startTime: DateTime.now().subtract(const Duration(days: 2, hours: 14)),
      endTime: DateTime.now().subtract(const Duration(days: 2, hours: 7, minutes: 45)),
      durationMinutes: 375, // 6h15
      qualityScore: 70,
      deepSleepMinutes: 80,
      lightSleepMinutes: 210,
      remSleepMinutes: 85,
      notes: 'Làm việc khuya nên ngủ hơi muộn.',
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 14)),
    ),
    SleepSessionModel(
      id: 'session_4',
      userId: 'user_01',
      startTime: DateTime.now().subtract(const Duration(days: 3, hours: 15)),
      endTime: DateTime.now().subtract(const Duration(days: 3, hours: 7)),
      durationMinutes: 480, // 8h
      qualityScore: 94,
      deepSleepMinutes: 130,
      lightSleepMinutes: 250,
      remSleepMinutes: 100,
      notes: 'Uống trà hoa cúc trước khi ngủ, ngủ sâu giấc.',
      createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 15)),
    ),
    SleepSessionModel(
      id: 'session_5',
      userId: 'user_01',
      startTime: DateTime.now().subtract(const Duration(days: 4, hours: 16)),
      endTime: DateTime.now().subtract(const Duration(days: 4, hours: 8)),
      durationMinutes: 480, // 8h
      qualityScore: 88,
      deepSleepMinutes: 115,
      lightSleepMinutes: 265,
      remSleepMinutes: 100,
      createdAt: DateTime.now().subtract(const Duration(days: 4, hours: 16)),
    ),
    SleepSessionModel(
      id: 'session_6',
      userId: 'user_01',
      startTime: DateTime.now().subtract(const Duration(days: 5, hours: 15)),
      endTime: DateTime.now().subtract(const Duration(days: 5, hours: 8, minutes: 30)),
      durationMinutes: 390, // 6.5h
      qualityScore: 74,
      deepSleepMinutes: 90,
      lightSleepMinutes: 215,
      remSleepMinutes: 85,
      createdAt: DateTime.now().subtract(const Duration(days: 5, hours: 15)),
    ),
    SleepSessionModel(
      id: 'session_7',
      userId: 'user_01',
      startTime: DateTime.now().subtract(const Duration(days: 6, hours: 15)),
      endTime: DateTime.now().subtract(const Duration(days: 6, hours: 7)),
      durationMinutes: 480, // 8h
      qualityScore: 90,
      deepSleepMinutes: 120,
      lightSleepMinutes: 260,
      remSleepMinutes: 100,
      createdAt: DateTime.now().subtract(const Duration(days: 6, hours: 15)),
    ),
  ];

  Future<List<SleepSessionModel>> getAllSessions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_sessions);
  }

  Future<void> addSession(SleepSessionModel session) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _sessions.insert(0, session);
  }

  Future<SleepStatisticsModel> getStatistics({List<DreamModel>? dreams}) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_sessions.isEmpty) {
      return SleepStatisticsModel.empty();
    }

    final totalMinutes = _sessions.fold<int>(0, (sum, s) => sum + s.totalMinutes);
    final avgHours = (totalMinutes / _sessions.length) / 60.0;
    final totalQuality = _sessions.fold<int>(0, (sum, s) => sum + s.qualityScore);
    final avgQuality = (totalQuality / _sessions.length).round();

    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final weekly = _sessions.take(7).toList().reversed.map((s) {
      final weekdayIndex = s.startTime.weekday - 1;
      return DailySleepStat(
        date: s.startTime,
        dayLabel: dayLabels[weekdayIndex % 7],
        hours: (s.totalMinutes / 60.0),
        qualityScore: s.qualityScore,
      );
    }).toList();

    final emotionDist = <EmotionType, int>{};
    if (dreams != null) {
      for (final dream in dreams) {
        emotionDist[dream.emotion] = (emotionDist[dream.emotion] ?? 0) + 1;
      }
    }

    return SleepStatisticsModel(
      averageSleepHours: double.parse(avgHours.toStringAsFixed(1)),
      averageQualityScore: avgQuality,
      totalRecordedDreams: dreams?.length ?? 10,
      currentStreakDays: 5,
      weeklyStats: weekly,
      emotionDistribution: emotionDist,
    );
  }
}
