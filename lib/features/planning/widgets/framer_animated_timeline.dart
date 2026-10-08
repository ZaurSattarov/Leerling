import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/utils/datum_utils.dart';
import '../../../models/les.dart';

/// Geanimeerde Framer-geïnspireerde tijdlijn voor de Agenda / Planning
/// 1-op-1 getrouw aan https://timelineanimated.framer.website/ :
/// - Doorlopende verticale progressielijn met dynamische fill & glow
/// - Pulserende knooppunten (past = checkmark, active = radial glow met breathing pulse, future = outline)
/// - Framer card styling met statusbadge, datumindicator, scheidingslijn en subtiele hover/active lift
/// - Inclusief alle inhoud van de les (titel, subtitel, tijden, instructeur, locatie, duur)
class AnimatedFramerTimeline extends StatefulWidget {
  final List<Les> lessen;
  final bool isKomend;
  final ScrollController? scrollController;
  final Widget? trailingWidget;
  final double bottomPadding;

  const AnimatedFramerTimeline({
    super.key,
    required this.lessen,
    required this.isKomend,
    this.scrollController,
    this.trailingWidget,
    this.bottomPadding = 40,
  });

  @override
  State<AnimatedFramerTimeline> createState() => _AnimatedFramerTimelineState();
}

class _AnimatedFramerTimelineState extends State<AnimatedFramerTimeline>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _pulseController;
  bool _ownsScrollController = false;

  // GlobalKeys voor elk item om exacte Y-posities in de scrollview te meten
  final List<GlobalKey> _itemKeys = [];
  int _activeItemIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsScrollController = true;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _syncItemKeys();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalculateProgress());
  }

  void _syncItemKeys() {
    while (_itemKeys.length < widget.lessen.length) {
      _itemKeys.add(GlobalKey());
    }
    if (_itemKeys.length > widget.lessen.length) {
      _itemKeys.removeRange(widget.lessen.length, _itemKeys.length);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedFramerTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessen != widget.lessen) {
      _syncItemKeys();
      WidgetsBinding.instance.addPostFrameCallback((_) => _recalculateProgress());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (_ownsScrollController) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    _recalculateProgress();
  }

  void _recalculateProgress() {
    if (!mounted || widget.lessen.isEmpty) return;

    if (!widget.isKomend) {
      // Afgeronde tab: alle lessen zijn al afgerond, lijn is 100% vol
      setState(() {
        _activeItemIndex = widget.lessen.length - 1;
      });
      return;
    }

    // Voor de Framer animated timeline:
    // De lijn begint bij het eerste knooppunt (top: 24) en groeit mee naar beneden.
    // Wanneer index 0 de actieve les is, reikt de fill exact tot het centrum van het actieve knooppunt.
    // Als de gebruiker scrollt, reikt de fill mee naar het huidige item in het midden van de viewport.
    final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final maxScroll = _scrollController.hasClients && _scrollController.position.hasContentDimensions
        ? _scrollController.position.maxScrollExtent
        : 1.0;

    final ratio = maxScroll > 0 ? (scrollOffset / maxScroll).clamp(0.0, 1.0) : 0.0;
    final targetIndex = (ratio * widget.lessen.length).floor().clamp(0, widget.lessen.length - 1);

    setState(() {
      _activeItemIndex = targetIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primary;
    final lineBgColor = isDark ? const Color(0xFF272F3E) : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, 20, 16, widget.bottomPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1-OP-1 FRAMER CONTINUOUS VERTICAL LINE
              // position: absolute, left: 14.5 (gecentreerd op x=16 van de 32px node track),
              // top: 24, bottom: 24, width: 3
              Positioned(
                left: 14.5,
                top: 24,
                bottom: widget.trailingWidget != null ? 80 : 24,
                child: SizedBox(
                  width: 3,
                  child: Stack(
                    children: [
                      // 1. Achtergrondlijn (100% hoogte, linear-gradient naar transparant)
                      Container(
                        width: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              lineBgColor,
                              lineBgColor,
                              lineBgColor.withValues(alpha: 0.1),
                            ],
                            stops: const [0.0, 0.85, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // 2. Geanimeerde actieve lijn (Framer: linear-gradient van primary naar primary 0.4 met subtiele glow)
                      LayoutBuilder(
                        builder: (context, lineConstraints) {
                          final totalLineHeight = lineConstraints.maxHeight;
                          final activeFraction = widget.lessen.length > 1
                              ? (_activeItemIndex / (widget.lessen.length - 1)).clamp(0.0, 1.0)
                              : 1.0;
                          final activeHeight = widget.isKomend
                              ? math.max(
                                  20.0,
                                  activeFraction * totalLineHeight,
                                )
                              : totalLineHeight;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            width: 3,
                            height: activeHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  primaryColor,
                                  primaryColor,
                                  primaryColor.withValues(alpha: 0.4),
                                ],
                                stops: const [0.0, 0.8, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ITEMS LIJST (Node links exact over de lijn gecentreerd + Framer Card rechts)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int index = 0; index < widget.lessen.length; index++) ...[
                    _buildTimelineRow(
                      index: index,
                      les: widget.lessen[index],
                      primaryColor: primaryColor,
                    ),
                    if (index < widget.lessen.length - 1)
                      const SizedBox(height: 24),
                  ],
                  if (widget.trailingWidget != null) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 46),
                      child: widget.trailingWidget,
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimelineRow({
    required int index,
    required Les les,
    required Color primaryColor,
  }) {
    final bool isPast;
    final bool isActive;
    if (!widget.isKomend) {
      isPast = true;
      isActive = false;
    } else {
      if (index < _activeItemIndex) {
        isPast = true;
        isActive = false;
      } else if (index == _activeItemIndex) {
        isPast = false;
        isActive = true;
      } else {
        isPast = false;
        isActive = false;
      }
    }

    final nodeState = isPast
        ? _TimelineNodeState.past
        : (isActive ? _TimelineNodeState.active : _TimelineNodeState.upcoming);

    return Row(
      key: _itemKeys[index],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Knooppunt links (32 breed, gecentreerd op x=16, exact over de lijn op left:14.5)
        SizedBox(
          width: 32,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: _FramerTimelineNode(
                state: nodeState,
                primaryColor: primaryColor,
                pulseAnimation: _pulseController,
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Framer Card rechts
        Expanded(
          child: _FramerTimelineCard(
            les: les,
            isActive: isActive,
            isPast: isPast,
            isKomend: widget.isKomend,
            primaryColor: primaryColor,
            pulseAnimation: _pulseController,
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/planning/${les.id}');
            },
          ),
        ),
      ],
    );
  }
}

enum _TimelineNodeState { past, active, upcoming }

class _FramerTimelineNode extends StatelessWidget {
  final _TimelineNodeState state;
  final Color primaryColor;
  final Animation<double> pulseAnimation;

  const _FramerTimelineNode({
    required this.state,
    required this.primaryColor,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    const size = 16.0;

    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: _buildNode(context, size),
      ),
    );
  }

  Widget _buildNode(BuildContext context, double size) {
    if (state == _TimelineNodeState.active) {
      // Actief knooppunt: breathing pulse & witte dot, GEEN roze shadows/gloed
      return AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, _) {
          final scale = 1.0 + (pulseAnimation.value * 0.25);
          return SizedBox(
            width: size + 16,
            height: size + 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ademende zachte buitenste ring
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: size + 12,
                    height: size + 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                // Kern cirkel met rand en subtiele neutrale schaduw
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 4,
                        offset: Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (state == _TimelineNodeState.past) {
      // Voltooid: gevulde cirkel met wit vinkje en neutrale schaduw
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryColor,
          boxShadow: const [
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.check,
            size: 11,
            color: Colors.white,
          ),
        ),
      );
    }

    // Toekomstig (upcoming): neutrale cirkel met outline
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

/// 1-op-1 kaart conform de Framer animated timeline card
class _FramerTimelineCard extends StatefulWidget {
  final Les les;
  final bool isActive;
  final bool isPast;
  final bool isKomend;
  final Color primaryColor;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  const _FramerTimelineCard({
    required this.les,
    required this.isActive,
    required this.isPast,
    required this.isKomend,
    required this.primaryColor,
    required this.pulseAnimation,
    required this.onTap,
  });

  @override
  State<_FramerTimelineCard> createState() => _FramerTimelineCardState();
}

class _FramerTimelineCardState extends State<_FramerTimelineCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);
    final dividerColor =
        isDark ? const Color(0xFF2D3748) : const Color(0xFFE5E7EB);

    final isHighlighted = widget.isActive || _isHovered;

    // Nederlandse statusbadges (geen Engelse termen meer)
    final String badgeLabel;
    if (widget.isPast) {
      badgeLabel = 'AFGEROND';
    } else if (widget.isActive) {
      badgeLabel = 'VOLGENDE';
    } else {
      badgeLabel = 'GEPLAND';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: const Cubic(0.23, 1, 0.32, 1),
          transform: isHighlighted
              ? Matrix4.translationValues(0, -3, 0)
              : Matrix4.translationValues(0, 0, 0),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted
                  ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
                  : (isDark
                      ? const Color(0xFF2D3748)
                      : const Color(0xFFE5E7EB)),
              width: isHighlighted ? 1.5 : 1.0,
            ),
            // Schone neutrale schaduwen zonder roze/primary gloed
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Top accent balk als actief (subtiele indicator)
                if (widget.isActive)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 3,
                    child: Container(
                      color: widget.primaryColor,
                    ),
                  ),

                // Inhoud van de kaart
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bovenste balk met Subtitle & Framer Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subtitle / Les fase / Tijdstip
                                Text(
                                  widget.les.tijdvakLabel,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                    letterSpacing: 0.2,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Titel van de les
                                Text(
                                  widget.les.titelLabel,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    letterSpacing: -0.3,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _FramerStatusBadge(
                            label: badgeLabel,
                            state: widget.isPast
                                ? _TimelineNodeState.past
                                : (widget.isActive
                                    ? _TimelineNodeState.active
                                    : _TimelineNodeState.upcoming),
                            primaryColor: widget.primaryColor,
                            pulseAnimation: widget.pulseAnimation,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Datum sectie (neutraal: zwart/textPrimary met iconPrimary)
                      Row(
                        children: [
                          Icon(
                            CoolIcons.calendar,
                            size: 14,
                            color: AppColors.iconPrimary,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            DatumUtils.langeDatum(widget.les.datum),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Dunne scheidingslijn conform Framer card
                      Container(
                        height: 1,
                        color: dividerColor,
                      ),

                      const SizedBox(height: 14),

                      // Les details (locatie, instructeur, onderwerpen of notities)
                      if (widget.les.locatie?.isNotEmpty == true ||
                          widget.les.instructeurNaam?.isNotEmpty == true) ...[
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            if (widget.les.instructeurNaam?.isNotEmpty == true)
                              _FramerMetaChip(
                                icon: CoolIcons.user01,
                                label: widget.les.instructeurNaam!,
                                color: textSecondary,
                              ),
                            if (widget.les.locatie?.isNotEmpty == true)
                              _FramerMetaChip(
                                icon: CoolIcons.mapPin,
                                label: widget.les.locatie!,
                                color: textSecondary,
                              ),
                            _FramerMetaChip(
                              icon: CoolIcons.timer,
                              label:
                                  DatumUtils.duurLabel(widget.les.duurMinuten),
                              color: textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Beschrijvingstekst / Feedback / Advies
                      if (_heeftOmschrijving(widget.les))
                        Text(
                          _beschrijvingTekst(widget.les),
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: textPrimary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _heeftOmschrijving(Les les) {
    return les.afgerondInfoLabel != null ||
        (les.notities?.trim().isNotEmpty ?? false) ||
        (les.instructeurFeedback?.trim().isNotEmpty ?? false);
  }

  String _beschrijvingTekst(Les les) {
    if (les.afgerondInfoLabel != null) return les.afgerondInfoLabel!;
    if (les.instructeurFeedback?.trim().isNotEmpty ?? false) {
      return les.instructeurFeedback!.trim();
    }
    if (les.notities?.trim().isNotEmpty ?? false) {
      return les.notities!.trim();
    }
    return '';
  }
}

/// Kleine meta chip met icoon en tekst
class _FramerMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FramerMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Framer statusbadge — 1-op-1 getrouw aan de solide StatusBadge uit de Instructeur-app
/// Nooit pastel achtergronden: solide verzadigde achtergrond met heldere witte tekst en subtiele schaduw.
class _FramerStatusBadge extends StatelessWidget {
  final String label;
  final _TimelineNodeState state;
  final Color primaryColor;
  final Animation<double> pulseAnimation;

  const _FramerStatusBadge({
    required this.label,
    required this.state,
    required this.primaryColor,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    // Solide kleuren exact conform Instructeur-app StatusBadge:
    // - Afgerond: Color(0xFF4F46E5) (Indigo solid) met wit vinkje
    // - Volgende / Actief: AppColors.successSolid (Groen solid, geen klantio rood)
    // - Gepland: AppColors.infoSolid (Color(0xFF2563EB) SaaS blue)
    final (Color bgColor, IconData? icon) = switch (state) {
      _TimelineNodeState.past => (const Color(0xFF4F46E5), Icons.check),
      _TimelineNodeState.active => (AppColors.successSolid, null),
      _TimelineNodeState.upcoming => (AppColors.infoSolid, null),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 11,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          if (state == _TimelineNodeState.active) ...[
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, _) => Opacity(
                opacity: 0.5 + (pulseAnimation.value * 0.5),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

extension _PlanningLesLabels on Les {
  String get tijdvakLabel => '$starttijd - $eindtijd';

  String get titelLabel {
    final type = lesType?.trim();
    if (type != null && type.isNotEmpty) return type;
    final rijbewijs = rijbewijsSoort?.trim();
    if (rijbewijs != null && rijbewijs.isNotEmpty) {
      return 'Rijles $rijbewijs';
    }
    return 'Rijles';
  }

  String? get afgerondInfoLabel {
    if (geoefendeOnderwerpen.isNotEmpty) {
      return 'Geoefend: ${geoefendeOnderwerpen.join(', ')}';
    }
    final rating = beoordeling?.trim();
    if (rating != null && rating.isNotEmpty) {
      return 'Evaluatie: $rating';
    }
    final advies = volgendeLesAdvies?.trim();
    if (advies != null && advies.isNotEmpty) {
      return 'Volgende focus: $advies';
    }
    return null;
  }
}
