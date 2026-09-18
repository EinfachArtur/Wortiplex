import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/game_stats.dart';
import '../../state/profile_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statistics)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (profile) {
          final stats = profile.statsFor('classic', profile.language);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _StatTile(label: l10n.gamesPlayed, value: '${stats.gamesPlayed}')),
                  Expanded(
                    child: _StatTile(
                      label: l10n.winRate,
                      value: '${(stats.winRate * 100).round()}%',
                    ),
                  ),
                  Expanded(child: _StatTile(label: l10n.currentStreak, value: '${stats.currentStreak}')),
                  Expanded(child: _StatTile(label: l10n.maxStreak, value: '${stats.maxStreak}')),
                ],
              ),
              const SizedBox(height: 24),
              _GuessDistribution(stats: stats),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ],
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var attempt = 1; attempt <= 6; attempt++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(width: 16, child: Text('$attempt')),
                const SizedBox(width: 8),
                Expanded(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: maxCount == 0
                        ? 0
                        : ((stats.guessDistribution[attempt] ?? 0) / maxCount).clamp(0.04, 1.0),
                    child: Container(
                      height: 20,
                      color: Theme.of(context).colorScheme.primary,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        '${stats.guessDistribution[attempt] ?? 0}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
