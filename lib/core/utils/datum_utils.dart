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

  static const List<String> _dagAfkortingen = [
    'MAA',
    'DIN',
    'WOE',
    'DON',
    'VRI',
    'ZAT',
    'ZON',
  ];

  static const List<String> _maandAfkortingen = [
    'jan',
    'feb',
    'mrt',
    'apr',
    'mei',
    'jun',
    'jul',
    'aug',
    'sep',
    'okt',
    'nov',
    'dec',
  ];

  /// Drieletterige weekdagafkorting (MAA..ZON) voor het compacte datumblok
  /// bij "Volgende les" (Home, Planning, Lesdetails) -- centraal zodat
  /// deze drie schermen nooit uit elkaar kunnen lopen.
  static String dagAfkorting(String dateStr) {
    try {
      return _dagAfkortingen[DateTime.parse(dateStr).weekday - 1];
    } catch (_) {
      return '';
    }
  }

  /// Dagnummer (1-31) als string, voor hetzelfde datumblok.
  static String dagNummer(String dateStr) {
    try {
      return DateTime.parse(dateStr).day.toString();
    } catch (_) {
      return '?';
    }
  }

  /// Drieletterige maandafkorting (jan..dec), voor hetzelfde datumblok.
  static String maandAfkorting(String dateStr) {
    try {
      return _maandAfkortingen[DateTime.parse(dateStr).month - 1];
    } catch (_) {
      return '';
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
