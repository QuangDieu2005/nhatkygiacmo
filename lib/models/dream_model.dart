import 'package:flutter/material.dart';

enum EmotionType {
  happy,
  peaceful,
  excited,
  sad,
  scared,
  confused,
  neutral,
}

extension EmotionTypeExtension on EmotionType {
  String get label {
    switch (this) {
      case EmotionType.happy:
        return 'Vui vẻ';
      case EmotionType.peaceful:
        return 'Bình yên';
      case EmotionType.excited:
        return 'Hào hứng';
      case EmotionType.sad:
        return 'Buồn bã';
      case EmotionType.scared:
        return 'Sợ hãi';
      case EmotionType.confused:
        return 'Kỳ lạ';
      case EmotionType.neutral:
        return 'Bình thường';
    }
  }

  String get emoji {
    switch (this) {
      case EmotionType.happy:
        return '😊';
      case EmotionType.peaceful:
        return '😌';
      case EmotionType.excited:
        return '✨';
      case EmotionType.sad:
        return '🌧️';
      case EmotionType.scared:
        return '😨';
      case EmotionType.confused:
        return '🌀';
      case EmotionType.neutral:
        return '🌙';
    }
  }

  Color get color {
    switch (this) {
      case EmotionType.happy:
        return const Color(0xFFFFD166);
      case EmotionType.peaceful:
        return const Color(0xFF06D6A0);
      case EmotionType.excited:
        return const Color(0xFF8B5CF6);
      case EmotionType.sad:
        return const Color(0xFF3B82F6);
      case EmotionType.scared:
        return const Color(0xFFEF4444);
      case EmotionType.confused:
        return const Color(0xFFEC4899);
      case EmotionType.neutral:
        return const Color(0xFF94A3B8);
    }
  }
}

class DreamModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final EmotionType emotion;
  final List<String> tags;
  final int clarityScore; // 1-5 độ rõ nét
  final bool isLucid; // Giấc mơ sáng suốt
  final DateTime dreamDate;
  final DateTime createdAt;

  const DreamModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.emotion,
    this.tags = const [],
    this.clarityScore = 3,
    this.isLucid = false,
    required this.dreamDate,
    required this.createdAt,
  });

  DreamModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    EmotionType? emotion,
    List<String>? tags,
    int? clarityScore,
    bool? isLucid,
    DateTime? dreamDate,
    DateTime? createdAt,
  }) {
    return DreamModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      emotion: emotion ?? this.emotion,
      tags: tags ?? this.tags,
      clarityScore: clarityScore ?? this.clarityScore,
      isLucid: isLucid ?? this.isLucid,
      dreamDate: dreamDate ?? this.dreamDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'emotion': emotion.name,
      'tags': tags,
      'clarity_score': clarityScore,
      'is_lucid': isLucid,
      'dream_date': dreamDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DreamModel.fromJson(Map<String, dynamic> json) {
    return DreamModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? 'default_user',
      title: json['title'] as String,
      content: json['content'] as String,
      emotion: EmotionType.values.firstWhere(
        (e) => e.name == (json['emotion'] as String?),
        orElse: () => EmotionType.neutral,
      ),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      clarityScore: (json['clarity_score'] as num?)?.toInt() ?? 3,
      isLucid: json['is_lucid'] as bool? ?? false,
      dreamDate: json['dream_date'] != null
          ? DateTime.parse(json['dream_date'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
