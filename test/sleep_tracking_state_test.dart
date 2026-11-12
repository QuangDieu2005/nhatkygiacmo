import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../lib/core/constants/app_constants.dart';
import '../lib/features/sleep_tracking/presentation/sleep_tracking_screen.dart';
import '../lib/models/dream_model.dart';
import '../lib/models/sleep_session_model.dart';
import '../lib/models/sleep_statistics_model.dart';
import '../lib/providers/sleep_provider.dart';
import '../lib/repositories/sleep_repository.dart';
import '../lib/services/sleep_tracking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'normal start and stop saves one session and clears pending state',
    () async {
      final storage = FakeSleepSessionStorage();
      final repository = FakeSleepSessionRepository();
      final service = SleepTrackingService.forTesting(storage);
      final provider = SleepProvider(
        repository: repository,
        trackingService: service,
      );
      addTearDown(provider.dispose);
      await provider.init();

      await provider.startTracking();
      final active = provider.activeSession!;
      expect(provider.isTracking, isTrue);

      final completed = await provider.stopTracking();
      expect(completed, isNotNull);
      expect(provider.isTracking, isFalse);
      expect(provider.activeSession, isNull);
      expect(provider.pendingCompletedSession, isNull);
      expect(provider.lastCompletedSession?.toJson(), completed!.toJson());
      expect(repository.sessions[active.id]?.toJson(), completed.toJson());
      expect(
        storage.values.containsKey(AppConstants.prefActiveSession),
        isFalse,
      );
      expect(
        storage.values.containsKey(AppConstants.prefPendingCompletedSession),
        isFalse,
      );
    },
  );

  test(
    'repository save failure retains one snapshot and retry reuses it',
    () async {
      final storage = FakeSleepSessionStorage();
      final repository = FakeSleepSessionRepository()..failNextAdds = 1;
      final service = SleepTrackingService.forTesting(storage);
      final provider = SleepProvider(
        repository: repository,
        trackingService: service,
      );
      addTearDown(provider.dispose);
      await provider.init();
      await provider.startTracking();

      await expectLater(provider.stopTracking(), throwsA(isA<StateError>()));
      final snapshot = provider.pendingCompletedSession!;
      final persisted =
          storage.values[AppConstants.prefPendingCompletedSession]!;
      expect(provider.isTracking, isFalse);
      expect(repository.sessions.containsKey(snapshot.id), isFalse);
      await expectLater(
        provider.startTracking(),
        throwsA(isA<SleepTrackingStartException>()),
      );
      expect(
        storage.values[AppConstants.prefPendingCompletedSession],
        persisted,
      );

      final completed = await provider.stopTracking();
      expect(completed?.toJson(), snapshot.toJson());
      expect(
        repository.sessions.keys.where((id) => id == snapshot.id),
        hasLength(1),
      );
      expect(repository.sessions[snapshot.id]?.toJson(), snapshot.toJson());
    },
  );

  test(
    'repository_saved write failure leaves a retryable snapshot after restart',
    () async {
      final storage = FakeSleepSessionStorage()
        ..failWriteOnAttempt(AppConstants.prefPendingCompletedSession, 2);
      final repository = FakeSleepSessionRepository();
      final service = SleepTrackingService.forTesting(storage);
      final provider = SleepProvider(
        repository: repository,
        trackingService: service,
      );
      addTearDown(provider.dispose);
      await provider.init();
      await provider.startTracking();

      await expectLater(provider.stopTracking(), throwsA(isA<StateError>()));
      final snapshot = provider.pendingCompletedSession!;
      expect(repository.sessions[snapshot.id]?.toJson(), snapshot.toJson());
      expect(service.isPendingCompletedSessionSaved, isFalse);

      final restartedService = SleepTrackingService.forTesting(storage);
      final restartedProvider = SleepProvider(
        repository: repository,
        trackingService: restartedService,
      );
      addTearDown(restartedProvider.dispose);
      await restartedProvider.init();
      expect(restartedProvider.isTracking, isFalse);
      expect(
        restartedProvider.pendingCompletedSession?.toJson(),
        snapshot.toJson(),
      );

      final completed = await restartedProvider.stopTracking();
      expect(completed?.toJson(), snapshot.toJson());
      expect(
        repository.sessions.keys.where((id) => id == snapshot.id),
        hasLength(1),
      );
      expect(restartedService.pendingCompletedSession, isNull);
    },
  );

  test(
    'active-key cleanup failure survives restart as completed, not tracking',
    () async {
      final storage = FakeSleepSessionStorage()
        ..failNextRemove(AppConstants.prefActiveSession);
      final repository = FakeSleepSessionRepository();
      final service = SleepTrackingService.forTesting(storage);
      final provider = SleepProvider(
        repository: repository,
        trackingService: service,
      );
      addTearDown(provider.dispose);
      await provider.init();
      await provider.startTracking();

      await expectLater(provider.stopTracking(), throwsA(isA<StateError>()));
      final snapshot = provider.pendingCompletedSession!;
      expect(service.isPendingCompletedSessionSaved, isTrue);

      final restartedService = SleepTrackingService.forTesting(storage);
      final restartedProvider = SleepProvider(
        repository: repository,
        trackingService: restartedService,
      );
      addTearDown(restartedProvider.dispose);
      await restartedProvider.init();
      expect(restartedProvider.activeSession, isNull);
      expect(restartedProvider.isTracking, isFalse);
      expect(
        restartedProvider.lastCompletedSession?.toJson(),
        snapshot.toJson(),
      );

      // The first injected failure was consumed by stopTracking(). Inject a
      // second cleanup failure here to exercise startTracking's blocked path.
      storage.failNextRemove(AppConstants.prefActiveSession);
      final pendingBeforeStart =
          storage.values[AppConstants.prefPendingCompletedSession];
      await expectLater(
        restartedProvider.startTracking(),
        throwsA(isA<SleepTrackingStartException>()),
      );
      expect(restartedProvider.activeSession, isNull);
      expect(
        restartedProvider.pendingCompletedSession?.toJson(),
        snapshot.toJson(),
      );
      expect(
        storage.values[AppConstants.prefPendingCompletedSession],
        pendingBeforeStart,
      );

      final completed = await restartedProvider.stopTracking();
      expect(completed?.toJson(), snapshot.toJson());
      expect(
        repository.sessions.keys.where((id) => id == snapshot.id),
        hasLength(1),
      );
    },
  );

  test(
    'pending-key cleanup failure is recovered without a duplicate',
    () async {
      final storage = FakeSleepSessionStorage()
        ..failNextRemove(AppConstants.prefPendingCompletedSession);
      final repository = FakeSleepSessionRepository();
      final service = SleepTrackingService.forTesting(storage);
      final provider = SleepProvider(
        repository: repository,
        trackingService: service,
      );
      addTearDown(provider.dispose);
      await provider.init();
      await provider.startTracking();

      await expectLater(provider.stopTracking(), throwsA(isA<StateError>()));
      final snapshot = provider.pendingCompletedSession!;
      expect(
        storage.values.containsKey(AppConstants.prefActiveSession),
        isFalse,
      );
      expect(
        storage.values.containsKey(AppConstants.prefPendingCompletedSession),
        isTrue,
      );

      final restartedService = SleepTrackingService.forTesting(storage);
      final restartedProvider = SleepProvider(
        repository: repository,
        trackingService: restartedService,
      );
      addTearDown(restartedProvider.dispose);
      await restartedProvider.init();
      expect(restartedProvider.isTracking, isFalse);
      expect(
        restartedProvider.pendingCompletedSession?.toJson(),
        snapshot.toJson(),
      );
      expect(
        restartedProvider.lastCompletedSession?.toJson(),
        snapshot.toJson(),
      );

      // The initial pending-key failure occurred during stopTracking(). Fail
      // cleanup once more so this start attempt must remain blocked.
      storage.failNextRemove(AppConstants.prefPendingCompletedSession);
      final pendingBeforeStart =
          storage.values[AppConstants.prefPendingCompletedSession];
      await expectLater(
        restartedProvider.startTracking(),
        throwsA(isA<SleepTrackingStartException>()),
      );
      expect(restartedProvider.activeSession, isNull);
      expect(
        restartedProvider.pendingCompletedSession?.toJson(),
        snapshot.toJson(),
      );
      expect(
        storage.values[AppConstants.prefPendingCompletedSession],
        pendingBeforeStart,
      );

      await restartedProvider.stopTracking();
      expect(
        repository.sessions.keys.where((id) => id == snapshot.id),
        hasLength(1),
      );
      expect(repository.sessions[snapshot.id]?.toJson(), snapshot.toJson());
      expect(restartedService.pendingCompletedSession, isNull);
    },
  );

  testWidgets('repository recovery failure is pending in UI and retryable', (
    tester,
  ) async {
    final storage = FakeSleepSessionStorage();
    final repository = FakeSleepSessionRepository();
    final service = SleepTrackingService.forTesting(storage);
    await service.startSleepTracking();
    final snapshot = (await service.prepareCompletedSession())!;
    await repository.addSession(snapshot);
    await service.markPendingCompletedSessionSaved();

    repository.failAllAdds = true;
    final provider = SleepProvider(
      repository: repository,
      trackingService: service,
    );
    addTearDown(provider.dispose);
    await provider.init();
    expect(provider.activeSession, isNull);
    expect(provider.isTracking, isFalse);
    expect(provider.pendingCompletedSession?.toJson(), snapshot.toJson());
    expect(provider.pendingRepositoryRecoveryFailed, isTrue);
    await expectLater(
      provider.startTracking(),
      throwsA(isA<SleepTrackingStartException>()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: const SleepTrackingScreen(),
        ),
      ),
    );
    expect(find.text('Phiên ngủ đang chờ khôi phục'), findsOneWidget);
    expect(find.text('Đang theo dõi'), findsNothing);

    repository.failAllAdds = false;
    final retryButton = find.text('Thử khôi phục phiên');
    await tester.ensureVisible(retryButton);
    await tester.pumpAndSettle();
    await tester.tap(retryButton);
    await tester.pumpAndSettle();
    expect(provider.pendingCompletedSession, isNull);
    expect(provider.pendingRepositoryRecoveryFailed, isFalse);
    expect(provider.activeSession, isNull);
    expect(provider.lastCompletedSession?.toJson(), snapshot.toJson());
    expect(service.pendingCompletedSession, isNull);
    final matchingSessions = repository.sessions.values.where(
      (item) => item.id == snapshot.id,
    );
    expect(matchingSessions, hasLength(1));
    expect(matchingSessions.single.toJson(), snapshot.toJson());
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'active write failure does not create provider or service active state',
    () async {
      final storage = FakeSleepSessionStorage()
        ..failNextWrite(AppConstants.prefActiveSession);
      final service = SleepTrackingService.forTesting(storage);
      final provider = SleepProvider(
        repository: FakeSleepSessionRepository(),
        trackingService: service,
      );
      addTearDown(provider.dispose);
      await provider.init();

      await expectLater(provider.startTracking(), throwsA(isA<StateError>()));
      expect(provider.activeSession, isNull);
      expect(provider.isTracking, isFalse);
      expect(service.activeSession, isNull);
      expect(
        storage.values.containsKey(AppConstants.prefActiveSession),
        isFalse,
      );

      await provider.startTracking();
      expect(provider.isTracking, isTrue);
    },
  );

  test(
    'concurrent start and stop calls do not create duplicate sessions',
    () async {
      final repository = FakeSleepSessionRepository();
      final service = SleepTrackingService.forTesting(
        FakeSleepSessionStorage(),
      );
      final provider = SleepProvider(
        repository: repository,
        trackingService: service,
      );
      addTearDown(provider.dispose);
      await provider.init();

      final firstStart = provider.startTracking();
      await expectLater(
        provider.startTracking(),
        throwsA(isA<SleepTrackingStartException>()),
      );
      await firstStart;
      final active = provider.activeSession!;

      final firstStop = provider.stopTracking();
      expect(await provider.stopTracking(), isNull);
      final completed = await firstStop;
      expect(completed?.id, active.id);
      expect(
        repository.sessions.keys.where((id) => id == active.id),
        hasLength(1),
      );
    },
  );

  test('concrete repository upserts the exact snapshot by ID', () async {
    final repository = SleepRepository.forTesting();
    final id = 'sleep-upsert-${DateTime.now().microsecondsSinceEpoch}';
    final first = SleepSessionModel(
      id: id,
      userId: 'test-user',
      startTime: DateTime(2026, 11, 12, 22),
      endTime: DateTime(2026, 11, 13, 6),
      durationMinutes: 480,
      qualityScore: 90,
      deepSleepMinutes: 120,
      lightSleepMinutes: 260,
      remSleepMinutes: 100,
      createdAt: DateTime(2026, 11, 12, 22),
    );
    final retrySnapshot = first.copyWith(
      endTime: DateTime(2026, 11, 13, 6, 5),
      durationMinutes: 485,
      qualityScore: 92,
    );

    await repository.addSession(first);
    await repository.addSession(retrySnapshot);
    final sessions = await repository.getAllSessions();
    final matches = sessions.where((session) => session.id == id).toList();
    expect(matches, hasLength(1));
    expect(matches.single.toJson(), retrySnapshot.toJson());
  });
}

class FakeSleepSessionStorage implements SleepSessionStorage {
  final Map<String, String> values = {};
  final Map<String, int> _writeAttempts = {};
  final Map<String, int> _removeFailures = {};
  final Map<String, int> _writeFailures = {};

  void failWriteOnAttempt(String key, int attempt) {
    _writeFailures[key] = attempt;
  }

  void failNextWrite(String key) {
    final current = _writeAttempts[key] ?? 0;
    _writeFailures[key] = current + 1;
  }

  void failNextRemove(String key) {
    _removeFailures[key] = (_removeFailures[key] ?? 0) + 1;
  }

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<bool> remove(String key) async {
    final failures = _removeFailures[key] ?? 0;
    if (failures > 0) {
      _removeFailures[key] = failures - 1;
      return false;
    }
    return values.remove(key) != null;
  }

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<bool> writeString(String key, String value) async {
    final attempt = (_writeAttempts[key] ?? 0) + 1;
    _writeAttempts[key] = attempt;
    if (_writeFailures[key] == attempt) return false;
    values[key] = value;
    return true;
  }
}

class FakeSleepSessionRepository implements SleepSessionRepository {
  final Map<String, SleepSessionModel> sessions = {};
  int failNextAdds = 0;
  bool failAllAdds = false;

  @override
  Future<void> addSession(SleepSessionModel session) async {
    if (failAllAdds || failNextAdds > 0) {
      if (failNextAdds > 0) failNextAdds--;
      throw StateError('Simulated repository write failure.');
    }
    sessions[session.id] = session;
  }

  @override
  Future<List<SleepSessionModel>> getAllSessions() async =>
      List.unmodifiable(sessions.values);

  @override
  Future<SleepStatisticsModel> getStatistics({
    List<DreamModel>? dreams,
  }) async => SleepStatisticsModel.empty();
}
