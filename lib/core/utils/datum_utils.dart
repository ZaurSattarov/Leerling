import 'package:intl/intl.dart';

class DatumUtils {
  DatumUtils._();

  static String toDateString(DateTime dt) =>
      DateFormat('yyyy-MM-dd').format(dt);

  static String vandaagString() => toDateString(DateTime.now());

  static String korteDatum(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('d MMM', 'nl_NL').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String langeDatum(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('EEEE d MMMM yyyy', 'nl_NL').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  /// "d MMMM yyyy" zonder weekdag -- geschikt voor geboortedatum/startdatum,
  /// waar de weekdag geen betekenisvolle informatie toevoegt (in
  /// tegenstelling tot [langeDatum], gebruikt voor toekomstige/geplande
  /// data zoals lessen).
  static String datumZonderWeekdag(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('d MMMM yyyy', 'nl_NL').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String relatiefDatum(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final today = DateTime.now();
      final diff =
          dt.difference(DateTime(today.year, today.month, today.day)).inDays;
      if (diff == 0) return 'Vandaag';
      if (diff == 1) return 'Morgen';
      if (diff == -1) return 'Gisteren';
      return langeDatum(dateStr);
    } catch (_) {
      return dateStr;
    }
  }

  static String duurLabel(int minuten) {
    if (minuten < 60) return '$minuten min';
    final uren = minuten ~/ 60;
    final rest = minuten % 60;
    return rest == 0 ? '$uren uur' : '$uren uur $rest min';
  }

  static bool isVerlopen(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      return DateTime.parse(dateStr).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  static String kortTijd(String t) => t.length > 5 ? t.substring(0, 5) : t;
}
