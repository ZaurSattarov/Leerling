import 'package:flutter/animation.dart';

/// Eén `AnimationController` drijft de hele splash. Elke fase krijgt hier
/// zijn eigen benoemde `Animation<double>` via een `Interval`, zodat elk
/// onderdeel onafhankelijk getimed en later los te tunen is zonder de
/// widgets aan te raken.
///
/// Concept "Behaald": het merkteken bouwt zichzelf op.
///
/// Tijdlijn (totaal 1.9s):
///   0.00s - 0.55s  WIT LINKSBOVEN:   schuift vanuit zijn eigen hoek naar binnen
///   0.08s - 0.63s  WIT LINKSONDER:   idem, licht verlaat
///   0.16s - 0.71s  WIT RECHTSONDER:  idem -- de basis (instructeur, lessen,
///                                    oefening) komt samen
///   0.34s - 0.94s  ROZE BLOK:        de leerling komt van linksonder op zijn plek
///   0.78s - 1.20s  DOEL:             het witte hoekje klikt diagonaal in het
///                                    roze blok -- het enige speelse moment
///   0.90s - 1.40s  KLANTIO:          wipe-reveal van links naar rechts
///   1.10s - 1.50s  LEERLINGENPORTAAL: rustige fade
///   1.50s - 1.90s  EXIT:             lockup stijgt licht op en vervaagt
///
/// Curves zijn gedempt; alleen het doel-hoekje krijgt een klein veertje.
class SplashPhaseAnimations {
  static const totalDuration = Duration(milliseconds: 1900);

  static const _totalMs = 1900.0;
  static Interval _at(double startMs, double endMs, {Curve curve = _settle}) =>
      Interval(startMs / _totalMs, endMs / _totalMs, curve: curve);

  static const _settle = Curves.easeOutQuint;
  static const _click = Curves.easeOutBack;
  static const _wipe = Curves.easeInOutCubic;
  static const _exit = Curves.easeInCubic;

  static final _markTopLeft = _at(0, 550);
  static final _markBottomLeft = _at(80, 630);
  static final _markBottomRight = _at(160, 710);
  static final _markStudent = _at(340, 940);
  static final _markGoal = _at(780, 1200, curve: _click);
  static final _klantioReveal = _at(900, 1400, curve: _wipe);
  static final _portaalAppear = _at(1100, 1500, curve: Curves.easeOut);
  static final _exitFade = _at(1500, 1900, curve: _exit);

  final AnimationController controller;

  late final Animation<double> markTopLeft =
      CurvedAnimation(parent: controller, curve: _markTopLeft);
  late final Animation<double> markBottomLeft =
      CurvedAnimation(parent: controller, curve: _markBottomLeft);
  late final Animation<double> markBottomRight =
      CurvedAnimation(parent: controller, curve: _markBottomRight);
  late final Animation<double> markStudent =
      CurvedAnimation(parent: controller, curve: _markStudent);

  /// Kan kort boven 1.0 uitschieten (veertje); alleen voor transform
  /// gebruiken, opacity altijd clampen.
  late final Animation<double> markGoal =
      CurvedAnimation(parent: controller, curve: _markGoal);

  /// KLANTIO: 0 = volledig verborgen, 1 = volledig onthuld (wipe).
  late final Animation<double> klantioReveal =
      CurvedAnimation(parent: controller, curve: _klantioReveal);
  late final Animation<double> portaalAppear =
      CurvedAnimation(parent: controller, curve: _portaalAppear);

  /// Uitgang: 0 = splash volledig zichtbaar, 1 = lockup volledig weg.
  late final Animation<double> exitFade =
      CurvedAnimation(parent: controller, curve: _exitFade);

  SplashPhaseAnimations(this.controller);
}
