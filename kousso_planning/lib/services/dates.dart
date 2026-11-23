import 'package:intl/intl.dart';

/// Utilitaires de dates : semaine du lundi au dimanche.
class Dates {
  static DateTime mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static List<DateTime> weekOf(DateTime monday) =>
      List.generate(7, (i) => monday.add(Duration(days: i)));

  static String key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static DateTime parse(String key) => DateFormat('yyyy-MM-dd').parse(key);

  /// « du 23 au 29 novembre »
  static String weekLabel(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    final f = DateFormat('d MMMM', 'fr_FR');
    if (monday.month == sunday.month) {
      return 'du ${monday.day} au ${f.format(sunday)}';
    }
    return 'du ${f.format(monday)} au ${f.format(sunday)}';
  }

  static String dayLong(DateTime d) {
    final s = DateFormat('EEEE d MMMM', 'fr_FR').format(d);
    return s[0].toUpperCase() + s.substring(1);
  }

  static bool isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }
}
