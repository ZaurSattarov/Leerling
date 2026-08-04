import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
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
    final profiel = _profiel;
    if (profiel == null) return;
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
  }

  Future<void> _verwijder(LeerlingBeschikbaarheid item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
    if (confirm != true) return;
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
            eyebrowText: 'BESCHIKBAARHEID',
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
  }

  int get _startMin => _startTijd.hour * 60 + _startTijd.minute;
  int get _eindMin => _eindTijd.hour * 60 + _eindTijd.minute;

  String _formatTijd(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _kiesTijd(bool isStart) async {
    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => _KlantioTijdPickerSheet(
        title: isStart ? 'Starttijd kiezen' : 'Eindtijd kiezen',
        initialTime: isStart ? _startTijd : _eindTijd,
        startTime: _startTijd,
        endTime: _eindTijd,
        isStart: isStart,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startTijd = picked;
      } else {
        _eindTijd = picked;
      }
      _fout = null;
    });
  }

  Future<void> _opslaanFormulier() async {
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

              // Starttijd en eindtijd
              Row(
                children: [
                  Expanded(
                    child: _TijdKiezer(
                      label: 'Starttijd',
                      tijd: _formatTijd(_startTijd),
                      onTap: _opslaan ? null : () => _kiesTijd(true),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: SizedBox(
                      width: 28,
                      child: Center(
                        child: const Text('–',
                            style: TextStyle(
                                fontSize: 18, color: AppColors.textSecondary)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _TijdKiezer(
                      label: 'Eindtijd',
                      tijd: _formatTijd(_eindTijd),
                      onTap: _opslaan ? null : () => _kiesTijd(false),
                    ),
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

// ─── Tijd kiezer widget ────────────────────────────────────────────

class _TijdKiezer extends StatelessWidget {
  final String label;
  final String tijd;
  final VoidCallback? onTap;

  const _TijdKiezer({
    required this.label,
    required this.tijd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: onTap != null ? AppColors.white : AppColors.borderLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                tijd,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: onTap != null
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Fout weergave ────────────────────────────────────────────────

class _KlantioTijdPickerSheet extends StatefulWidget {
  final String title;
  final TimeOfDay initialTime;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isStart;

  const _KlantioTijdPickerSheet({
    required this.title,
    required this.initialTime,
    required this.startTime,
    required this.endTime,
    required this.isStart,
  });

  @override
  State<_KlantioTijdPickerSheet> createState() =>
      _KlantioTijdPickerSheetState();
}

class _KlantioTijdPickerSheetState extends State<_KlantioTijdPickerSheet> {
  late TimeOfDay _selected;
  late TextEditingController _controller;
  String? _error;

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
    _selected = widget.initialTime;
    _controller = TextEditingController(text: _format(_selected));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  TimeOfDay? _parse(String raw) {
    final match =
        RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(raw.trim());
    if (match == null) return null;
    return TimeOfDay(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  void _select(TimeOfDay time) {
    setState(() {
      _selected = time;
      _controller.text = _format(time);
      _error = null;
    });
  }

  void _confirm() {
    final parsed = _parse(_controller.text);
    if (parsed == null) {
      setState(() => _error = 'Gebruik 24-uursnotatie, bijvoorbeeld 09:00.');
      return;
    }
    final start = widget.isStart ? parsed : widget.startTime;
    final end = widget.isStart ? widget.endTime : parsed;
    if (_minutes(end) <= _minutes(start)) {
      setState(() => _error = 'Starttijd moet voor eindtijd zijn.');
      return;
    }
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Tijd kiezen',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeSummary(
                          label: 'Begin',
                          value: _format(
                              widget.isStart ? _selected : widget.startTime),
                          active: widget.isStart,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TimeSummary(
                          label: 'Einde',
                          value: _format(
                              widget.isStart ? widget.endTime : _selected),
                          active: !widget.isStart,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                      LengthLimitingTextInputFormatter(5),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Tijd',
                      hintText: '09:00',
                    ),
                    onChanged: (value) {
                      final parsed = _parse(value);
                      if (parsed != null) _selected = parsed;
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Snelle keuzes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final time in _quickTimes)
                        ChoiceChip(
                          label: Text(_format(time)),
                          selected: _format(time) == _format(_selected),
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            color: _format(time) == _format(_selected)
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(
                            color: _format(time) == _format(_selected)
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          onSelected: (_) => _select(time),
                        ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.dangerBorder),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.dangerText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuleren'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _confirm,
                          child: const Text('Tijd gebruiken'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeSummary extends StatelessWidget {
  final String label;
  final String value;
  final bool active;

  const _TimeSummary({
    required this.label,
    required this.value,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: active ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
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
