import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/utils/datum_utils.dart';
import 'package:leerling_app/core/utils/lespakket_detail.dart';
import 'package:leerling_app/core/utils/lespakket_voortgang.dart';
import 'package:leerling_app/models/leerling_profiel.dart';
import 'package:leerling_app/models/les.dart';

/// Regressietest voor de canonical bugfix (2026-09-10): pakketvoortgang in
/// de Leerling-app moet 'afgerond' uitsluitend uit `leerlingen.lessen_gevolgd`
/// halen (nooit meer een client-side recount van `lessen`), en 'gepland'
/// moet -- net als de Instructeur-app -- alleen toekomstige PAKKETlessen
/// meetellen.
///
/// Bewezen live casus (Lisa Visser, leerlingen.id=d17968a9-4762-4b5e-b925-
/// 93d28610b005, read-only via `supabase db query --linked` geverifieerd):
///   pakket_lessen (lessenTotaal) = 76
///   lessen_gevolgd              = 58
///   geplande pakketlessen       = 1
///   geplande niet-pakketlessen  = 7  ('rijles', telt niet mee)
///   afgeronde lessen zichtbaar_voor_leerling=true (via student_lessen_view)
///                               = 15 (de OUDE, foutieve client-side telling)
///   afgeronde lessen zichtbaar_voor_leerling=false = 54 (mogen NIET
///     verdwijnen uit de pakketvoortgang)
///
/// Instrecteur/Admin Web tonen voor dit pakket: 58 afgerond / 1 gepland /
/// 17 resterend / 76% -- de Leerling-app moet exact hetzelfde tonen.
void main() {
  final vandaag = DateTime.now();
  final morgen = DatumUtils.toDateString(vandaag.add(const Duration(days: 1)));
  final gisteren =
      DatumUtils.toDateString(vandaag.subtract(const Duration(days: 1)));

  Les maakLes({
    required String id,
    required LesStatus status,
    required String? lesType,
    required String datum,
  }) {
    return Les(
      id: id,
      instructeurId: 'instr-1',
      leerlingId: 'd17968a9-4762-4b5e-b925-93d28610b005',
      datum: datum,
      starttijd: '10:00',
      eindtijd: '11:00',
      duurMinuten: 60,
      status: status,
      aangemaaktOp: '2026-01-01T00:00:00Z',
      bijgewerktOp: '2026-01-01T00:00:00Z',
      lesType: lesType,
      zichtbaarVoorLeerling: true,
    );
  }

  /// Simuleert exact wat `student_lessen_view` teruggeeft aan de Leerling-
  /// app: alleen de 15 zichtbare afgeronde pakketlessen (de 54 onzichtbare
  /// bestaan hier bewust NIET in de lijst -- de view laat ze nooit door),
  /// 1 geplande pakketles en 7 geplande niet-pakketlessen ('rijles').
  List<Les> maakLisaLessenLijst() {
    final lessen = <Les>[
      for (var i = 0; i < 15; i++)
        maakLes(
          id: 'afgerond-zichtbaar-$i',
          status: LesStatus.afgerond,
          // 'Pakketles' is het label dat Les.fromJson() teruggeeft voor
          // les_type='pakketles' (zie Les._lesTypeLabel) -- de testfixture
          // bouwt Les rechtstreeks op, dus hier al de getransformeerde
          // labelwaarde gebruiken i.p.v. de ruwe databasewaarde.
          lesType: 'Pakketles',
          datum: gisteren,
        ),
      maakLes(
        id: 'gepland-pakketles',
        status: LesStatus.gepland,
        lesType: 'Pakketles',
        datum: morgen,
      ),
      for (var i = 0; i < 7; i++)
        maakLes(
          id: 'gepland-rijles-$i',
          status: LesStatus.gepland,
          // les_type='rijles' heeft geen case in _lesTypeLabel -> null,
          // exact zoals Les.fromJson() dat voor deze leerling teruggeeft.
          lesType: null,
          datum: morgen,
        ),
    ];
    return lessen;
  }

  LeerlingProfiel maakLisaProfiel() {
    return const LeerlingProfiel(
      id: 'd17968a9-4762-4b5e-b925-93d28610b005',
      instructeurId: 'instr-1',
      voornaam: 'Lisa',
      achternaam: 'Visser',
      pakket: PakketType.standaard,
      status: LeerlingStatus.actief,
      lessenTotaal: 76,
      lessenGevolgd: 58,
      aangemaaktOp: '2026-01-01T00:00:00Z',
      bijgewerktOp: '2026-01-01T00:00:00Z',
      pakketId: 'pakket-starter',
      pakketNaam: 'Starter',
    );
  }

  group('LespakketVoortgang.fromProfiel — canonical lessen_gevolgd', () {
    test(
        'Lisa Visser: 58 afgerond / 1 gepland / 17 resterend / 76%, ook al '
        'ziet de lessenlijst er maar 15 afgerond + 8 gepland uit', () {
      final resultaat = LespakketVoortgang.fromProfiel(
        profiel: maakLisaProfiel(),
        lessen: maakLisaLessenLijst(),
      );

      expect(resultaat.afgerondeLessen, 58,
          reason: 'afgerond moet uit lessen_gevolgd komen, niet uit de '
              '(door zichtbaar_voor_leerling gefilterde) lessenlijst');
      expect(resultaat.geplandeLessen, 1,
          reason: 'alleen de geplande PAKKETles telt mee, niet de 7 '
              'geplande rijlessen');
      expect(resultaat.nogInTePlannen, 17); // 76 - 58 - 1
      expect(resultaat.percentageLabel, 76); // round(58 / 76 * 100)
      expect(resultaat.gebruiktFallback, isFalse);
    });

    test('54 niet-zichtbare afgeronde lessen verdwijnen niet uit de telling',
        () {
      // Lessenlijst met NUL afgeronde rijen (worst case: de view laat er
      // geen enkele door) -- lessen_gevolgd blijft alsnog leidend.
      final profiel = maakLisaProfiel();
      final resultaat = LespakketVoortgang.fromProfiel(
        profiel: profiel,
        lessen: const [],
      );
      expect(resultaat.afgerondeLessen, 58);
      expect(resultaat.gebruiktFallback, isFalse,
          reason: 'geen "fallback" meer -- lessen_gevolgd is altijd de '
              'canonical bron, niet een noodgreep bij een lege lijst');
    });

    test('geplande niet-pakketlessen (rijles) tellen nooit mee', () {
      final resultaat = LespakketVoortgang.fromProfiel(
        profiel: maakLisaProfiel(),
        lessen: [
          maakLes(
            id: 'gepland-rijles',
            status: LesStatus.gepland,
            lesType: null,
            datum: morgen,
          ),
        ],
      );
      expect(resultaat.geplandeLessen, 0);
    });

    test('verlopen geplande pakketles telt niet mee (zelfde als Instrecteur)',
        () {
      final resultaat = LespakketVoortgang.fromProfiel(
        profiel: maakLisaProfiel(),
        lessen: [
          maakLes(
            id: 'verlopen-gepland',
            status: LesStatus.gepland,
            lesType: 'Pakketles',
            datum: gisteren,
          ),
        ],
      );
      expect(resultaat.geplandeLessen, 0);
    });
  });

  group('LespakketDetail.resolve — canonical lessen_gevolgd', () {
    test('gevolgdeLessen komt uit lessen_gevolgd, niet uit de lessenlijst',
        () {
      final detail = LespakketDetail.resolve(
        profiel: maakLisaProfiel().copyWithSnapshot(),
        lessen: maakLisaLessenLijst(),
      );
      expect(detail.gevolgdeLessen, 58);
      expect(detail.totaalLessen, 76);
      expect(detail.resterendeLessen, 18); // 76 - 58 (zonder gepland-aftrek)
    });
  });
}

/// Test-helper: forceert `heeftPakketSnapshot == true` zodat
/// `LespakketDetail.resolve` de snapshot-tak neemt i.p.v. de
/// catalogusfallback-tak (die hier niet relevant is voor deze test).
extension on LeerlingProfiel {
  LeerlingProfiel copyWithSnapshot() {
    return LeerlingProfiel(
      id: id,
      instructeurId: instructeurId,
      voornaam: voornaam,
      achternaam: achternaam,
      pakket: pakket,
      status: status,
      lessenTotaal: lessenTotaal,
      lessenGevolgd: lessenGevolgd,
      aangemaaktOp: aangemaaktOp,
      bijgewerktOp: bijgewerktOp,
      pakketId: pakketId,
      pakketNaam: pakketNaam,
      saldoEenheid: 'lessen',
      pakketLesduurMinuten: 60,
      pakketSnapshotVastgelegdOp: '2026-01-01T00:00:00Z',
    );
  }
}
