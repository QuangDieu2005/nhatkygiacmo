import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/dream_model.dart';
import 'package:my_app/models/sleep_session_model.dart';

const _id = '550e8400-e29b-41d4-a716-446655440000';
const _userId = '123e4567-e89b-42d3-a456-426614174000';

void main() {
  group('Dream API contract', () {
    test('parses strict UUID response fields', () {
      final dream = DreamModel.fromApiJson(_dreamDto());
      expect(dream.id, _id);
      expect(dream.userId, _userId);
      expect(dream.emotion, EmotionType.peaceful);
    });

    test('rejects malformed UUID and missing required response fields', () {
      expect(
        () => DreamModel.fromApiJson({..._dreamDto(), 'id': '17'}),
        throwsFormatException,
      );
      final incomplete = _dreamDto()..remove('clarity_score');
      expect(() => DreamModel.fromApiJson(incomplete), throwsFormatException);
    });

    test('serializes tags as strings and omits server-owned fields', () {
      final json = _dream().toApiWriteJson();
      expect(json['tags'], ['moon', 'night']);
      expect(
        json.keys,
        containsAll([
          'title',
          'content',
          'emotion',
          'tags',
          'clarity_score',
          'is_lucid',
          'dream_date',
        ]),
      );
      expect(json.keys, isNot(contains('id')));
      expect(json.keys, isNot(contains('user_id')));
      expect(json.keys, isNot(contains('created_at')));
    });

    test('date-only value preserves local calendar date', () {
      final json = _dream(date: DateTime(2025, 3, 10, 23, 45)).toApiWriteJson();
      expect(json['dream_date'], '2025-03-10');
      final parsed = DreamModel.fromApiJson(_dreamDto(dreamDate: '2025-03-10'));
      expect(parsed.dreamDate.year, 2025);
      expect(parsed.dreamDate.month, 3);
      expect(parsed.dreamDate.day, 10);
    });

    test('edit copy preserves id, owner and creation metadata', () {
      final original = _dream();
      final edited = original.copyWith(title: 'Edited');
      expect(edited.id, original.id);
      expect(edited.userId, original.userId);
      expect(edited.createdAt, original.createdAt);
    });
  });

  group('Sleep API contract', () {
    test('parses UTC and explicit UTC offset timestamps to UTC instants', () {
      final utc = SleepSessionModel.fromApiJson(_sleepDto());
      final offset = SleepSessionModel.fromApiJson(
        _sleepDto(
          startTime: '2025-03-10T22:00:00+07:00',
          endTime: '2025-03-11T06:00:00+07:00',
        ),
      );
      expect(utc.startTime.isUtc, isTrue);
      expect(offset.startTime, DateTime.utc(2025, 3, 10, 15));
      expect(offset.endTime, DateTime.utc(2025, 3, 10, 23));
    });

    test('rejects timestamps without an explicit timezone', () {
      expect(
        () => SleepSessionModel.fromApiJson(
          _sleepDto(startTime: '2025-03-10T22:00:00'),
        ),
        throwsFormatException,
      );
    });

    test(
      'API write payload normalizes timestamps and omits local/server fields',
      () {
        final json = _sleep().toApiWriteJson();
        expect(json['start_time'], '2025-03-10T15:00:00.000Z');
        expect(json['end_time'], '2025-03-10T23:00:00.000Z');
        expect(json.keys, isNot(contains('id')));
        expect(json.keys, isNot(contains('user_id')));
        expect(json.keys, isNot(contains('created_at')));
        expect(json.keys, isNot(contains('duration_minutes')));
        expect(json.keys, isNot(contains('is_tracking')));
        expect(json.keys, isNot(contains('isTracking')));
      },
    );

    test('local snapshot serialization remains unchanged', () {
      final local = _sleep(isTracking: true, endTime: null).toJson();
      expect(local['id'], 'local-session-id');
      expect(local['duration_minutes'], isA<int>());
      expect(local['is_tracking'], isTrue);
      expect(SleepSessionModel.fromJson(local).isTracking, isTrue);
    });

    test('strict parser rejects invalid required numeric fields', () {
      expect(
        () => SleepSessionModel.fromApiJson({
          ..._sleepDto(),
          'quality_score': '80',
        }),
        throwsFormatException,
      );
      expect(
        () => SleepSessionModel.fromApiJson({
          ..._sleepDto(),
          'duration_minutes': 479,
        }),
        throwsFormatException,
      );
    });
  });
}

DreamModel _dream({DateTime? date}) => DreamModel(
  id: _id,
  userId: _userId,
  title: 'A quiet dream',
  content: 'A walk under the moon.',
  emotion: EmotionType.peaceful,
  tags: const ['moon', 'night'],
  clarityScore: 4,
  isLucid: false,
  dreamDate: date ?? DateTime(2025, 3, 10),
  createdAt: DateTime.utc(2025, 3, 10, 8),
);

Map<String, dynamic> _dreamDto({String dreamDate = '2025-03-10'}) => {
  'id': _id,
  'user_id': _userId,
  'title': 'A quiet dream',
  'content': 'A walk under the moon.',
  'emotion': 'peaceful',
  'tags': ['moon', 'night'],
  'clarity_score': 4,
  'is_lucid': false,
  'dream_date': dreamDate,
  'created_at': '2025-03-10T08:00:00Z',
};

SleepSessionModel _sleep({bool isTracking = false, DateTime? endTime}) =>
    SleepSessionModel(
      id: 'local-session-id',
      userId: _userId,
      startTime: DateTime.utc(2025, 3, 10, 15),
      endTime: isTracking ? null : endTime ?? DateTime.utc(2025, 3, 10, 23),
      durationMinutes: 480,
      qualityScore: 88,
      deepSleepMinutes: 120,
      lightSleepMinutes: 260,
      remSleepMinutes: 100,
      notes: 'Rested',
      isTracking: isTracking,
      createdAt: DateTime.utc(2025, 3, 10, 15),
    );

Map<String, dynamic> _sleepDto({
  String startTime = '2025-03-10T15:00:00Z',
  String endTime = '2025-03-10T23:00:00Z',
}) => {
  'id': _id,
  'user_id': _userId,
  'start_time': startTime,
  'end_time': endTime,
  'duration_minutes': 480,
  'quality_score': 88,
  'deep_sleep_minutes': 120,
  'light_sleep_minutes': 260,
  'rem_sleep_minutes': 100,
  'notes': 'Rested',
  'created_at': '2025-03-10T15:00:00Z',
};
