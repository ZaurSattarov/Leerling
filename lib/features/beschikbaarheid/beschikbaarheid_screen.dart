import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../core/utils/tijd_invoer_formatter.dart';
import '../../models/leerling_beschikbaarheid.dart';
import '../../models/leerling_profiel.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../../shared/widgets/snackbar.dart';

// ─── Screen ───────────────────────────────────────────────────────

class BeschikbaarheidScreen extends ConsumerStatefulWidget {
  const BeschikbaarheidScreen({super.key});

  @override
  ConsumerState<BeschikbaarheidScreen> createState() =>
      _BeschikbaarheidScreenState();
}

class _BeschikbaarheidScreenState extends ConsumerState<BeschikbaarheidScreen> {
  List<LeerlingBeschikbaarheid>? _items;
  bool _laden = true;
  String? _fout;
  LeerlingProfiel? _profiel;

  // Hardening tegen dubbele Navigator-operaties (zie onderzoek naar de
  // gemelde '!_debugLocked'-assertion): geen bevestigde reproductie
  // gevonden, maar deze twee entry points (FAB + tegel-bewerken) konden
  // allebei showModalBottomSheet/showDialog aanroepen zonder enige guard
  // tegen een tweede aanroep terwijl de eerste nog open staat.
  bool _formulierOpen = false;
  bool _verwijderDialoogOpen = false;

  @override
  void initState() {
    super.initState();
    _laadData();
  }

  Future<void> _laadData() async {
    try {
      final profiel = await ref.read(mijnProfielProvider.future);
      if (profiel == null) {
        if (mounted) {
          setState(() {
            _laden = false;
            _fout = 'Geen profiel gevonden';
          });
        }
        return;
      }
      _profiel = profiel;
      final items = await StudentService.getMijnBeschikbaarheid(profiel.id);
      if (mounted) {
        setState(() {
          _items = items;
          _laden = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _laden = false;
          _fout = e.toString();
        });
      }
    }
  }

  Future<void> _refresh() async {
    final profiel = _profiel;
    if (profiel == null) return;
    try {
      final items = await StudentService.getMijnBeschikbaarheid(profiel.id);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Laden mislukt', isError: true);
    }
  }

  Future<void> _toonFormulier([LeerlingBeschikbaarheid? bestaand]) async {
    // Guard: voorkomt dat een tweede tik (FAB of een tegel) tijdens het
    // openen van de sheet een tweede Navigator-push start.
    if (_formulierOpen) return;
    final profiel = _profiel;
    if (profiel == null) return;
    _formulierOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _BeschikbaarheidFormulier(
          bestaand: bestaand,
          leerlingId: profiel.id,
          instructeurId: profiel.instructeurId,
          onOpgeslagen: _refresh,
        ),
      );
    } finally {
      _formulierOpen = false;
    }
  }

  Future<void> _verwijder(LeerlingBeschikbaarheid item) async {
    // Guard: voorkomt een tweede showDialog-aanroep bij een dubbele tik op
    // de verwijderknop van een tegel.
    if (_verwijderDialoogOpen) return;
    _verwijderDialoogOpen = true;
    bool confirm;
    try {
      confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Verwijderen',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              content: Text(
                  '${item.dagNaam} ${item.startTijdKort} – ${item.eindTijdKort} verwijderen?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annuleren'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dangerSolid),
                  child: const Text('Verwijderen'),
                ),
              ],
            ),
          ) ==
          true;
    } finally {
      _verwijderDialoogOpen = false;
    }
    if (!confirm) return;
    try {
      await StudentService.verwijderBeschikbaarheid(item.id);
      await _refresh();
      if (mounted) {
        showAppSnackBar(context, 'Tijdblok verwijderd', isSuccess: true);
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Verwijderen mislukt', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: _laden
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _toonFormulier(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Tijd toevoegen',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
      body: Column(
        children: [
          const MainDetailHeader(
            title: 'Mijn tijden',
          ),
          Expanded(
            child: _laden
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _fout != null
                    ? _FoutWeergave(fout: _fout!, onRetry: _laadData)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _refresh,
                        child: CustomScrollView(
                          slivers: [
                            // Info banner
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 20, 20, 12),
                                child: AppCard(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0F2F5),
                                          borderRadius:
                                              BorderRadius.circular(9),
                                        ),
                                        child: const Icon(
                                            Icons.info_outline_rounded,
                                            color: AppColors.iconDark,
                                            size: 17),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Geef aan wanneer je meestal rijles kunt volgen. '
                                          'Je instructeur gebruikt deze tijden voor de weekplanning.',
                                          style: TextStyle(
                                              fontSize: 13,
                                              height: 1.4,
                                              color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Lege staat
                            if (_items == null || _items!.isEmpty)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: EmptyState(
                                  icon: Icons.schedule_outlined,
                                  title:
                                      'Je hebt nog geen beschikbaarheid toegevoegd.',
                                  subtitle:
                                      'Tik op "Tijd toevoegen" om tijdblokken in te vullen.',
                                ),
                              )
                            else
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 8, 20, 100),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (ctx, i) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _BeschikbaarheidTegel(
                                        item: _items![i],
                                        onBewerk: () =>
                                            _toonFormulier(_items![i]),
                                        onVerwijder: () =>
                                            _verwijder(_items![i]),
                                      ),
                                    ),
                                    childCount: _items!.length,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Tegel (lijstitem) ─────────────────────────────────────────────

class _BeschikbaarheidTegel extends StatelessWidget {
  final LeerlingBeschikbaarheid item;
  final VoidCallback onBewerk;
  final VoidCallback onVerwijder;

  const _BeschikbaarheidTegel({
    required this.item,
    required this.onBewerk,
    required this.onVerwijder,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onBewerk,
      child: Row(
        children: [
          // Dag afkorting badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.dagNaam.substring(0, 2),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Dag + tijden
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.dagNaam,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.startTijdKort} – ${item.eindTijdKort}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Voorkeur sterren
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Icon(
                i < item.voorkeurScore
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 14,
                color: i < item.voorkeurScore
                    ? AppColors.warningSolid
                    : AppColors.textMuted,
              ),
            ),
          ),

          // Verwijder knop
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textHint, size: 20),
            onPressed: onVerwijder,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formulier (bottom sheet) ──────────────────────────────────────

class _BeschikbaarheidFormulier extends ConsumerStatefulWidget {
  final LeerlingBeschikbaarheid? bestaand;
  final String leerlingId;
  final String instructeurId;
  final Future<void> Function() onOpgeslagen;

  const _BeschikbaarheidFormulier({
    required this.bestaand,
    required this.leerlingId,
    required this.instructeurId,
    required this.onOpgeslagen,
  });

  @override
  ConsumerState<_BeschikbaarheidFormulier> createState() =>
      _BeschikbaarheidFormulierState();
}

class _BeschikbaarheidFormulierState
    extends ConsumerState<_BeschikbaarheidFormulier> {
  int _dag = 0;
  TimeOfDay _startTijd = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _eindTijd = const TimeOfDay(hour: 12, minute: 0);
  int _score = 3;
  bool _opslaan = false;
  String? _fout;

  // Begin/Einde zijn nu rechtstreeks in dit formulier bewerkbaar -- geen
  // los tweede sheet meer. `_actiefVeld` bepaalt welk van de twee net is
  // aangeraakt (zichtbaar via de solide accentkleur) en dus welk veld een
  // "Snelle keuze"-tik bijwerkt. Eén bron van waarheid: _startTijd/
  // _eindTijd; de controllers zijn alleen de tekstweergave daarvan.
  _ActiefTijdVeld _actiefVeld = _ActiefTijdVeld.begin;
  late final TextEditingController _startCtrl;
  late final TextEditingController _eindCtrl;
  late final FocusNode _startFocus;
  late final FocusNode _eindFocus;

  static const _quickTimes = [
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 17, minute: 0),
    TimeOfDay(hour: 19, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.bestaand;
    if (b != null) {
      _dag = b.dagVanWeek;
      final s = b.startTijdKort.split(':');
      final e = b.eindTijdKort.split(':');
      _startTijd = TimeOfDay(hour: int.parse(s[0]), minute: int.parse(s[1]));
      _eindTijd = TimeOfDay(hour: int.parse(e[0]), minute: int.parse(e[1]));
      _score = b.voorkeurScore;
    }
    _startCtrl = TextEditingController(text: _formatTijd(_startTijd));
    _eindCtrl = TextEditingController(text: _formatTijd(_eindTijd));
    _startFocus = FocusNode()
      ..addListener(() {
        if (_startFocus.hasFocus) {
          setState(() => _actiefVeld = _ActiefTijdVeld.begin);
        }
      });
    _eindFocus = FocusNode()
      ..addListener(() {
        if (_eindFocus.hasFocus) {
          setState(() => _actiefVeld = _ActiefTijdVeld.eind);
        }
      });
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _eindCtrl.dispose();
    _startFocus.dispose();
    _eindFocus.dispose();
    super.dispose();
  }

  int get _startMin => _startTijd.hour * 60 + _startTijd.minute;
  int get _eindMin => _eindTijd.hour * 60 + _eindTijd.minute;

  String _formatTijd(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay? _parseTijd(String raw) {
    final match =
        RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(raw.trim());
    if (match == null) return null;
    return TimeOfDay(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  // Bijgewerkt bij elke toetsaanslag. Zolang de tekst geen volledig geldige
  // HH:MM is (bv. tijdens het typen van "15:") laten we _startTijd/
  // _eindTijd bewust ongewijzigd -- geen crash, gewoon nog geen nieuwe
  // waarde totdat de invoer compleet is. Opslaan valideert zelf nogmaals
  // vanuit de actuele tekst (zie _opslaanFormulier).
  void _onVeldGewijzigd(_ActiefTijdVeld veld, String waarde) {
    final parsed = _parseTijd(waarde);
    setState(() {
      if (parsed != null) {
        if (veld == _ActiefTijdVeld.begin) {
          _startTijd = parsed;
        } else {
          _eindTijd = parsed;
        }
      }
      if (_fout != null) _fout = null;
    });
  }

  void _kiesSnelleTijd(TimeOfDay time) {
    setState(() {
      if (_actiefVeld == _ActiefTijdVeld.begin) {
        _startTijd = time;
        _startCtrl.text = _formatTijd(time);
      } else {
        _eindTijd = time;
        _eindCtrl.text = _formatTijd(time);
      }
      _fout = null;
    });
  }

  Future<void> _opslaanFormulier() async {
    // Nogmaals vanuit de actuele tekst valideren (niet alleen vertrouwen op
    // de laatst geparste _startTijd/_eindTijd) -- zo kan er nooit worden
    // opgeslagen terwijl een veld nog een onvolledige/ongeldige tijd toont
    // (bv. "15:").
    final geparsteStart = _parseTijd(_startCtrl.text);
    final geparsteEind = _parseTijd(_eindCtrl.text);
    if (geparsteStart == null || geparsteEind == null) {
      setState(() => _fout = 'Gebruik 24-uursnotatie, bijvoorbeeld 09:00.');
      return;
    }
    _startTijd = geparsteStart;
    _eindTijd = geparsteEind;
    if (_eindMin <= _startMin) {
      setState(() => _fout = 'Starttijd moet vóór eindtijd zijn.');
      return;
    }
    setState(() {
      _opslaan = true;
      _fout = null;
    });
    try {
      final startStr = '${_formatTijd(_startTijd)}:00';
      final eindStr = '${_formatTijd(_eindTijd)}:00';
      if (widget.bestaand != null) {
        await StudentService.updateBeschikbaarheid(
          id: widget.bestaand!.id,
          dagVanWeek: _dag,
          startTijd: startStr,
          eindTijd: eindStr,
          voorkeurScore: _score,
        );
      } else {
        await StudentService.voegBeschikbaarheidToe(
          leerlingId: widget.leerlingId,
          instructeurId: widget.instructeurId,
          dagVanWeek: _dag,
          startTijd: startStr,
          eindTijd: eindStr,
          voorkeurScore: _score,
        );
      }
      await widget.onOpgeslagen();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _opslaan = false;
          _fout = 'Opslaan mislukt. Probeer opnieuw.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + insets.bottom),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titel
              Text(
                widget.bestaand != null
                    ? 'Tijdblok bewerken'
                    : 'Tijdblok toevoegen',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Geef aan wanneer je rijles kunt volgen.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 20),

              // Dag
              const Text('Dag',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _dag,
                decoration: const InputDecoration(),
                items: List.generate(
                  7,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(LeerlingBeschikbaarheid.dagNamen[i]),
                  ),
                ),
                onChanged: _opslaan ? null : (v) => setState(() => _dag = v!),
              ),

              const SizedBox(height: 16),

              // Begin en Einde -- rechtstreeks bewerkbaar, geen los sheet.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TijdVeldKaart(
                      label: 'Begin',
                      controller: _startCtrl,
                      focusNode: _startFocus,
                      heeftFout: _fout != null,
                      enabled: !_opslaan,
                      onChanged: (v) =>
                          _onVeldGewijzigd(_ActiefTijdVeld.begin, v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TijdVeldKaart(
                      label: 'Einde',
                      controller: _eindCtrl,
                      focusNode: _eindFocus,
                      heeftFout: _fout != null,
                      enabled: !_opslaan,
                      onChanged: (v) =>
                          _onVeldGewijzigd(_ActiefTijdVeld.eind, v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text('Snelle keuzes',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final time in _quickTimes)
                    _SnelleTijdChip(
                      label: _formatTijd(time),
                      selected: _formatTijd(time) ==
                          _formatTijd(_actiefVeld == _ActiefTijdVeld.begin
                              ? _startTijd
                              : _eindTijd),
                      onTap: _opslaan ? null : () => _kiesSnelleTijd(time),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Voorkeur score
              const Text('Voorkeur',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              const Text(
                'Hoe goed past dit tijdstip?',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap:
                        _opslaan ? null : () => setState(() => _score = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        (i + 1) <= _score
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 34,
                        color: (i + 1) <= _score
                            ? AppColors.warningSolid
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$_score van 5 - voorkeur',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Fout
              if (_fout != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E2E7)),
                  ),
                  child: Text(_fout!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.dangerSolid)),
                ),
              ],

              const SizedBox(height: 20),

              // Opslaan knop
              ElevatedButton(
                onPressed: _opslaan ? null : _opslaanFormulier,
                child: _opslaan
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Opslaan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Begin/Einde -- inline in het formulier, geen los sheet meer ────
//
// `_actiefVeld` bepaalt welk van de twee velden net is aangeraakt en dus
// het doel is van de "Snelle keuzes"-chips -- zichtbaar via Flutter's eigen
// focus-rand op het aangetikte veld (zie _TijdVeldKaart), geen verborgen
// state. Bron van waarheid is _startTijd/_eindTijd in
// _BeschikbaarheidFormulierState hierboven.

enum _ActiefTijdVeld { begin, eind }

// Begin/Einde-kaart: label klein boven het veld, tijd groot erin. PRECIES
// ÉÉN visuele doos -- het TextField ZELF is de doos (via zijn eigen
// InputDecoration/border), geen los omhullend Container-vlak eromheen. De
// globale InputDecorationTheme (zie app.dart: filled: true,
// fillColor: AppColors.white) tekende voorheen al een eigen witte,
// afgeronde doos BINNEN de oude buitenste Container -- dat was de dubbele
// doos. Hier hergebruiken we die achtergrond bewust als de ENIGE laag en
// sturen we alleen de randkleur bij (enabledBorder/focusedBorder): bij
// focus verandert UITSLUITEND de rand naar AppColors.primary, nooit de
// vulling. Tekst blijft altijd AppColors.textPrimary (donker) -- ook actief
// -- dus nooit onleesbaar wit-op-wit meer.
class _TijdVeldKaart extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool heeftFout;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _TijdVeldKaart({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.heeftFout,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final randKleur = heeftFout ? AppColors.dangerSolid : AppColors.border;
    final focusRandKleur = heeftFout ? AppColors.dangerSolid : AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: const [TimeInputFormatter()],
          cursorColor: AppColors.primary,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.white,
            hintText: '--:--',
            hintStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textHint,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: randKleur),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: randKleur),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: focusRandKleur, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// Snelle-keuze chip: actief = solide primary-vulling + witte tekst/vinkje
// (NOOIT pastel roze). Inactief = witte achtergrond, donkere tekst,
// subtiele rand.
class _SnelleTijdChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SnelleTijdChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoutWeergave extends StatelessWidget {
  final String fout;
  final VoidCallback onRetry;

  const _FoutWeergave({required this.fout, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.dangerSolid),
            const SizedBox(height: 16),
            const Text('Kon gegevens niet laden',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(fout,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      ),
    );
  }
}
