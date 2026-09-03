import 'examenadvies_data.dart';

/// UI-selectie bovenop de canonical RPC-reeks. Geen nieuwe trendformule:
/// richting = bestaande `CategorieScore.trend`, punten = `geschiedenis`.
class ExamenadviesSparklineData {
  final List<double> punten;
  final VaardigheidTrend trend;
  final String categorie;

  const ExamenadviesSparklineData({
    required this.punten,
    required this.trend,
    required this.categorie,
  });

  bool get heeftChart => punten.length >= 2;
}

/// Zelfde drempel als SQL: minder dan 2 lespunten → geen trend/chart.
const int minPuntenVoorOntwikkelingChart = 2;

/// Kiest de eerste categorie die de Ontwikkeling-tekst al noemt
/// (verbeterd/gedaald), anders de eerste met een bekende trend.
/// Combineert nooit categorieën tot een gemiddelde lijn.
ExamenadviesSparklineData? bouwOntwikkelingSparkline(ExamenadviesData advies) {
  final kandidaten = advies.categorieen
      .where((c) => c.geschiedenis.length >= minPuntenVoorOntwikkelingChart)
      .toList();
  if (kandidaten.isEmpty) return null;

  final gewenst = _richtingUitTekst(advies.ontwikkeling);
  final gericht = gewenst == null
      ? kandidaten
      : kandidaten.where((c) => c.trend == gewenst).toList();
  final gekozen = gericht.isNotEmpty ? gericht.first : kandidaten.first;

  return ExamenadviesSparklineData(
    punten: gekozen.geschiedenis.length > 6
        ? gekozen.geschiedenis.sublist(gekozen.geschiedenis.length - 6)
        : gekozen.geschiedenis,
    trend: gekozen.trend,
    categorie: gekozen.naam,
  );
}

VaardigheidTrend? _richtingUitTekst(String ontwikkeling) {
  final tekst = ontwikkeling.toLowerCase();
  if (tekst.contains('verbeterd')) return VaardigheidTrend.stijgt;
  if (tekst.contains('gedaald')) return VaardigheidTrend.daalt;
  return null;
}
