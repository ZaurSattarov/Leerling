import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/utils/contact_uri.dart';

void main() {
  test('bellen gebruikt genormaliseerd telefoonnummer', () {
    expect(
        ContactUri.tel(' +31 6 12 34 56 78 ')?.toString(), 'tel:+31612345678');
  });

  test('whatsapp gebruikt cijfers zonder plus', () {
    expect(ContactUri.whatsapp('+31 6 12 34 56 78')?.toString(),
        'https://wa.me/31612345678');
  });

  test('email gebruikt geldig mailto adres met onderwerp', () {
    expect(
      ContactUri.email(
        'instructeur@example.nl',
        subject: 'Vraag via Klantio Leerlingen-app',
      )?.toString(),
      'mailto:instructeur@example.nl?subject=Vraag+via+Klantio+Leerlingen-app',
    );
  });

  test('ongeldige contactdata levert geen uri op', () {
    expect(ContactUri.tel('123'), isNull);
    expect(ContactUri.whatsapp('abc'), isNull);
    expect(ContactUri.email('geen-email'), isNull);
  });
}
