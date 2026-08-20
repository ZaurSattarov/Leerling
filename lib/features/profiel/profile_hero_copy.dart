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

bool _sameVisibleName(String? a, String? b) {
  final left = a?.trim().toLowerCase() ?? '';
  final right = b?.trim().toLowerCase() ?? '';
  if (left.isEmpty || right.isEmpty) return false;
  return left == right;
}

LearnerProfileHeroCopy buildLearnerProfileHeroCopy({
  required LeerlingProfiel? profiel,
  required Instructeur? instructeur,
}) {
  final name = profiel?.volledigeNaam.trim();
  final primary =
      (name != null && name.isNotEmpty) ? name : 'Mijn profiel';

  final school = instructeur?.rijschoolNaam?.trim();
  final instructorName = instructeur?.naam?.trim();
  String? schoolLine;
  if (school != null &&
      school.isNotEmpty &&
      !_sameVisibleName(school, primary)) {
    schoolLine = school;
  } else if (instructorName != null &&
      instructorName.isNotEmpty &&
      !_sameVisibleName(instructorName, primary)) {
    schoolLine = instructorName;
  }

  return LearnerProfileHeroCopy(
    primaryTitle: primary,
    schoolLine: schoolLine,
    statusLabel: profiel?.status.label ?? 'Actief',
    statusTone: learnerHeroBadgeTone(profiel?.status),
  );
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
