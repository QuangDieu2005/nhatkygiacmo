class UserModel {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final int sleepGoalHours;
  final bool notificationsEnabled;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.sleepGoalHours = 8,
    this.notificationsEnabled = true,
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    int? sleepGoalHours,
    bool? notificationsEnabled,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'sleep_goal_hours': sleepGoalHours,
      'notifications_enabled': notificationsEnabled,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      sleepGoalHours: (json['sleep_goal_hours'] as num?)?.toInt() ?? 8,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  factory UserModel.fromAuthJson(
    Map<String, dynamic> json, {
    UserModel? localSettings,
  }) {
    final id = json['id'];
    final email = json['email'];
    if (id is! String || id.isEmpty || email is! String || email.isEmpty) {
      throw const FormatException(
        'Thông tin người dùng xác thực không hợp lệ.',
      );
    }

    final metadataValue = json['user_metadata'];
    final metadata = metadataValue is Map
        ? Map<String, dynamic>.from(metadataValue)
        : const <String, dynamic>{};
    final rootName = json['name'];
    final metadataName = metadata['name'];
    final name = rootName is String && rootName.trim().isNotEmpty
        ? rootName.trim()
        : metadataName is String && metadataName.trim().isNotEmpty
        ? metadataName.trim()
        : email.split('@').first;

    final rootAvatar = json['avatar_url'];
    final metadataAvatar = metadata['avatar_url'];
    final createdAtValue = json['created_at'];
    return UserModel(
      id: id,
      email: email,
      name: name,
      avatarUrl: rootAvatar is String
          ? rootAvatar
          : metadataAvatar is String
          ? metadataAvatar
          : localSettings?.avatarUrl,
      sleepGoalHours: localSettings?.sleepGoalHours ?? 8,
      notificationsEnabled: localSettings?.notificationsEnabled ?? true,
      createdAt: createdAtValue is String
          ? DateTime.parse(createdAtValue)
          : localSettings?.createdAt ?? DateTime.now(),
    );
  }
}
