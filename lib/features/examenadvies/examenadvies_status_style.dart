import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'examenadvies_data.dart';

/// Bestaand Examenadvies-kleurmodel voor Home + detail.
///
/// Grijs (`textHint`) alleen bij echte empty/unknown: `onvoldoendeData`.
/// Een geldige lage score (`nogNietKlaar`, bv. 27%) blijft merkbaar
/// via het primaire Klantio-accent (`AppColors.primary`).
Color examenadviesStatusAccent(ExamenadviesStatus status) {
  return switch (status) {
    ExamenadviesStatus.klaarVoorExamen => AppColors.successSolid,
    ExamenadviesStatus.bijnaKlaar => AppColors.warningSolid,
    ExamenadviesStatus.nogOefenen => AppColors.infoSolid,
    ExamenadviesStatus.nogNietKlaar => AppColors.primary,
    ExamenadviesStatus.onvoldoendeData => AppColors.textHint,
  };
}

Color examenadviesStatusAccentVanLabel(String statusLabel) {
  return examenadviesStatusAccent(switch (statusLabel) {
    'Klaar voor examen' => ExamenadviesStatus.klaarVoorExamen,
    'Bijna klaar' => ExamenadviesStatus.bijnaKlaar,
    'Nog oefenen' => ExamenadviesStatus.nogOefenen,
    'Nog niet klaar' => ExamenadviesStatus.nogNietKlaar,
    _ => ExamenadviesStatus.onvoldoendeData,
  });
}

bool examenadviesIsEmptyStatusLabel(String statusLabel) {
  return statusLabel == 'Nog onvoldoende data' || statusLabel.isEmpty;
}
