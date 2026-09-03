import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;

import '../../models/factuur.dart';
import '../../models/leerling_profiel.dart';
import '../services/student_service.dart';
import 'datum_utils.dart';

/// Canonical factuur-PDF voor de Leerling-app -- 1-op-1 port van
/// FactuurShareUtils (rijschool-planner-flutter/lib/core/utils/
/// factuur_share_utils.dart): zelfde kleuren, zelfde secties/velden, zelfde
/// berekeningen, client-side gebouwd (nooit ergens opgeslagen). Bewust GEEN
/// tweede, afwijkende factuur-PDF-architectuur -- alleen de databronnen
/// verschillen (leerling = de ingelogde gebruiker zelf, instructeurprofiel
/// via een eigen, minimale, RLS-gescoped select).
///
/// AUTORISATIE: geen nieuwe/aparte laag. `StudentService.getFactuur`/
/// `getMijnFacturen` lopen al via de bestaande RLS-policies
/// `leerling_eigen_facturen_lezen`/`student_facturen_select`
/// (`leerling_id IN (leerlingen WHERE user_id = auth.uid())`) -- een
/// leerling kan dus principieel al geen andermans factuur ophalen, ongeacht
/// welke factuurId wordt geprobeerd. Het instructeurprofiel wordt gelezen
/// via de bestaande policies `leerling_instructeur_profiel_lezen`/
/// `student_instructeur_select` (alleen de eigen gekoppelde instructeur).
class FactuurPdfUtils {
  FactuurPdfUtils._();

  static const _primary = PdfColor.fromInt(0xff1a2332);
  static const _dark = PdfColor.fromInt(0xff0f172a);
  static const _muted = PdfColor.fromInt(0xff6b7280);
  static const _soft = PdfColor.fromInt(0xfff8fafc);
  static const _line = PdfColor.fromInt(0xffe2e8f0);
  static const _white = PdfColors.white;
  static const _mutedLight = PdfColor.fromInt(0xffcbd5e1);

  static Future<void> openPdf(Factuur factuur) async {
    final payload = await _loadPayload(factuur);
    final xFile = await _schrijfTijdelijkPdf(payload.bytes, payload.fileName);
    await SharePlus.instance.share(ShareParams(files: [xFile]));
  }

  static Future<void> downloadPdf(Factuur factuur) async {
    final payload = await _loadPayload(factuur);
    final xFile = await _schrijfTijdelijkPdf(payload.bytes, payload.fileName);
    await SharePlus.instance.share(ShareParams(
      files: [xFile],
      subject: 'Factuur ${factuur.factuurnummer}',
    ));
  }

  static Future<XFile> _schrijfTijdelijkPdf(
    List<int> bytes,
    String fileName,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return XFile(file.path, mimeType: 'application/pdf', name: fileName);
  }

  static Future<_Payload> _loadPayload(Factuur factuur) async {
    final leerling = await StudentService.getMijnProfiel();
    final profiel = await _getInstructeurProfielVoorPdf(factuur.instructeurId);
    final leerlingNaam = [leerling?.voornaam, leerling?.achternaam]
        .where((v) => v != null && v.trim().isNotEmpty)
        .join(' ');
    final fileName = '${_safeFileName(factuur.factuurnummer)}.pdf';
    final bytes = await _buildPdfBytes(
      factuur: factuur,
      profiel: profiel,
      leerling: leerling,
      leerlingNaam: leerlingNaam.isNotEmpty ? leerlingNaam : 'Leerling',
    );
    return _Payload(bytes: bytes, fileName: fileName);
  }

  /// Eigen, minimale select (dezelfde RLS-policies als StudentService.
  /// getMijnInstructeur, maar met de extra facturatievelden die alleen de
  /// PDF nodig heeft: IBAN/BTW-nummer/factuurprefix).
  static Future<_InstructeurPdfProfiel?> _getInstructeurProfielVoorPdf(
    String instructeurId,
  ) async {
    final res = await StudentService.client
        .from('instructeur_profielen')
        .select(
            'rijschool_naam, naam, logo_url, adres, postcode, stad, telefoon, email, website, kvk_nummer, btw_nummer, iban, factuur_prefix')
        .eq('id', instructeurId)
        .maybeSingle();
    if (res == null) return null;
    return _InstructeurPdfProfiel(
      rijschoolNaam: res['rijschool_naam'] as String?,
      naam: res['naam'] as String?,
      logoUrl: res['logo_url'] as String?,
      adres: res['adres'] as String?,
      postcode: res['postcode'] as String?,
      stad: res['stad'] as String?,
      telefoon: res['telefoon'] as String?,
      email: res['email'] as String?,
      website: res['website'] as String?,
      kvkNummer: res['kvk_nummer'] as String?,
      btwNummer: res['btw_nummer'] as String?,
      iban: res['iban'] as String?,
      factuurPrefix: res['factuur_prefix'] as String?,
    );
  }

  static Future<List<int>> _buildPdfBytes({
    required Factuur factuur,
    required _InstructeurPdfProfiel? profiel,
    required LeerlingProfiel? leerling,
    required String leerlingNaam,
  }) async {
    // Expliciet Inter laden als PDF-basisfont -- de standaard base14-fonts
    // (Helvetica) van het `pdf`-package kennen geen €-glyph en tonen die
    // dan als een leeg kruisje/vierkantje (o.a. zichtbaar naast "Totaal").
    // Inter (al gebundeld als appfont, zie pubspec.yaml) ondersteunt € wel.
    final interRegular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf'));
    final interBold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Bold.ttf'));
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: interRegular, bold: interBold),
    );
    final regels = factuur.factuurregels ?? const <FactuurRegel>[];
    final subtotaal = factuur.subtotaalCents ??
        (regels.isNotEmpty
            ? regels.fold<int>(
                0, (sum, regel) => sum + (regel.totaalCents - regel.btwCents))
            : factuur.bedragCents);
    final btw = factuur.btwCents ??
        (regels.isNotEmpty
            ? regels.fold<int>(0, (sum, regel) => sum + regel.btwCents)
            : 0);
    final logo = await _loadLogoImage(profiel?.logoUrl);
    final companyName = _clean(profiel?.rijschoolNaam) ??
        _clean(profiel?.naam) ??
        'Mijn Rijschool';

    final footerParts = _nonEmpty([
      _prefixed('KvK', profiel?.kvkNummer),
      _prefixed('BTW', profiel?.btwNummer),
      _prefixed('IBAN', profiel?.iban),
    ]);
    final footerText =
        footerParts.isNotEmpty ? footerParts.join('  ·  ') : companyName;

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.fromLTRB(34, 34, 34, 30),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: _line, thickness: 0.5),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    footerText,
                    style: const pw.TextStyle(fontSize: 7, color: _muted),
                  ),
                ),
                pw.Text(
                  'Pagina ${context.pageNumber}/${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7, color: _muted),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          _invoiceHeader(factuur: factuur, profiel: profiel, logo: logo),
          pw.SizedBox(height: 28),
          _clientSection(leerlingNaam: leerlingNaam, leerling: leerling),
          pw.SizedBox(height: 26),
          _itemsTable(factuur: factuur, regels: regels),
          pw.SizedBox(height: 20),
          _totalsBlock(
            subtotaal: subtotaal,
            btw: btw,
            totaal: factuur.bedragCents,
          ),
          pw.SizedBox(height: 26),
          _paymentSection(factuur: factuur, profiel: profiel),
          if (_clean(factuur.notities) != null) ...[
            pw.SizedBox(height: 18),
            _noteSection(factuur.notities!),
          ],
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              'Bedankt voor uw vertrouwen in $companyName.',
              style: const pw.TextStyle(fontSize: 8.5, color: _muted),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _invoiceHeader({
    required Factuur factuur,
    required _InstructeurPdfProfiel? profiel,
    required pw.MemoryImage? logo,
  }) {
    final companyName = _clean(profiel?.rijschoolNaam) ??
        _clean(profiel?.naam) ??
        'Mijn Rijschool';
    final placeLine = _joinLine([profiel?.postcode, profiel?.stad]);
    final companyLines = _nonEmpty([
      profiel?.adres,
      placeLine,
      profiel?.telefoon,
      profiel?.email,
      profiel?.website,
    ]);

    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: pw.BoxDecoration(
        color: _dark,
        borderRadius: pw.BorderRadius.circular(18),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logo != null)
                  pw.Container(
                    height: 48,
                    width: 140,
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  )
                else
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: _white,
                    ),
                  ),
                if (logo != null) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: _white,
                    ),
                  ),
                ],
                pw.SizedBox(height: 8),
                ...companyLines.map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      line,
                      style:
                          const pw.TextStyle(fontSize: 8.5, color: _mutedLight),
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: _primary,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'FACTUUR',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              _metaLineDark('Factuurnummer', _factuurnummer(factuur, profiel)),
              _metaLineDark('Factuurdatum', _formatDate(factuur.aangemaaktOp)),
              if (_clean(factuur.vervaldatum) != null)
                _metaLineDark('Vervaldatum', _formatDate(factuur.vervaldatum!)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _metaLineDark(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$label: ',
            style: const pw.TextStyle(fontSize: 8.5, color: _mutedLight),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              color: _white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _clientSection({
    required String leerlingNaam,
    required LeerlingProfiel? leerling,
  }) {
    final contactLines = _nonEmpty([
      leerling?.adres,
      leerling?.telefoon,
      leerling?.email,
    ]);

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.8),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'FACTUUR AAN',
            style: pw.TextStyle(
              fontSize: 8,
              color: _muted,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            leerlingNaam,
            style: pw.TextStyle(
              fontSize: 12,
              color: _dark,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (contactLines.isNotEmpty) pw.SizedBox(height: 3),
          ...contactLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: pw.Text(
                line,
                style: const pw.TextStyle(fontSize: 9, color: _muted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _itemsTable({
    required Factuur factuur,
    required List<FactuurRegel> regels,
  }) {
    final rows = regels.isEmpty
        ? [
            _InvoiceRow(
              omschrijving: factuur.beschrijving.isNotEmpty
                  ? factuur.beschrijving
                  : 'Factuur',
              aantal: 1,
              prijsCents: factuur.bedragCents,
              totaalCents: factuur.bedragCents,
            )
          ]
        : regels
            .map(
              (regel) => _InvoiceRow(
                omschrijving: regel.omschrijving,
                aantal: regel.aantal,
                prijsCents: regel.prijsPerStukCents,
                totaalCents: regel.totaalCents,
              ),
            )
            .toList();

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1.6),
      },
      border: const pw.TableBorder(
        bottom: pw.BorderSide(color: _line, width: 0.8),
        horizontalInside: pw.BorderSide(color: _line, width: 0.5),
      ),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _dark),
          children: [
            _tableCell('Omschrijving', header: true, dark: true),
            _tableCell('Aantal', header: true, alignRight: true, dark: true),
            _tableCell('Prijs/stuk',
                header: true, alignRight: true, dark: true),
            _tableCell('Totaal', header: true, alignRight: true, dark: true),
          ],
        ),
        ...rows.asMap().entries.map(
              (entry) => pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: entry.key.isEven ? _soft : _white,
                ),
                children: [
                  _tableCell(entry.value.omschrijving),
                  _tableCell('${entry.value.aantal}', alignRight: true),
                  _tableCell(
                    _euro(entry.value.prijsCents),
                    alignRight: true,
                  ),
                  _tableCell(
                    _euro(entry.value.totaalCents),
                    alignRight: true,
                    bold: true,
                  ),
                ],
              ),
            ),
      ],
    );
  }

  static pw.Widget _totalsBlock({
    required int subtotaal,
    required int btw,
    required int totaal,
  }) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 240,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line, width: 0.8),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          children: [
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _totalLine('Subtotaal', _euro(subtotaal)),
            ),
            pw.Divider(color: _line, height: 1, thickness: 0.8),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _totalLine('BTW', _euro(btw)),
            ),
            pw.Divider(color: _dark, height: 1, thickness: 1),
            pw.Container(
              decoration: const pw.BoxDecoration(
                color: _dark,
                borderRadius: pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(11),
                  bottomRight: pw.Radius.circular(11),
                ),
              ),
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: _totalLine(
                'Totaal',
                _euro(totaal),
                strong: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _paymentSection({
    required Factuur factuur,
    required _InstructeurPdfProfiel? profiel,
  }) {
    final iban = _clean(profiel?.iban) ?? _clean(factuur.ibanSnapshot);
    final paymentLines = _nonEmpty([
      _prefixed('IBAN', iban),
      _prefixed(
        'Betaalkenmerk',
        _clean(factuur.betalingskenmerk) ?? _factuurnummer(factuur, profiel),
      ),
      _prefixed('Betaalmethode', _betaalmethodeLabel(factuur)),
      _prefixed('Status', factuur.status.label),
      // Betaallink hoort bewust NIET in de PDF -- zelfde regel als
      // FactuurShareUtils._paymentSection.
    ]);

    if (paymentLines.isEmpty) return pw.SizedBox.shrink();

    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: _soft,
        border: pw.Border.all(color: _line, width: 0.8),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 60,
            margin: const pw.EdgeInsets.only(right: 14),
            decoration: pw.BoxDecoration(
              color: _primary,
              borderRadius: pw.BorderRadius.circular(4),
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Betaling',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _dark,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                ...paymentLines.map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      line,
                      style: const pw.TextStyle(fontSize: 9, color: _muted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _noteSection(String note) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _soft,
        border: pw.Border.all(color: _line, width: 0.8),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Notities',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: _dark,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            note,
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(
    String value, {
    bool header = false,
    bool alignRight = false,
    bool dark = false,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: pw.Align(
        alignment:
            alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: header ? 8.5 : 9.5,
            color: dark ? _white : (header ? _muted : _dark),
            fontWeight:
                (header || bold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  static pw.Widget _totalLine(
    String label,
    String value, {
    bool strong = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: strong ? 11 : 9.5,
            color: strong ? _white : _muted,
            fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: strong ? 14 : 9.5,
            // Zelfde contrastfix als Admin Web (2026-08-18): _primary op
            // _dark-achtergrond is bijna onleesbaar -- alleen dit veld wit,
            // verder identiek aan de canonical Dart-bron.
            color: strong ? _white : _dark,
            fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  static Future<pw.MemoryImage?> _loadLogoImage(String? rawUrl) async {
    final url = _clean(rawUrl);
    if (url == null) return null;
    try {
      final uri = Uri.parse(url);
      if (!uri.hasAbsolutePath && !uri.hasScheme) return null;
      final data = await NetworkAssetBundle(uri).load(url);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _euro(int cents) {
    final value = (cents / 100).toStringAsFixed(2).replaceAll('.', ',');
    return '€ $value';
  }

  static String _safeFileName(String raw) {
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9-_]'), '_');
  }

  static String _formatDate(String raw) {
    // langeDatum ("18 augustus 2026") i.p.v. korteDatum ("18 aug") -- matcht
    // het formaat van de canonical PDF (zie Admin Web-render van FactuurShareUtils).
    try {
      return DatumUtils.langeDatum(raw);
    } catch (_) {
      return raw;
    }
  }

  static String _factuurnummer(
    Factuur factuur,
    _InstructeurPdfProfiel? profiel,
  ) {
    final nummer = _clean(factuur.factuurnummer);
    if (nummer != null) return nummer;
    final prefix = _clean(profiel?.factuurPrefix);
    return prefix == null ? '-' : '${prefix}0000';
  }

  static String? _betaalmethodeLabel(Factuur factuur) {
    if ((factuur.effectieveBetaalUrl ?? '').trim().isNotEmpty &&
        (factuur.betaalmethode == null || factuur.betaalmethode!.isEmpty)) {
      return 'Betaalverzoek';
    }
    switch (factuur.betaalmethode) {
      case 'ideal':
        return 'iDEAL';
      case 'contant':
        return 'Contant';
      case 'ideal_tikkie':
        return 'iDEAL / Tikkie';
      case 'bankoverschrijving':
        return 'SEPA / bankoverschrijving';
      case 'pin':
        return 'Pin';
      default:
        return null;
    }
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static List<String> _nonEmpty(List<String?> values) {
    return values.map(_clean).whereType<String>().toList();
  }

  static String? _joinLine(List<String?> values) {
    final parts = _nonEmpty(values);
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  static String? _prefixed(String label, String? value) {
    final clean = _clean(value);
    if (clean == null) return null;
    return '$label: $clean';
  }
}

class _InstructeurPdfProfiel {
  final String? rijschoolNaam;
  final String? naam;
  final String? logoUrl;
  final String? adres;
  final String? postcode;
  final String? stad;
  final String? telefoon;
  final String? email;
  final String? website;
  final String? kvkNummer;
  final String? btwNummer;
  final String? iban;
  final String? factuurPrefix;

  const _InstructeurPdfProfiel({
    this.rijschoolNaam,
    this.naam,
    this.logoUrl,
    this.adres,
    this.postcode,
    this.stad,
    this.telefoon,
    this.email,
    this.website,
    this.kvkNummer,
    this.btwNummer,
    this.iban,
    this.factuurPrefix,
  });
}

class _InvoiceRow {
  final String omschrijving;
  final int aantal;
  final int prijsCents;
  final int totaalCents;

  const _InvoiceRow({
    required this.omschrijving,
    required this.aantal,
    required this.prijsCents,
    required this.totaalCents,
  });
}

class _Payload {
  final List<int> bytes;
  final String fileName;
  const _Payload({required this.bytes, required this.fileName});
}
