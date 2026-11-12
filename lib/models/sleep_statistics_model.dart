import 'dream_model.dart';

class DailySleepStat {
  final DateTime date;
  final String dayLabel; // T2, T3, T4...
  final double hours;
  final int qualityScore;

  const DailySleepStat({
    required this.date,
    required this.dayLabel,
    required this.hours,
    required this.qualityScore,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'day_label': dayLabel,
    'hours': hours,
    'quality_score': qualityScore,
  };

  factory DailySleepStat.fromJson(Map<String, dynamic> json) => DailySleepStat(
    date: DateTime.parse(json['date'] as String),
    dayLabel: json['day_label'] as String,
    hours: (json['hours'] as num).toDouble(),
    qualityScore: (json['quality_score'] as num).toInt(),
  );
}

class SleepStatisticsModel {
  final double averageSleepHours;
  final int averageQualityScore;
  final int totalRecordedDreams;
  final int currentStreakDays;
  final List<DailySleepStat> weeklyStats;
  final Map<EmotionType, int> emotionDistribution;

  const SleepStatisticsModel({
    required this.averageSleepHours,
    required this.averageQualityScore,
    required this.totalRecordedDreams,
    required this.currentStreakDays,
    required this.weeklyStats,
    required this.emotionDistribution,
  });

  factory SleepStatisticsModel.empty() {
    return const SleepStatisticsModel(
      averageSleepHours: 0,
      averageQualityScore: 0,
      totalRecordedDreams: 0,
      currentStreakDays: 0,
      weeklyStats: [],
      emotionDistribution: {},
    );
  }
}
