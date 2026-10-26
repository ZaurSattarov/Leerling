import '../../models/instructeur.dart';
import '../../models/leerling_profiel.dart';

/// Presentatie voor de Leerling profiel-hero. Geen extra databron.
enum LearnerHeroBadgeTone { success, ink, warning }

class LearnerProfileHeroCopy {
  final String primaryTitle;
  final String? schoolLine;
  final String statusLabel;
  final LearnerHeroBadgeTone statusTone;

  const LearnerProfileHeroCopy({
    required this.primaryTitle,
    required this.schoolLine,
    required this.statusLabel,
    required this.statusTone,
  });
}

LearnerProfileHeroCopy buildLearnerProfileHeroCopy({
  required LeerlingProfiel? profiel,
  required Instructeur? instructeur,
  String? accountEmail,
}) {
  final name = profiel?.volledigeNaam.trim();
  final primary = (name != null && name.isNotEmpty) ? name : 'Mijn profiel';
  final accountLine = leerlingHeaderEmail(
    accountEmail: accountEmail,
    profielEmail: profiel?.email,
    instructeurEmail: instructeur?.email,
  );

  return LearnerProfileHeroCopy(
    primaryTitle: primary,
    schoolLine: accountLine,
    statusLabel: profiel?.status.label ?? 'Actief',
    statusTone: learnerHeroBadgeTone(profiel?.status),
  );
}

/// Tweede regel van de profielkop: het e-mailadres van de ingelogde leerling.
/// Het adres van de instructeur of rijschool hoort hier niet.
String? leerlingHeaderEmail({
  String? accountEmail,
  String? profielEmail,
  String? instructeurEmail,
}) {
  final vreemd = instructeurEmail?.trim().toLowerCase();
  bool vanDeLeerling(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return false;
    if (vreemd != null && vreemd.isNotEmpty && value.toLowerCase() == vreemd) {
      return false;
    }
    return true;
  }

  if (vanDeLeerling(accountEmail)) return accountEmail!.trim();
  if (vanDeLeerling(profielEmail)) return profielEmail!.trim();
  return null;
}

LearnerHeroBadgeTone learnerHeroBadgeTone(LeerlingStatus? status) {
  switch (status) {
    case LeerlingStatus.actief:
    case LeerlingStatus.geslaagd:
    case null:
      return LearnerHeroBadgeTone.success;
    case LeerlingStatus.wachtlijst:
      return LearnerHeroBadgeTone.warning;
    case LeerlingStatus.gestopt:
      return LearnerHeroBadgeTone.ink;
  }
}
