import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/app.dart';
import 'package:leerling_app/features/home/home_provider.dart';
import 'package:leerling_app/features/notificaties/notificaties_provider.dart';
import 'package:leerling_app/features/planning/planning_provider.dart';

void main() {
  test('LA-18: bij hervatten worden lessen, home en meldingen opnieuw geladen',
      () async {
    final geladen = <String, int>{};
    int teller(String naam) => geladen[naam] = (geladen[naam] ?? 0) + 1;

    final container = ProviderContainer(overrides: [
      komendeLessenProvider.overrideWith((ref) async {
        teller('komende');
        return [];
      }),
      vorigeLessenProvider.overrideWith((ref) async {
        teller('vorige');
        return [];
      }),
      notificatiesProvider.overrideWith((ref) async {
        teller('meldingen');
        return [];
      }),
      ongelezenNotificatiesProvider.overrideWith((ref) async {
        teller('ongelezen');
        return 0;
      }),
      homeProvider.overrideWith((ref) async {
        teller('home');
        throw UnimplementedError('niet nodig in deze test');
      }),
    ]);
    addTearDown(container.dispose);

    // Houd de (autoDispose) providers in leven, zoals zichtbare schermen doen.
    container.listen(komendeLessenProvider, (_, __) {});
    container.listen(vorigeLessenProvider, (_, __) {});
    container.listen(notificatiesProvider, (_, __) {});
    container.listen(ongelezenNotificatiesProvider, (_, __) {});
    container.listen(homeProvider, (_, __) {}, onError: (_, __) {});
    await Future<void>.delayed(Duration.zero);
    expect(geladen.values.every((n) => n == 1), isTrue);

    verversLeerlingDataBijHervatten(container.invalidate);
    await Future<void>.delayed(Duration.zero);

    expect(geladen, {
      'komende': 2,
      'vorige': 2,
      'meldingen': 2,
      'ongelezen': 2,
      'home': 2,
    });
  });
}
