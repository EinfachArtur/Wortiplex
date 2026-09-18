import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/economy_config.dart';
import '../screens/spin/spin_wheel_screen.dart';
import '../state/profile_providers.dart';
import 'reward_dialog.dart';

/// Combines the "free gifts" daily login bonus and the spin wheel into one
/// compact home-screen card, matching the reference screenshots' daily
/// engagement hooks.
class DailyRewardsCard extends ConsumerWidget {
  const DailyRewardsCard({super.key});

  Future<void> _claimDailyLogin(BuildContext context, WidgetRef ref) async {
    final coins = await ref.read(profileControllerProvider.notifier).claimDailyLoginReward();
    if (!context.mounted) return;
    if (coins != null) {
      RewardCelebrationDialog.show(
        context,
        coins: coins,
        title: 'TÄGLICHER BONUS! 🎁',
        message: 'Danke fürs Vorbeischauen! Dein tägliches Geschenk wartet.',
        icon: Icons.card_giftcard_rounded,
      );
    }
  }

  void _openWheel(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpinWheelScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Re-reading the notifier's availability checks on every rebuild keeps
    // this in sync after a claim without needing separate stream providers.
    ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    final loginAvailable = controller.isDailyLoginRewardAvailable();
    final freeSpins = controller.freeSpinsAvailable();

    return Row(
      children: [
        Expanded(
          child: _RewardTile(
            icon: Icons.card_giftcard,
            title: l10n.dailyLoginTitle,
            actionLabel: loginAvailable ? l10n.dailyLoginClaim(controller.nextDailyLoginCoins()) : l10n.dailyLoginClaimed,
            enabled: loginAvailable,
            onTap: () => _claimDailyLogin(context, ref),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RewardTile(
            icon: Icons.casino,
            title: l10n.spinWheelTitle,
            actionLabel: freeSpins > 0 ? '${l10n.spinButton} · ${l10n.free}' : '${l10n.spinButton} · ${EconomyConfig.spinCost}',
            enabled: true,
            onTap: () => _openWheel(context),
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
