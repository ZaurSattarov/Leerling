import 'package:flutter/animation.dart';

/// Eén `AnimationController` van ~3s drijft de hele splash. Elke fase krijgt
/// hier zijn eigen benoemde `Animation<double>` via een `Interval`, zodat elk
/// onderdeel (ICON, KLANTIO, LEERLINGENPORTAAL) onafhankelijk getimed en
/// later los te tunen is zonder de widgets aan te raken.
///
/// 1-op-1 dezelfde tijdlijn/curves als de Instructeur-app
/// (rijschool-planner-flutter/lib/features/splash/splash_phase_animations.dart)
/// -- alleen de veldnamen zijn hernoemd naar de Leerlingen-assets.
///
/// Tijdlijn (op een totaal van 3.0s):
///   0.00s - 0.50s  ICON:              fade 0->1, scale 0.92->1.0
///   0.35s - 0.85s  KLANTIO:           fade 0->1, scale 0.97->1.0
///   0.70s - 1.10s  LEERLINGENPORTAAL: fade 0->1
///   1.10s - 3.00s  hold:              volledige compositie blijft rustig
///                  staan
///
/// Curves zijn bewust rustig/gedempt (geen bounce, geen overshoot) -- een
/// premium, ingehouden splash, geen speels effect. Geen eind-animatie: na
/// de intro blijft de compositie gewoon op zijn definitieve positie staan
/// tot de splash sluit en de app normaal verdergaat.
class SplashPhaseAnimations {
  static const totalDuration = Duration(milliseconds: 3000);

  static const _msPerUnit = 3000.0;
  static Interval _at(double startMs, double endMs, {Curve curve = _ease}) =>
      Interval(startMs / _msPerUnit, endMs / _msPerUnit, curve: curve);

  static const _ease = Curves.easeOutCubic;

  static final _lAppear = _at(0, 500);
  static final _klantioAppear = _at(350, 850);
  static final _portaalAppear = _at(700, 1100);

  final AnimationController controller;

  late final Animation<double> lAppear =
      CurvedAnimation(parent: controller, curve: _lAppear);
  late final Animation<double> klantioAppear =
      CurvedAnimation(parent: controller, curve: _klantioAppear);
  late final Animation<double> portaalAppear =
      CurvedAnimation(parent: controller, curve: _portaalAppear);

  SplashPhaseAnimations(this.controller);
}
