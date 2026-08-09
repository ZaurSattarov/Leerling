// Unit tests voor TimeInputFormatter -- de ene gedeelde formatter voor
// zowel Begin als Einde in "Tijdblok toevoegen". Simuleert toetsaanslagen
// rechtstreeks op formatEditUpdate, los van enige widget/Supabase.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/utils/tijd_invoer_formatter.dart';

const _formatter = TimeInputFormatter();

/// Simuleert het typen van [toType] karakter voor karakter, uitgaand van
/// de al opgemaakte tekst [current] (zoals een echt TextField dat
/// aanlevert: elke toets levert een newValue met de nieuwe tekst aan het
/// eind van de oude opgemaakte tekst).
String _type(String current, String toType) {
  var text = current;
  for (final ch in toType.split('')) {
    final oldValue =
        TextEditingValue(text: text, selection: _eind(text.length));
    final newValue = TextEditingValue(
      text: text + ch,
      selection: _eind(text.length + 1),
    );
    text = _formatter.formatEditUpdate(oldValue, newValue).text;
  }
  return text;
}

/// Simuleert één backspace-druk aan het eind van [current].
String _backspace(String current) {
  if (current.isEmpty) return current;
  final oldValue =
      TextEditingValue(text: current, selection: _eind(current.length));
  final nieuweTekst = current.substring(0, current.length - 1);
  final newValue =
      TextEditingValue(text: nieuweTekst, selection: _eind(nieuweTekst.length));
  return _formatter.formatEditUpdate(oldValue, newValue).text;
}

TextSelection _eind(int offset) => TextSelection.collapsed(offset: offset);

void main() {
  group('TimeInputFormatter -- automatische ":"', () {
    test('1 cijfer blijft ongewijzigd', () {
      expect(_type('', '1'), '1');
    });

    test('"15" wordt automatisch "15:"', () {
      expect(_type('', '15'), '15:');
    });

    test('"16" wordt automatisch "16:"', () {
      expect(_type('', '16'), '16:');
    });

    test('daarna kunnen minuten worden ingevoerd: 15: -> 15:3 -> 15:30', () {
      var text = _type('', '15');
      expect(text, '15:');
      text = _type(text, '3');
      expect(text, '15:3');
      text = _type(text, '0');
      expect(text, '15:30');
    });

    test('volledige invoer 09:30, 16:45, 18:00 wordt correct opgebouwd', () {
      expect(_type('', '0930'), '09:30');
      expect(_type('', '1645'), '16:45');
      expect(_type('', '1800'), '18:00');
    });
  });

  group('TimeInputFormatter -- backspace/cursor', () {
    test('15:30 -> 15:3 -> 15: -> 15 -> 1 -> leeg, telkens één stap terug',
        () {
      var text = '15:30';
      text = _backspace(text);
      expect(text, '15:3');
      text = _backspace(text);
      expect(text, '15:');
      // Kernpunt: de ':' mag niet meteen terugkomen zodra alleen de ':'
      // zelf is weggehaald -- anders kan de gebruiker nooit verder terug.
      text = _backspace(text);
      expect(text, '15');
      text = _backspace(text);
      expect(text, '1');
      text = _backspace(text);
      expect(text, '');
    });

    test('na het wegbackspacen van de ":" kan weer normaal verder getypt '
        'worden', () {
      final naColonWeg = _backspace('15:');
      expect(naColonWeg, '15');
      expect(_type(naColonWeg, '3'), '15:3');
    });
  });

  group('TimeInputFormatter -- validatie per cijfer', () {
    test('ongeldig eerste uurcijfer (9) wordt geweigerd', () {
      expect(_type('', '9'), '');
    });

    test('"29" kan niet getypt worden -- na een "2" mag het tweede '
        'uurcijfer max 3 zijn', () {
      expect(_type('', '29'), '2');
    });

    test('"99:00" kan niet getypt worden', () {
      expect(_type('', '99'), '');
    });

    test('"12:99" kan niet getypt worden -- minuten max 59', () {
      expect(_type('', '1299'), '12:');
    });

    test('eerste minuutcijfer > 5 wordt geweigerd (bv. 12:8)', () {
      expect(_type('', '128'), '12:');
    });

    test('geldige grenswaarde 23:59 wél toegestaan', () {
      expect(_type('', '2359'), '23:59');
    });

    test('00:00 toegestaan', () {
      expect(_type('', '0000'), '00:00');
    });

    test('nooit meer dan 4 cijfers (5 tekens incl. ":")', () {
      expect(_type('', '235959'), '23:59');
    });
  });
}
