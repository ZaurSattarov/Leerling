import 'package:flutter/services.dart';

/// Eén gedeelde `TextInputFormatter` voor alle handmatige HH:MM-tijdvelden
/// (Begin/Einde in "Tijdblok toevoegen") -- geen aparte implementatie per
/// veld.
///
/// Gedrag:
/// - Alleen cijfers worden geaccepteerd; de ':' wordt automatisch ingevoegd
///   zodra er 2 geldige uurcijfers staan (bv. "15" -> "15:").
/// - Elk cijfer wordt op zijn positie begrensd zodat een ongeldige HH:MM
///   nooit getypt kan worden (uren 00-23, minuten 00-59) -- bv. een derde
///   cijfer "9" na "2" wordt geweigerd omdat geen enkel geldig uur op "29"
///   uitkomt.
/// - Backspace werkt normaal, ook dwars door de automatisch ingevoegde ':'
///   heen (15:30 -> 15:3 -> 15: -> 15 -> 1 -> ""), zonder dat de ':'
///   meteen weer terugkomt.
class TimeInputFormatter extends TextInputFormatter {
  const TimeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldDigits = _digitsOf(oldValue.text);
    final rawDigits = _digitsOf(newValue.text);
    final isDeletion = newValue.text.length < oldValue.text.length;

    // Backspace die alleen de automatisch ingevoegde ':' wegneemt laat
    // het cijferaantal ongewijzigd t.o.v. vóór de bewerking (er is geen
    // cijfer verdwenen, alleen de ':'). In dat geval onderdrukken we het
    // opnieuw toevoegen van de ':' precies deze ene keer -- anders zou de
    // ':' via de opmaak hieronder meteen terugkomen en zou de gebruiker
    // 'm nooit weg kunnen backspacen. Op de eerstvolgende bewerking (nog
    // een backspace, of verder typen) geldt de normale opmaak weer.
    final colonJuistVerwijderd =
        isDeletion && rawDigits.length == oldDigits.length;

    // Per positie begrenzen op een geldige HH:MM (00-23 : 00-59). Cijfers
    // na een ongeldige waarde worden genegeerd -- typen "stopt" daar
    // simpelweg, er verschijnt nooit een ongeldige tussenstand.
    final constrained = StringBuffer();
    for (final d in rawDigits.split('')) {
      if (constrained.length >= 4) break;
      final pos = constrained.length;
      if (pos == 0 && !'012'.contains(d)) break;
      if (pos == 1 && constrained.toString()[0] == '2' && !'0123'.contains(d)) {
        break;
      }
      if (pos == 2 && !'012345'.contains(d)) break;
      constrained.write(d);
    }
    final digitStr = constrained.toString();

    final formatted = digitStr.length < 2
        ? digitStr
        : (digitStr.length == 2 && colonJuistVerwijderd)
            ? digitStr
            : '${digitStr.substring(0, 2)}:${digitStr.substring(2)}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _digitsOf(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
}
