import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../state/profile_providers.dart';

/// Combines the "free gifts" daily login bonus and the spin wheel into one
/// compact home-screen card, matching the reference screenshots' daily
/// engagement hooks.
class DailyRewardsCard extends ConsumerWidget {
  const DailyRewardsCard({super.key});

  Future<void> _claimDailyLogin(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final coins = await ref.read(profileControllerProvider.notifier).claimDailyLoginReward();
    if (!context.mounted) return;
    if (coins != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dailyLoginClaim(coins))),
      );
    }
  }

  Future<void> _spin(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final coins = await ref.read(profileControllerProvider.notifier).spinWheel();
    if (!context.mounted) return;
    if (coins != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Icon(Icons.celebration, color: AppColors.coinGold, size: 48),
          content: Text(l10n.spinWheelWon(coins), textAlign: TextAlign.center),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Re-reading the notifier's availability checks on every rebuild keeps
    // this in sync after a claim without needing separate stream providers.
    ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    final loginAvailable = controller.isDailyLoginRewardAvailable();
    final spinAvailable = controller.isSpinAvailable();

    return Row(
      children: [
        Expanded(
          child: _RewardTile(
            icon: Icons.card_giftcard,
            title: l10n.dailyLoginTitle,
            actionLabel: loginAvailable ? null : l10n.dailyLoginClaimed,
            enabled: loginAvailable,
            onTap: () => _claimDailyLogin(context, ref),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RewardTile(
            icon: Icons.casino,
            title: l10n.spinWheelTitle,
            actionLabel: spinAvailable ? l10n.spinWheelAction : l10n.spinWheelUsed,
            enabled: spinAvailable,
            onTap: () => _spin(context, ref),
          ),
        ),
      ],
    );
  }
}

class _RewardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final bool enabled;
  final VoidCallback onTap;

  const _RewardTile({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 28, color: enabled ? AppColors.coinGold : Colors.grey),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              if (actionLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  actionLabel!,
                  style: TextStyle(fontSize: 11, color: enabled ? Theme.of(context).colorScheme.primary : Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
