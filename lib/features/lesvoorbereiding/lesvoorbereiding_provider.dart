import 'package:flutter_riverpod/flutter_riverpod.dart';

class LesvoorbereidingData {
  final String focus;
  final String voorbereiding;
  final List<String> tips;
  final List<String> oefenen;
  final String motivatie;

  const LesvoorbereidingData({
    required this.focus,
    required this.voorbereiding,
    required this.tips,
    required this.oefenen,
    required this.motivatie,
  });
}

const _mockLesvoorbereiding = LesvoorbereidingData(
  focus: 'Kijkgedrag en rotondes',
  voorbereiding:
      'Morgen oefen je rotondes. Let extra op spiegelen, richting aangeven en rustig invoegen.',
  tips: [
    'Kijk vroeg naar borden en rijstroken voordat je de rotonde nadert.',
    'Controleer spiegels en dode hoek voordat je uitvoegt.',
    'Geef richting duidelijk en op tijd aan.',
  ],
  oefenen: [
    'Rotondes met meerdere rijstroken',
    'Spiegelgebruik voor en na de rotonde',
    'Rustig invoegen en uitvoegen',
  ],
  motivatie:
      'Je hoeft het niet perfect te doen. Focus op rustig blijven en steeds dezelfde kijkroutine gebruiken.',
);

final lesvoorbereidingProvider = Provider<LesvoorbereidingData>((ref) {
  return _mockLesvoorbereiding;
});
