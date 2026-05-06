import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../models/notificatie.dart';
import '../../shared/providers/auth_provider.dart';

List<Notificatie> mockNotificaties() {
  final now = DateTime.now();
  String iso(Duration ago) => now.subtract(ago).toIso8601String();

  return [
    Notificatie(
      id: 'mock-les-morgen',
      leerlingId: 'mock',
      instructeurId: 'mock',
      titel: 'Je rijles is morgen om 10:15',
      bericht: 'Zorg dat je tien minuten eerder klaarstaat.',
      omschrijving: 'Zorg dat je tien minuten eerder klaarstaat.',
      type: 'les_reminder',
      gelezen: false,
      aangemaaktOp: iso(const Duration(minutes: 18)),
      targetRoute: '/planning',
    ),
    Notificatie(
      id: 'mock-voorbereiding',
      leerlingId: 'mock',
      instructeurId: 'mock',
      titel: 'Morgen oefen je kijkgedrag en rotondes',
      bericht:
          'Bekijk je voorbereiding en let extra op spiegelen en rustig invoegen.',
      omschrijving:
          'Bekijk je voorbereiding en let extra op spiegelen en rustig invoegen.',
      type: 'voorbereiding',
      gelezen: false,
      aangemaaktOp: iso(const Duration(hours: 2)),
      targetRoute: '/lesvoorbereiding',
    ),
    Notificatie(
      id: 'mock-feedback',
      leerlingId: 'mock',
      instructeurId: 'mock',
      titel: 'Feedback beschikbaar',
      bericht: 'Je instructeur heeft feedback toegevoegd aan je laatste les.',
      omschrijving:
          'Je instructeur heeft feedback toegevoegd aan je laatste les.',
      type: 'feedback',
      gelezen: false,
      aangemaaktOp: iso(const Duration(hours: 5)),
      targetRoute: '/les-logboek',
    ),
    Notificatie(
      id: 'mock-factuur',
      leerlingId: 'mock',
      instructeurId: 'mock',
      titel: 'Er staat nog een factuur open',
      bericht: 'Bekijk je openstaande facturen wanneer het uitkomt.',
      omschrijving: 'Bekijk je openstaande facturen wanneer het uitkomt.',
      type: 'factuur',
      gelezen: true,
      aangemaaktOp: iso(const Duration(days: 1)),
      targetRoute: '/facturen',
    ),
    Notificatie(
      id: 'mock-examenadvies',
      leerlingId: 'mock',
      instructeurId: 'mock',
      titel: 'Je examenadvies is bijgewerkt naar 72%',
      bericht: 'Bekijk welke onderdelen je score hebben veranderd.',
      omschrijving: 'Bekijk welke onderdelen je score hebben veranderd.',
      type: 'examenadvies',
      gelezen: true,
      aangemaaktOp: iso(const Duration(days: 2)),
      targetRoute: '/examenadvies',
    ),
  ];
}

final notificatiesProvider =
    FutureProvider.autoDispose<List<Notificatie>>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return mockNotificaties();
  try {
    final meldingen = await StudentService.getMijnNotificaties(profiel.id);
    debugPrint(
        '[student.notificaties.provider] backend count=${meldingen.length} fallback=${meldingen.isEmpty}');
    return meldingen.isEmpty ? mockNotificaties() : meldingen;
  } catch (e) {
    debugPrint(
        '[student.notificaties.provider] backend fout, mock fallback: $e');
    return mockNotificaties();
  }
});

final ongelezenNotificatiesProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) {
    return mockNotificaties().where((n) => !n.gelezen).length;
  }
  try {
    final aantal =
        await StudentService.getOngelezenNotificatiesAantal(profiel.id);
    return aantal;
  } catch (_) {
    return mockNotificaties().where((n) => !n.gelezen).length;
  }
});
