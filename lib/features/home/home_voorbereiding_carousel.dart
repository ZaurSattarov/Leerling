import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/cool_icons.dart';
import '../../shared/widgets/klantio_pressable.dart';
import '../../shared/widgets/main_scaffold.dart' show metNativeNavAfgedekt;
import 'cbr_voorbereiding_data.dart';

/// Home-carousel met examenvoorbereiding (CBR-vragen) boven een foto van een
/// auto in Nederland. Vervangt de drie losse kerncijfer-kaarten. Tik opent
/// alle vragen en antwoorden van de categorie.
class HomeVoorbereidingCarousel extends StatefulWidget {
  /// Rijbewijscategorie van de leerling (A/A1/A2 = motor, anders auto).
  final String? rijbewijsSoort;

  const HomeVoorbereidingCarousel({super.key, this.rijbewijsSoort});

  static const double hoogte = 196;

  @override
  State<HomeVoorbereidingCarousel> createState() =>
      _HomeVoorbereidingCarouselState();
}

class _HomeVoorbereidingCarouselState extends State<HomeVoorbereidingCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _pagina = 0;

  List<CbrCategorie> get _categorieen =>
      cbrCategorieenVoor(widget.rijbewijsSoort);

  @override
  void didUpdateWidget(covariant HomeVoorbereidingCarousel old) {
    super.didUpdateWidget(old);
    if (_categorieen != cbrCategorieenVoor(old.rijbewijsSoort)) {
      _pagina = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || !_controller.hasClients) return;
      final volgende = (_pagina + 1) % _categorieen.length;
      _controller.animateToPage(
        volgende,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dagelijks wisselende uitgelichte vraag per categorie.
    final dag = DateTime.now().difference(DateTime(2026)).inDays;

    return SizedBox(
      height: HomeVoorbereidingCarousel.hoogte,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Listener(
              onPointerDown: (_) => _timer?.cancel(),
              onPointerUp: (_) => _startTimer(),
              child: PageView.builder(
                controller: _controller,
                itemCount: _categorieen.length,
                onPageChanged: (i) => setState(() => _pagina = i),
                itemBuilder: (context, i) {
                  final cat = _categorieen[i];
                  return _Slide(
                    categorie: cat,
                    uitgelicht: cat.vragen[(dag + i) % cat.vragen.length],
                    onTap: () => _openCategorie(context, cat),
                  );
                },
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: IgnorePointer(
                child: Row(
                  children: [
                    for (var i = 0; i < _categorieen.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(left: 4),
                        width: i == _pagina ? 16 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: i == _pagina ? 0.95 : 0.5),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCategorie(BuildContext context, CbrCategorie cat) {
    return metNativeNavAfgedekt<void>(
      context,
      () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CategorieSheet(categorie: cat),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final CbrCategorie categorie;
  final CbrVraag uitgelicht;
  final VoidCallback onTap;

  const _Slide({
    required this.categorie,
    required this.uitgelicht,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KlantioPressable(
      onTap: onTap,
      pressedScale: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            categorie.foto,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: AppColors.splashBackground),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x40101722),
                  Color(0xF2101722)
                ],
                stops: [0, 0.3, 0.85],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categorie.titel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  uitgelicht.vraag,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        uitgelicht.antwoord,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.isDarkMode
                            ? const Color(0xFF283244)
                            : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CoolIcons.chevronRight,
                        size: 16,
                        color: AppColors.iconPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorieSheet extends StatelessWidget {
  final CbrCategorie categorie;

  const _CategorieSheet({required this.categorie});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      categorie.foto,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0xCC101722)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: Text(
                        categorie.titel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (final v in categorie.vragen)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.vraag,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      v.antwoord,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
