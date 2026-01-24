import 'package:intl/intl.dart';

class TimePeriod {
  /// Enhanced: Centralized logic for period keys.
  static String makePeriodKey(String logType, DateTime now) {
    switch (logType) {
      case 'daily':
        return _yyyyMmDd(now);
      case 'weekly':
        final w = _isoWeek(now);
        return '${w.year}-W${w.week.toString().padLeft(2, '0')}';
      case 'monthly':
        return _yyyyMm(now);
      case 'quarterly':
        final q = ((now.month - 1) ~/ 3) + 1;
        return '${now.year}-Q$q';
      case 'half_yearly':
        final h = (now.month <= 6) ? 1 : 2;
        return '${now.year}-H$h';
      case 'yearly':
        return '${now.year}';
      default:
        return _yyyyMmDd(now);
    }
  }

  /// Efficiency: Enhanced Log ID generation with sanitization.
  static String makeLogId({
    required String uid,
    required String districtId,
    required String logType,
    required String eventType,
    required String periodKey,
  }) {
    // Optimized sanitization logic
    String clean(String s) => s.trim().replaceAll(RegExp(r'[ /]'), '_');

    return '${clean(uid)}__${clean(districtId)}__${clean(logType)}__${clean(eventType)}__${clean(periodKey)}';
  }

  /// NEW: Helper to format keys into Readable Bengali/English for the UI.
  /// This is "Enhanced" for your Dashboard/History screens.
  static String formatKeyForUI(String logType, String periodKey) {
    try {
      if (logType == 'daily') {
        final date = DateTime.parse(periodKey);
        return DateFormat('dd MMM, yyyy').format(date); // e.g., 14 Jan, 2026
      }
      if (logType == 'monthly') {
        final date = DateFormat('yyyy-MM').parse(periodKey);
        return DateFormat('MMMM, yyyy').format(date); // e.g., January, 2026
      }
    } catch (e) {
      return periodKey; // Fallback to raw key
    }
    return periodKey;
  }

  // --- Private Formatters ---

  static String _yyyyMmDd(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';

  static String _yyyyMm(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}';

  static _IsoWeek _isoWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final day = d.weekday;
    final thursday = d.add(Duration(days: 4 - day));
    final isoYear = thursday.year;

    final jan4 = DateTime(isoYear, 1, 4);
    final week1Monday = jan4.subtract(Duration(days: jan4.weekday - 1));

    final diffDays = thursday.difference(week1Monday).inDays;
    final week = (diffDays ~/ 7) + 1;

    return _IsoWeek(year: isoYear, week: week);
  }
}

class _IsoWeek {
  final int year;
  final int week;
  const _IsoWeek({required this.year, required this.week});
}