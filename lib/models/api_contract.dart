class ApiContract {
  ApiContract._();

  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final RegExp _dateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp _zonedTimestamp = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-](?:(?:0\d|1[0-3]):[0-5]\d|14:00))$',
    caseSensitive: false,
  );

  static String requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Invalid or missing "$key" field.');
    }
    return value;
  }

  static String requiredUuid(Map<String, dynamic> json, String key) {
    final value = requiredString(json, key);
    if (!_uuid.hasMatch(value)) {
      throw FormatException('Invalid UUID in "$key" field.');
    }
    return value;
  }

  static int requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int)
      throw FormatException('Invalid or missing "$key" field.');
    return value;
  }

  static bool requiredBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! bool)
      throw FormatException('Invalid or missing "$key" field.');
    return value;
  }

  static List<String> requiredStringList(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('Invalid or missing "$key" field.');
    }
    return List<String>.unmodifiable(value.cast<String>());
  }

  static DateTime requiredDateOnly(Map<String, dynamic> json, String key) {
    final value = requiredString(json, key);
    if (!_dateOnly.hasMatch(value)) {
      throw FormatException('Invalid date-only value in "$key" field.');
    }
    final parts = value.split('-').map(int.parse).toList();
    final parsed = DateTime(parts[0], parts[1], parts[2]);
    if (parsed.year != parts[0] ||
        parsed.month != parts[1] ||
        parsed.day != parts[2]) {
      throw FormatException('Invalid calendar date in "$key" field.');
    }
    return parsed;
  }

  static DateTime requiredZonedTimestamp(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = requiredString(json, key);
    if (!_zonedTimestamp.hasMatch(value)) {
      throw FormatException('Timestamp "$key" must include Z or UTC offset.');
    }
    try {
      return DateTime.parse(value).toUtc();
    } on FormatException {
      throw FormatException('Invalid timestamp in "$key" field.');
    }
  }

  static String serializeDateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static String serializeUtc(DateTime value) => value.toUtc().toIso8601String();
}
