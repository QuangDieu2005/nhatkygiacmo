import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/features/dream_diary/presentation/dream_detail_screen.dart';
import 'package:my_app/features/dream_diary/presentation/edit_dream_screen.dart';
import 'package:my_app/models/dream_model.dart';
import 'package:my_app/providers/dream_provider.dart';
import 'package:my_app/repositories/dream_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Detail stays loading until ID query completes', (tester) async {
    final repo = _DreamRepo()..gate = Completer<DreamModel?>();
    await _pump(tester, repo, const DreamDetailScreen(dreamId: 'dream-a'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.gate!.complete(_dream('dream-a', 'Dream A'));
    await tester.pumpAndSettle();
    expect(find.text('Dream A'), findsOneWidget);
    expect(repo.idReads, 1);
  });

  testWidgets('Detail loads and shows a record by ID when list is empty', (
    tester,
  ) async {
    final repo = _DreamRepo()
      ..records['dream-a'] = _dream('dream-a', 'Dream A');
    await _pump(tester, repo, const DreamDetailScreen(dreamId: 'dream-a'));
    await tester.pumpAndSettle();
    expect(find.text('Dream A'), findsOneWidget);
    expect(repo.idReads, 1);
  });

  testWidgets('Detail reports not found only after successful ID lookup', (
    tester,
  ) async {
    final repo = _DreamRepo();
    await _pump(tester, repo, const DreamDetailScreen(dreamId: 'missing'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
    expect(repo.idReads, 1);
  });

  testWidgets('Detail load error can retry the same ID', (tester) async {
    final repo = _DreamRepo()
      ..failCount = 1
      ..records['dream-a'] = _dream('dream-a', 'Dream A');
    await _pump(tester, repo, const DreamDetailScreen(dreamId: 'dream-a'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();
    expect(repo.lastId, 'dream-a');
    expect(repo.idReads, 2);
    expect(find.text('Dream A'), findsOneWidget);
  });

  testWidgets('Edit waits for record load before constructing the form', (
    tester,
  ) async {
    final repo = _DreamRepo()..gate = Completer<DreamModel?>();
    await _pump(tester, repo, const EditDreamScreen(dreamId: 'dream-a'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    repo.gate!.complete(_dream('dream-a', 'Dream A'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(_field(tester, 0).controller!.text, 'Dream A');
  });

  testWidgets('Edit load error can retry and then builds the form', (
    tester,
  ) async {
    final repo = _DreamRepo()
      ..failCount = 1
      ..records['dream-a'] = _dream('dream-a', 'Dream A');
    await _pump(tester, repo, const EditDreamScreen(dreamId: 'dream-a'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();
    expect(repo.idReads, 2);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Edit shows not found after a successful missing lookup', (
    tester,
  ) async {
    final repo = _DreamRepo();
    await _pump(tester, repo, const EditDreamScreen(dreamId: 'missing'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('Edit text survives ordinary Provider rebuilds', (tester) async {
    final repo = _DreamRepo()
      ..records['dream-a'] = _dream('dream-a', 'Dream A');
    final provider = DreamProvider(repository: repo);
    await _pump(
      tester,
      repo,
      const EditDreamScreen(dreamId: 'dream-a'),
      provider: provider,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'User changed title',
    );
    provider.setSearchQuery('refresh rebuild');
    await tester.pump();
    expect(_field(tester, 0).controller!.text, 'User changed title');
    expect(repo.idReads, 1);
  });

  testWidgets('Edit save preserves record ID, user ID and creation timestamp', (
    tester,
  ) async {
    final original = _dream('dream-a', 'Dream A');
    final repo = _DreamRepo()..records[original.id] = original;
    await _pump(tester, repo, EditDreamScreen(dreamId: original.id));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Updated title');
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();
    final saved = repo.updated!;
    expect(saved.id, original.id);
    expect(saved.userId, original.userId);
    expect(saved.createdAt, original.createdAt);
    expect(saved.title, 'Updated title');
  });

  testWidgets(
    'Changing dreamId loads corresponding record, not previous record',
    (tester) async {
      final repo = _DreamRepo()
        ..records['dream-a'] = _dream('dream-a', 'Dream A')
        ..records['dream-b'] = _dream('dream-b', 'Dream B');
      final provider = DreamProvider(repository: repo);
      await _pump(
        tester,
        repo,
        const EditDreamScreen(dreamId: 'dream-a'),
        provider: provider,
      );
      await tester.pumpAndSettle();
      expect(_field(tester, 0).controller!.text, 'Dream A');
      await _pump(
        tester,
        repo,
        const EditDreamScreen(dreamId: 'dream-b'),
        provider: provider,
      );
      await tester.pumpAndSettle();
      expect(_field(tester, 0).controller!.text, 'Dream B');
      expect(repo.idReads, 2);
    },
  );

  testWidgets('Provider rebuild does not repeat a completed ID query', (
    tester,
  ) async {
    final repo = _DreamRepo()
      ..records['dream-a'] = _dream('dream-a', 'Dream A');
    final provider = DreamProvider(repository: repo);
    await _pump(
      tester,
      repo,
      const DreamDetailScreen(dreamId: 'dream-a'),
      provider: provider,
    );
    await tester.pumpAndSettle();
    provider.setSearchQuery('notify');
    await tester.pump();
    expect(repo.idReads, 1);
  });
}

TextFormField _field(WidgetTester tester, int index) =>
    tester.widget<TextFormField>(find.byType(TextFormField).at(index));

Future<void> _pump(
  WidgetTester tester,
  _DreamRepo repo,
  Widget screen, {
  DreamProvider? provider,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<DreamProvider>.value(
      value: provider ?? DreamProvider(repository: repo),
      child: MaterialApp(theme: AppTheme.darkTheme, home: screen),
    ),
  );
}

DreamModel _dream(String id, String title) => DreamModel(
  id: id,
  userId: 'user-owner',
  title: title,
  content: 'A dream description',
  emotion: EmotionType.peaceful,
  tags: const ['moon'],
  clarityScore: 4,
  isLucid: true,
  dreamDate: DateTime(2026, 10, 1),
  createdAt: DateTime(2026, 10, 2, 8),
);

class _DreamRepo implements DreamDataRepository {
  final Map<String, DreamModel> records = {};
  int idReads = 0;
  int failCount = 0;
  String? lastId;
  DreamModel? updated;
  Completer<DreamModel?>? gate;

  @override
  Future<DreamModel?> getDreamById(String id) async {
    idReads++;
    lastId = id;
    if (gate != null) return gate!.future;
    if (failCount > 0) {
      failCount--;
      throw StateError('injected repository failure');
    }
    return records[id];
  }

  @override
  Future<List<DreamModel>> getAllDreams() async => records.values.toList();
  @override
  Future<void> addDream(DreamModel dream) async => records[dream.id] = dream;
  @override
  Future<void> updateDream(DreamModel dream) async {
    updated = dream;
    records[dream.id] = dream;
  }

  @override
  Future<void> deleteDream(String id) async => records.remove(id);
}
