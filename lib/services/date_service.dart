import 'package:intl/intl.dart';

class DateService {
  DateService._();

  static int get dayOfYear {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    return now.difference(startOfYear).inDays + 1;
  }

  static int get daysRemainingInYear {
    final now = DateTime.now();
    final endOfYear = DateTime(now.year, 12, 31);
    return endOfYear.difference(now).inDays + 1;
  }

  static int daysLived(DateTime dob) {
    return DateTime.now().difference(dob).inDays;
  }

  static int totalDays(int lifespanYears) {
    return lifespanYears * 365;
  }

  static int daysRemaining(DateTime dob, int lifespanYears) {
    final lived = daysLived(dob);
    final total = totalDays(lifespanYears);
    return (total - lived).clamp(0, total);
  }

  // Goal calendar
  static int goalTotal(DateTime start, DateTime end) {
    return end.difference(start).inDays.clamp(1, 99999);
  }

  static int goalPassed(DateTime start) {
    return DateTime.now().difference(start).inDays.clamp(0, 99999);
  }

  static int goalRemaining(DateTime start, DateTime end) {
    final total = goalTotal(start, end);
    final passed = goalPassed(start);
    return (total - passed).clamp(0, total);
  }

  static double goalProgress(DateTime start, DateTime end) {
    final total = goalTotal(start, end);
    final passed = goalPassed(start);
    return (passed / total).clamp(0.0, 1.0);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd / MM / yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static int get currentYear => DateTime.now().year;

  static bool get isLeapYear {
    final y = DateTime.now().year;
    return (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0);
  }
}
