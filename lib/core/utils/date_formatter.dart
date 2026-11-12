import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('HH:mm - dd/MM/yyyy');
  static final DateFormat _weekdayFormat = DateFormat('EEEE', 'vi');

  static String formatDate(DateTime dateTime) => _dateFormat.format(dateTime);

  static String formatTime(DateTime dateTime) => _timeFormat.format(dateTime);

  static String formatDateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  static String formatWeekday(DateTime dateTime) {
    try {
      return _weekdayFormat.format(dateTime);
    } catch (_) {
      final days = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
      return days[dateTime.weekday - 1];
    }
  }

  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0 && dateTime.day == now.day) {
      return 'Hôm nay ${formatTime(dateTime)}';
    } else if (difference.inDays <= 1 && (now.day - dateTime.day == 1)) {
      return 'Hôm qua ${formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return formatDate(dateTime);
    }
  }

  static String formatDurationMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  static String formatDurationDetailed(Duration duration) {
    final hours = duration.inHours;
    final mins = duration.inMinutes.remainder(60);
    return '$hours giờ $mins phút';
  }
}
