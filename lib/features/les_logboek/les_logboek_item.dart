class LesLogboekItem {
  final String id;
  final String datumLabel;
  final String tijdLabel;
  final String instructeur;
  final List<String> onderwerpen;
  final String feedback;
  final String beoordeling;
  final String? leerlingNotitie;

  const LesLogboekItem({
    required this.id,
    required this.datumLabel,
    required this.tijdLabel,
    required this.instructeur,
    required this.onderwerpen,
    required this.feedback,
    required this.beoordeling,
    this.leerlingNotitie,
  });
}
