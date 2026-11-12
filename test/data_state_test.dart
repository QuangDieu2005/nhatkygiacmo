import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/features/analytics/presentation/analytics_screen.dart';
import 'package:my_app/features/history/presentation/history_screen.dart';
import 'package:my_app/features/home/presentation/home_screen.dart';
import 'package:my_app/models/dream_model.dart';
import 'package:my_app/models/sleep_session_model.dart';
import 'package:my_app/models/sleep_statistics_model.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/providers/dream_provider.dart';
import 'package:my_app/providers/sleep_provider.dart';
import 'package:my_app/repositories/dream_repository.dart';
import 'package:my_app/repositories/sleep_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home shows loading then successful empty state', (tester) async {
    final dreams = _DreamRepo()..gate = Completer<List<DreamModel>>();
    final sleep = _SleepRepo();
    await _pump(tester, const HomeScreen(), dreams: dreams, sleep: sleep);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    dreams.gate!.complete([]);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
  });

  testWidgets('Home reports source errors and retry calls repositories', (
    tester,
  ) async {
    final dreams = _DreamRepo()..failCount = 1;
    final sleep = _SleepRepo()
      ..sessionFailCount = 1
      ..statsFailCount = 1;
    await _pump(tester, const HomeScreen(), dreams: dreams, sleep: sleep);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_rounded), findsAtLeastNWidgets(2));
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('home-sessions-retry')),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(sleep.sessionReads, 2);
    expect(sleep.statsReads, 2);
    final dreamRetry = find.descendant(
      of: find.byKey(const ValueKey('home-dreams-retry')),
      matching: find.byType(TextButton),
    );
    await tester.ensureVisible(dreamRetry);
    await tester.pumpAndSettle();
    await tester.tap(dreamRetry);
    await tester.pumpAndSettle();
    expect(dreams.reads, 2);
  });

  testWidgets('Analytics reports statistics error and retries', (tester) async {
    final dreams = _DreamRepo()..values = [_sampleDream];
    final sleep = _SleepRepo()
      ..values = [_sampleSession]
      ..statsFailCount = 1;
    final dreamProvider = DreamProvider(repository: dreams);
    await dreamProvider.loadDreams();
    await _pump(
      tester,
      const AnalyticsScreen(),
      dreams: dreams,
      sleep: sleep,
      dreamProvider: dreamProvider,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.show_chart_rounded), findsNothing);
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect(sleep.statsReads, 2);
    expect(find.byIcon(Icons.show_chart_rounded), findsOneWidget);
  });

  testWidgets('Analytics refresh preserves loaded dream emotion data', (
    tester,
  ) async {
    final dreams = _DreamRepo()..values = [_sampleDream];
    final sleep = _SleepRepo()..values = [_sampleSession];
    final dreamProvider = DreamProvider(repository: dreams);
    await dreamProvider.loadDreams();
    await _pump(
      tester,
      const AnalyticsScreen(),
      dreams: dreams,
      sleep: sleep,
      dreamProvider: dreamProvider,
    );
    await tester.pumpAndSettle();
    expect(sleep.lastDreams?.length, 1);
    expect(sleep.lastDreams!.single.emotion, EmotionType.peaceful);
    await tester.drag(find.byType(RefreshIndicator), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(sleep.lastDreams?.length, 1);
    expect(find.byIcon(Icons.favorite_outline_rounded), findsOneWidget);
  });

  testWidgets('History keeps dreams when sleep source fails and retries it', (
    tester,
  ) async {
    final dreams = _DreamRepo()..values = [_sampleDream];
    final sleep = _SleepRepo()..sessionFailCount = 1;
    await _pump(tester, const HistoryScreen(), dreams: dreams, sleep: sleep);
    await tester.pumpAndSettle();
    expect(find.text('Dream marker'), findsOneWidget);
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();
    expect(sleep.sessionReads, 2);
  });

  testWidgets('History keeps sleep rows when dreams source fails', (
    tester,
  ) async {
    final dreams = _DreamRepo()..failCount = 1;
    final sleep = _SleepRepo()..values = [_sampleSession];
    await _pump(tester, const HistoryScreen(), dreams: dreams, sleep: sleep);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    expect(find.textContaining('90m'), findsOneWidget);
    await tester.tap(find.byType(Tab).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required _DreamRepo dreams,
  required _SleepRepo sleep,
  DreamProvider? dreamProvider,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider<DreamProvider>.value(
          value: dreamProvider ?? DreamProvider(repository: dreams),
        ),
        ChangeNotifierProvider(create: (_) => SleepProvider(repository: sleep)),
      ],
      child: MaterialApp(theme: AppTheme.darkTheme, home: screen),
    ),
  );
}

final _sampleDream = DreamModel(
  id: 'dream-test',
  userId: 'user-test',
  title: 'Dream marker',
  content: 'A quiet dream',
  emotion: EmotionType.peaceful,
  dreamDate: DateTime(2026, 11, 13),
  createdAt: DateTime(2026, 11, 13),
);

final _sampleSession = SleepSessionModel(
  id: 'sleep-test',
  userId: 'user-test',
  startTime: DateTime(2026, 11, 12, 22),
  endTime: DateTime(2026, 11, 13, 6),
  durationMinutes: 480,
  qualityScore: 88,
  deepSleepMinutes: 90,
  lightSleepMinutes: 250,
  remSleepMinutes: 100,
  createdAt: DateTime(2026, 11, 12, 22),
);

class _DreamRepo implements DreamDataRepository {
  List<DreamModel> values = [];
  int failCount = 0;
  int reads = 0;
  Completer<List<DreamModel>>? gate;

  @override
  Future<List<DreamModel>> getAllDreams() async {
    reads++;
    if (gate != null) return gate!.future;
    if (failCount > 0) {
      failCount--;
      throw StateError('dream failure');
    }
    return values;
  }

  @override
  Future<DreamModel?> getDreamById(String id) async => null;
  @override
  Future<void> addDream(DreamModel dream) async => values.insert(0, dream);
  @override
  Future<void> updateDream(DreamModel dream) async {}
  @override
  Future<void> deleteDream(String id) async {}
}

class _SleepRepo implements SleepSessionRepository {
  List<SleepSessionModel> values = [];
  int sessionFailCount = 0;
  int statsFailCount = 0;
  int sessionReads = 0;
  int statsReads = 0;
  List<DreamModel>? lastDreams;

  @override
  Future<List<SleepSessionModel>> getAllSessions() async {
    sessionReads++;
    if (sessionFailCount > 0) {
      sessionFailCount--;
      throw StateError('sleep failure');
    }
    return values;
  }

  @override
  Future<void> addSession(SleepSessionModel session) async =>
      values.insert(0, session);
  @override
  Future<SleepStatisticsModel> getStatistics({List<DreamModel>? dreams}) async {
    statsReads++;
    lastDreams = dreams;
    if (statsFailCount > 0) {
      statsFailCount--;
      throw StateError('stats failure');
    }
    final emotions = <EmotionType, int>{};
    for (final dream in dreams ?? const <DreamModel>[]) {
      emotions[dream.emotion] = (emotions[dream.emotion] ?? 0) + 1;
    }
    return SleepStatisticsModel(
      averageSleepHours: 8,
      averageQualityScore: 88,
      totalRecordedDreams: dreams?.length ?? 0,
      currentStreakDays: 1,
      weeklyStats: values
          .map(
            (session) => DailySleepStat(
              date: session.startTime,
              dayLabel: 'T5',
              hours: session.totalMinutes / 60,
              qualityScore: session.qualityScore,
            ),
          )
          .toList(),
      emotionDistribution: emotions,
    );
  }
}
