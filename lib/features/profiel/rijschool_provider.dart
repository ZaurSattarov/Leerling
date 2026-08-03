import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/student_service.dart';
import '../../models/instructeur.dart';
import '../../shared/providers/auth_provider.dart';

/// Gekoppelde instructeur/rijschool van de ingelogde leerling (Fase 6).
/// Voorheen privé binnen profiel_screen.dart -- hierheen verplaatst zodat
/// zowel de "Contact met instructeur"-tegel (Communicatie-sectie) als het
/// nieuwe "Mijn rijschool"-detailscherm dezelfde, enige provider gebruiken
/// i.p.v. een tweede kopie. Query ongewijzigd: StudentService.
/// getMijnInstructeur() via leerlingen.instructeur_id.
final mijnInstructeurProvider =
    FutureProvider.autoDispose<Instructeur?>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return null;
  return StudentService.getMijnInstructeur(profiel.instructeurId);
});
