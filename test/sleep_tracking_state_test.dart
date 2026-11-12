import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/models/sleep_session_model.dart';
import '../lib/providers/sleep_provider.dart';
import '../lib/repositories/sleep_repository.dart';
import '../lib/services/sleep_tracking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = SleepTrackingService.instance;
  final repository = SleepRepository.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await service.init();
  });

  test('restores an unsaved completed snapshot as pending, then retries it',
      () async {
    final active = await service.startSleepTracking();
    final snapshot = await service.prepareCompletedSession();
    expect(snapshot, isNotNull);

    final provider = SleepProvider();
    addTearDown(provider.dispose);
    await provider.init();

    expect(provider.isTracking, isFalse);
    expect(provider.activeSession, isNull);
    expect(provider.pendingCompletedSession?.id, snapshot!.id);
    expect(provider.pendingCompletedSession?.startTime, snapshot.startTime);
    expect(provider.pendingCompletedSession?.endTime, snapshot.endTime);
    expect(provider.pendingCompletedSession?.durationMinutes, snapshot.durationMinutes);
    expect(provider.pendingCompletedSession?.qualityScore, snapshot.qualityScore);

    final completed = await provider.stopTracking();
    expect(completed?.id, snapshot.id);
    expect(completed?.startTime, snapshot.startTime);
    expect(completed?.endTime, snapshot.endTime);
    expect(completed?.durationMinutes, snapshot.durationMinutes);
    expect(completed?.qualityScore, snapshot.qualityScore);
    expect(completed?.deepSleepMinutes, snapshot.deepSleepMinutes);
    expect(provider.isTracking, isFalse);
    expect(provider.pendingCompletedSession, isNull);
    expect(provider.lastCompletedSession?.id, snapshot.id);

    final sessions = await repository.getAllSessions();
    final matches = sessions.where((session) => session.id == active.id).toList();
    expect(matches, hasLength(1));
    expect(matches.single.toJson(), completed!.toJson());
  });

  test('restores an active session as tracking, not as a completed snapshot',
      () async {
    final active = await service.startSleepTracking();
    final provider = SleepProvider();
    addTearDown(provider.dispose);
    await provider.init();

    expect(provider.isTracking, isTrue);
    expect(provider.activeSession?.id, active.id);
    expect(provider.pendingCompletedSession, isNull);
    expect(provider.lastCompletedSession, isNull);
  });

  test('saved pending snapshot is rehydrated before a new session starts',
      () async {
    await service.startSleepTracking();
    final snapshot = (await service.prepareCompletedSession())!;
    await repository.addSession(snapshot);
    await service.markPendingCompletedSessionSaved();

    final provider = SleepProvider();
    addTearDown(provider.dispose);
    await provider.init();
    expect(provider.isTracking, isFalse);
    expect(provider.lastCompletedSession?.toJson(), snapshot.toJson());
    expect(provider.pendingCompletedSession?.toJson(), snapshot.toJson());

    provider.clearLastCompletedSession();
    expect(provider.isTracking, isFalse);
    expect(provider.pendingCompletedSession?.toJson(), snapshot.toJson());

    await provider.startTracking();
    expect(provider.isTracking, isTrue);
    expect(provider.activeSession?.id, isNot(snapshot.id));
    expect(provider.lastCompletedSession, isNull);
    expect(provider.pendingCompletedSession, isNull);

    final sessions = await repository.getAllSessions();
    final oldRows = sessions.where((session) => session.id == snapshot.id).toList();
    expect(oldRows, hasLength(1));
    expect(oldRows.single.toJson(), snapshot.toJson());
  });

  test('repository upsert replaces matching ID with the exact retry snapshot',
      () async {
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

  test('concurrent start and stop calls do not create duplicate sessions',
      () async {
    final provider = SleepProvider();
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

    final sessions = await repository.getAllSessions();
    expect(sessions.where((session) => session.id == active.id), hasLength(1));
  });
}
