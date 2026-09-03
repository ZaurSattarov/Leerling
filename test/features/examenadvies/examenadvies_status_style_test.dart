import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/constants/app_colors.dart';
import 'package:leerling_app/features/examenadvies/examenadvies_data.dart';
import 'package:leerling_app/features/examenadvies/examenadvies_status_style.dart';

void main() {
  test('Nog niet klaar gebruikt het primaire accent, geen grijs', () {
    expect(
      examenadviesStatusAccent(ExamenadviesStatus.nogNietKlaar),
      AppColors.primary,
    );
    expect(
      examenadviesStatusAccentVanLabel('Nog niet klaar'),
      AppColors.primary,
    );
    expect(examenadviesIsEmptyStatusLabel('Nog niet klaar'), isFalse);
  });

  test('onvoldoende data blijft de empty/grey state', () {
    expect(
      examenadviesStatusAccent(ExamenadviesStatus.onvoldoendeData),
      AppColors.textHint,
    );
    expect(examenadviesIsEmptyStatusLabel('Nog onvoldoende data'), isTrue);
  });

  test('bestaande statuskleuren blijven semantisch', () {
    expect(
      examenadviesStatusAccent(ExamenadviesStatus.klaarVoorExamen),
      AppColors.successSolid,
    );
    expect(
      examenadviesStatusAccent(ExamenadviesStatus.bijnaKlaar),
      AppColors.warningSolid,
    );
    expect(
      examenadviesStatusAccent(ExamenadviesStatus.nogOefenen),
      AppColors.infoSolid,
    );
  });
}
