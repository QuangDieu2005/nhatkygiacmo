import 'api_contract.dart';

class SleepSessionModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final int qualityScore; // 0 - 100
  final int deepSleepMinutes;
  final int lightSleepMinutes;
  final int remSleepMinutes;
  final String? notes;
  final bool isTracking;
  final DateTime createdAt;

  const SleepSessionModel({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.qualityScore = 75,
    this.deepSleepMinutes = 0,
    this.lightSleepMinutes = 0,
    this.remSleepMinutes = 0,
    this.notes,
    this.isTracking = false,
    required this.createdAt,
  });

  Duration get calculatedDuration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  int get totalMinutes {
    if (durationMinutes != null && durationMinutes! > 0) {
      return durationMinutes!;
    }
    return calculatedDuration.inMinutes;
  }

  SleepSessionModel copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    int? qualityScore,
    int? deepSleepMinutes,
    int? lightSleepMinutes,
    int? remSleepMinutes,
    String? notes,
    bool? isTracking,
    DateTime? createdAt,
  }) {
    return SleepSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      qualityScore: qualityScore ?? this.qualityScore,
      deepSleepMinutes: deepSleepMinutes ?? this.deepSleepMinutes,
      lightSleepMinutes: lightSleepMinutes ?? this.lightSleepMinutes,
      remSleepMinutes: remSleepMinutes ?? this.remSleepMinutes,
      notes: notes ?? this.notes,
      isTracking: isTracking ?? this.isTracking,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': totalMinutes,
      'quality_score': qualityScore,
      'deep_sleep_minutes': deepSleepMinutes,
      'light_sleep_minutes': lightSleepMinutes,
      'rem_sleep_minutes': remSleepMinutes,
      'notes': notes,
      'is_tracking': isTracking,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Completed-record API write fields only; local tracking metadata stays local.
  Map<String, dynamic> toApiWriteJson() {
    final end = endTime;
    if (end == null || isTracking) {
      throw StateError('Only completed sleep sessions can be sent to the API.');
    }
    final duration = end.toUtc().difference(startTime.toUtc());
    if (duration <= Duration.zero || duration > const Duration(hours: 24)) {
      throw StateError(
        'Sleep session timestamps are outside the allowed range.',
      );
    }
    if (qualityScore < 0 || qualityScore > 100) {
      throw StateError('qualityScore must be between 0 and 100.');
    }
    if (deepSleepMinutes < 0 || lightSleepMinutes < 0 || remSleepMinutes < 0) {
      throw StateError('Sleep stage minutes cannot be negative.');
    }
    return {
      'start_time': ApiContract.serializeUtc(startTime),
      'end_time': ApiContract.serializeUtc(end),
      'quality_score': qualityScore,
      'deep_sleep_minutes': deepSleepMinutes,
      'light_sleep_minutes': lightSleepMinutes,
      'rem_sleep_minutes': remSleepMinutes,
      'notes': notes,
    };
  }

  factory SleepSessionModel.fromApiJson(Map<String, dynamic> json) {
    final startTime = ApiContract.requiredZonedTimestamp(json, 'start_time');
    final endTime = ApiContract.requiredZonedTimestamp(json, 'end_time');
    if (!endTime.isAfter(startTime) ||
        endTime.difference(startTime) > const Duration(hours: 24)) {
      throw FormatException('Sleep session timestamp range is invalid.');
    }

    final durationMinutes = ApiContract.requiredInt(json, 'duration_minutes');
    final expectedDurationMinutes =
        endTime.difference(startTime).inMilliseconds ~/ 60000;
    if (durationMinutes != expectedDurationMinutes) {
      throw FormatException('duration_minutes does not match the timestamps.');
    }
    final qualityScore = ApiContract.requiredInt(json, 'quality_score');
    final deepSleepMinutes = ApiContract.requiredInt(
      json,
      'deep_sleep_minutes',
    );
    final lightSleepMinutes = ApiContract.requiredInt(
      json,
      'light_sleep_minutes',
    );
    final remSleepMinutes = ApiContract.requiredInt(json, 'rem_sleep_minutes');
    if (durationMinutes < 0 || durationMinutes > 1440) {
      throw FormatException('Invalid duration_minutes value.');
    }
    if (qualityScore < 0 || qualityScore > 100) {
      throw FormatException('Invalid quality_score value.');
    }
    if (deepSleepMinutes < 0 || lightSleepMinutes < 0 || remSleepMinutes < 0) {
      throw FormatException('Sleep stage minutes cannot be negative.');
    }
    final notes = json['notes'];
    if (notes != null && notes is! String) {
      throw FormatException('Invalid notes field.');
    }

    return SleepSessionModel(
      id: ApiContract.requiredUuid(json, 'id'),
      userId: ApiContract.requiredUuid(json, 'user_id'),
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      qualityScore: qualityScore,
      deepSleepMinutes: deepSleepMinutes,
      lightSleepMinutes: lightSleepMinutes,
      remSleepMinutes: remSleepMinutes,
      notes: notes as String?,
      isTracking: false,
      createdAt: ApiContract.requiredZonedTimestamp(json, 'created_at'),
    );
  }

  factory SleepSessionModel.fromJson(Map<String, dynamic> json) {
    return SleepSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? 'default_user',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      qualityScore: (json['quality_score'] as num?)?.toInt() ?? 75,
      deepSleepMinutes: (json['deep_sleep_minutes'] as num?)?.toInt() ?? 0,
      lightSleepMinutes: (json['light_sleep_minutes'] as num?)?.toInt() ?? 0,
      remSleepMinutes: (json['rem_sleep_minutes'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      isTracking: json['is_tracking'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
