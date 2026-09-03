import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/arrival/live_aankomst_banner_logic.dart';
import 'package:leerling_app/models/les.dart';

void main() {
  // Les: 14:00, vaste "nu" voor deterministische tijdsberekeningen.
  final lesStart = DateTime(2026, 9, 3, 14, 0);

  group('bepaalLiveAankomstBannerStatus -- venster (10/15/20 min)', () {
    for (final minuten in [10, 15, 20]) {
      test('$minuten min: exact op de open-grens is al "open" (grens zelf '
          'telt als open, niet als "voor venster")', () {
        final nu = lesStart.subtract(Duration(minutes: minuten));
        final status = bepaalLiveAankomstBannerStatus(
          lesStatus: LesStatus.gepland,
          eligible: true,
          visibleFromMinutes: minuten,
          lesStartMoment: lesStart,
          sessieActief: false,
          nu: nu,
        );
        expect(status, LiveAankomstBannerStatus.vensterOpenNietGestart);
      });

      test('$minuten min: 1 minuut vóór de grens is nog "voor venster"', () {
        final nu =
            lesStart.subtract(Duration(minutes: minuten + 1));
        final status = bepaalLiveAankomstBannerStatus(
          lesStatus: LesStatus.gepland,
          eligible: true,
          visibleFromMinutes: minuten,
          lesStartMoment: lesStart,
          sessieActief: false,
          nu: nu,
        );
        expect(status, LiveAankomstBannerStatus.voorVenster);
      });

      test('$minuten min: 1 minuut na de grens blijft "venster open"', () {
        final nu =
            lesStart.subtract(Duration(minutes: minuten - 1));
        final status = bepaalLiveAankomstBannerStatus(
          lesStatus: LesStatus.gepland,
          eligible: true,
          visibleFromMinutes: minuten,
          lesStartMoment: lesStart,
          sessieActief: false,
          nu: nu,
        );
        expect(status, LiveAankomstBannerStatus.vensterOpenNietGestart);
      });
    }
  });

  group('bepaalLiveAankomstBannerStatus -- basisstromen', () {
    test('1. banner zichtbaar vóór het venster', () {
      final status = bepaalLiveAankomstBannerStatus(
        lesStatus: LesStatus.gepland,
        eligible: true,
        visibleFromMinutes: 15,
        lesStartMoment: lesStart,
        sessieActief: false,
        nu: lesStart.subtract(const Duration(hours: 2)),
      );
      expect(status, LiveAankomstBannerStatus.voorVenster);
    });

    test('3. banner zichtbaar vanaf het venster (nog niet gestart)', () {
      final status = bepaalLiveAankomstBannerStatus(
        lesStatus: LesStatus.gepland,
        eligible: true,
        visibleFromMinutes: 15,
        lesStartMoment: lesStart,
        sessieActief: false,
        nu: lesStart.subtract(const Duration(minutes: 5)),
      );
      expect(status, LiveAankomstBannerStatus.vensterOpenNietGestart);
    });

    test('4/5. actieve sessie wint altijd, ongeacht venster/tijd', () {
      final vroegNu = lesStart.subtract(const Duration(hours: 5));
      final status = bepaalLiveAankomstBannerStatus(
        lesStatus: LesStatus.gepland,
        eligible: true,
        visibleFromMinutes: 15,
        lesStartMoment: lesStart,
        sessieActief: true,
        nu: vroegNu,
      );
      expect(status, LiveAankomstBannerStatus.actief);
    });

    test('actieve sessie wint zelfs als les-moment al gepasseerd is', () {
      final status = bepaalLiveAankomstBannerStatus(
        lesStatus: LesStatus.gepland,
        eligible: true,
        visibleFromMinutes: 15,
        lesStartMoment: lesStart,
        sessieActief: true,
        nu: lesStart.add(const Duration(minutes: 5)),
      );
      expect(status, LiveAankomstBannerStatus.actief);
    });
  });

  group('bepaalLiveAankomstBannerStatus -- geen banner', () {
    test('les niet eligible (server: uit/lestype niet toegestaan) -> geen '
        'banner, ook niet vóór lesstart', () {
      final status = bepaalLiveAankomstBannerStatus(
        lesStatus: LesStatus.gepland,
        eligible: false,
        visibleFromMinutes: null,
        lesStartMoment: lesStart,
        sessieActief: false,
        nu: lesStart.subtract(const Duration(hours: 1)),
      );
      expect(status, isNull);
    });

    test('geannuleerde les -> geen banner', () {
      final status = bepaalLiveAankomstBannerStatus(
        lesStatus: LesStatus.geannuleerd,
        eligible: true,
        visibleFromMinutes: 15,
        lesStartMoment: lesStart,
        sessieActief: false,
        nu: lesStart.subtract(const Duration(hours: 1)),
      );
      expect(status, isNull);
    });

    test('afgeronde les -> geen banner', () {
      final status = bepaalLiveAankomstBannerStatus(
        lesStatus: LesStatus.afgerond,
        eligible: true,
        visibleFromMinutes: 15,
        lesStartMoment: lesStart,
        sessieActief: false,
        nu: lesStart.subtract(const Duration(hours: 1)),
      );
      expect(status, isNull);
    });

    test('les al begonnen en geen actieve sessie (nooit gestart of al '
        'gestopt) -> geen banner meer', () {
      final status = bepaalLiveAankomstBannerStatus(
        lesStatus: LesStatus.gepland,
        eligible: true,
        visibleFromMinutes: 15,
        lesStartMoment: lesStart,
        sessieActief: false,
        nu: lesStart.add(const Duration(minutes: 1)),
      );
      expect(status, isNull);
    });

    test('reeds gestopte Live Aankomst binnen het venster (voor lesstart) '
        '-> valt terug op "venster open, niet gestart" (mag opnieuw '
        'starten)', () {
      final status = bepaalLiveAankomstBannerStatus(
        lesStatus: LesStatus.gepland,
        eligible: true,
        visibleFromMinutes: 15,
        lesStartMoment: lesStart,
        sessieActief: false, // sessie is gestopt -> niet meer actief
        nu: lesStart.subtract(const Duration(minutes: 5)),
      );
      expect(status, LiveAankomstBannerStatus.vensterOpenNietGestart);
    });

    test('geen geldig lesmoment -> geen banner (geen crash)', () {
      final status = bepaalLiveAankomstBannerStatus(
        lesStatus: LesStatus.gepland,
        eligible: true,
        visibleFromMinutes: 15,
        lesStartMoment: null,
        sessieActief: false,
      );
      expect(status, isNull);
    });

    test('eligible=true maar visibleFromMinutes ontbreekt (inconsistente '
        'respons) -> geen banner', () {
      final status = bepaalLiveAankomstBannerStatus(
        lesStatus: LesStatus.gepland,
        eligible: true,
        visibleFromMinutes: null,
        lesStartMoment: lesStart,
        sessieActief: false,
        nu: lesStart.subtract(const Duration(hours: 1)),
      );
      expect(status, isNull);
    });
  });

  group('leesLesStartMoment', () {
    Les lesMet({required String datum, required String starttijd}) => Les(
          id: 'l1',
          instructeurId: 'i1',
          leerlingId: 'll1',
          datum: datum,
          starttijd: starttijd,
          eindtijd: '15:00',
          duurMinuten: 60,
          status: LesStatus.gepland,
          aangemaaktOp: '',
          bijgewerktOp: '',
        );

    test('combineert datum + starttijd correct tot lokale DateTime', () {
      final result =
          leesLesStartMoment(lesMet(datum: '2026-09-03', starttijd: '14:00'));
      expect(result, DateTime(2026, 9, 3, 14, 0));
    });

    test('lege datum -> null, geen crash', () {
      expect(leesLesStartMoment(lesMet(datum: '', starttijd: '14:00')), isNull);
    });

    test('lege starttijd -> null, geen crash', () {
      expect(leesLesStartMoment(lesMet(datum: '2026-09-03', starttijd: '')),
          isNull);
    });

    test('ongeldige datum -> null, geen crash', () {
      expect(
        leesLesStartMoment(lesMet(datum: 'niet-een-datum', starttijd: '14:00')),
        isNull,
      );
    });
  });
}
