import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/game_style.dart';
import '../../../domain/models/game_stats.dart';
import '../../state/profile_providers.dart';
import '../../widgets/game_scaffold.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileControllerProvider).valueOrNull;

    return GameScaffold(
      title: l10n.statistics,
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : Builder(builder: (context) {
              final stats = profile.statsFor('classic', profile.language);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Row(
                    children: [
                      Expanded(child: _StatTile(icon: Icons.sports_esports_rounded, color: GameColors.sky, label: l10n.gamesPlayed, value: '${stats.gamesPlayed}')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatTile(icon: Icons.emoji_events_rounded, color: GameColors.amber, label: l10n.winRate, value: '${(stats.winRate * 100).round()}%')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatTile(icon: Icons.local_fire_department_rounded, color: GameColors.coral, label: l10n.currentStreak, value: '${stats.currentStreak}')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatTile(icon: Icons.military_tech_rounded, color: GameColors.mint, label: l10n.maxStreak, value: '${stats.maxStreak}')),
                    ],
                  ),
                  const SizedBox(height: 22),
                  GameText(l10n.guessDistribution, size: 18, textAlign: TextAlign.left, shadow: null),
                  const SizedBox(height: 12),
                  GlassCard(child: _GuessDistribution(stats: stats)),
                ],
              );
            }),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          GameText(value, size: 32, textAlign: TextAlign.left, shadow: null),
          const SizedBox(height: 2),
          GameText(label, size: 13, color: GameColors.textDim, textAlign: TextAlign.left, shadow: null, weight: 500),
        ],
      ),
    );
  }
}

class _GuessDistribution extends StatelessWidget {
  final GameStats stats;
  const _GuessDistribution({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxCount = stats.guessDistribution.values.fold(0, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (var attempt = 1; attempt <= 6; attempt++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 18, child: GameText('$attempt', size: 15, color: GameColors.textDim, shadow: null)),
                const SizedBox(width: 10),
                Expanded(
                  child: LayoutBuilder(builder: (context, c) {
                    final count = stats.guessDistribution[attempt] ?? 0;
                    final fraction = maxCount == 0 ? 0.0 : (count / maxCount).clamp(0.0, 1.0);
                    return Stack(
                      children: [
                        Container(height: 26, decoration: BoxDecoration(color: GameColors.pill, borderRadius: BorderRadius.circular(9))),
                        Container(
                          height: 26,
                          width: count == 0 ? 26 : 26 + (c.maxWidth - 26) * fraction,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 9),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            gradient: LinearGradient(colors: count == 0 ? const [Color(0x33FFFFFF), Color(0x33FFFFFF)] : const [GameColors.mint, GameColors.mintDark]),
                          ),
                          child: GameText('$count', size: 13, color: count == 0 ? Colors.white54 : GameColors.night0, shadow: null),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
