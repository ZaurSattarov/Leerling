import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import 'voortgang_trends_provider.dart';
import 'widgets/tijdlijn_card.dart';

/// Volledig historisch tijdlijnoverzicht -- bereikbaar via "Zie alles" op
/// het Voortgang-tabblad. Toont dezelfde [TijdlijnCard]-opbouw als de
/// hoofdpagina, maar dan met de volledige geschiedenis i.p.v. alleen de
/// laatste gebeurtenis. Geen aparte databron -- zelfde
/// [voortgangTrendsProvider], alleen ongefilterd getoond.
class VoortgangTijdlijnScreen extends ConsumerWidget {
  const VoortgangTijdlijnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(voortgangTrendsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const MainDetailHeader(
            title: 'Voortgang tijdlijn',
            fallbackRoute: '/voortgang',
          ),
          Expanded(
            child: trendsAsync.when(
              data: (trends) => RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(voortgangTrendsProvider),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    TijdlijnCard(items: trends.tijdlijn),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Kon tijdlijn niet laden',
                  subtitle: e.toString(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
