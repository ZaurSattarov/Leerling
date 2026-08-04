class LegalDocumentContent {
  final String eyebrow;
  final String title;
  final String version;
  final String effectiveDate;
  final List<LegalSectionContent> sections;

  const LegalDocumentContent({
    required this.eyebrow,
    required this.title,
    required this.version,
    required this.effectiveDate,
    required this.sections,
  });
}

class LegalSectionContent {
  final String title;
  final String body;

  const LegalSectionContent({
    required this.title,
    required this.body,
  });
}
