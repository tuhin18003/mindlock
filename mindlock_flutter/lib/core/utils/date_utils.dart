import 'package:intl/intl.dart';

class MindLockDateUtils {
  MindLockDateUtils._();

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    if (minutes > 0) return '${minutes}m';
    return '< 1m';
  }

  static String formatDurationSeconds(int seconds) {
    return formatDuration(Duration(seconds: seconds));
  }

  static String formatMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (m == 0) return '${h}h';
      return '${h}h ${m}m';
    }
    return '${minutes}m';
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    if (now.difference(date).inDays < 7) return DateFormat('EEEE').format(date);
    return DateFormat('MMM d').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, h:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return startOfDay(date.subtract(Duration(days: weekday - 1)));
  }

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static String toIso8601(DateTime date) => date.toUtc().toIso8601String();

  static DateTime fromIso8601(String iso) => DateTime.parse(iso).toLocal();
}
