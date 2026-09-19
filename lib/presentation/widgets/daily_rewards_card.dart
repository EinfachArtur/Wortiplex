import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/economy_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/game_style.dart';
import '../screens/spin/spin_wheel_screen.dart';
import '../state/profile_providers.dart';
import 'reward_dialog.dart';

/// The two daily engagement hooks on the home screen: the daily gift and the
/// prize wheel.
class DailyRewardsCard extends ConsumerWidget {
  /// Stretch the tiles to the height the parent gives them (home screen on tall phones).
  final bool fill;
  const DailyRewardsCard({super.key, this.fill = false});

  Future<void> _claimDailyLogin(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final coins = await ref.read(profileControllerProvider.notifier).claimDailyLoginReward();
    if (!context.mounted || coins == null) return;
    RewardCelebrationDialog.show(
      context,
      coins: coins,
      title: l10n.dailyLoginTitle,
      message: l10n.dailyLoginClaimed,
      imageAsset: 'assets/images/Geschenk.png',
    );
  }

  void _openWheel(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpinWheelScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Re-reading the availability checks on every profile change keeps the
    // tiles in sync after a claim without extra providers.
    ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    final loginAvailable = controller.isDailyLoginRewardAvailable();
    final freeSpins = controller.freeSpinsAvailable();

    return Row(
      crossAxisAlignment: fill ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _RewardTile(
            imageAsset: 'assets/images/Geschenk.png',
            color: GameColors.coral,
            title: l10n.dailyLoginTitle,
            actionLabel: loginAvailable ? l10n.dailyLoginClaim(controller.nextDailyLoginCoins()) : l10n.dailyLoginClaimed,
            highlight: loginAvailable,
            onTap: loginAvailable ? () => _claimDailyLogin(context, ref) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RewardTile(
            imageAsset: 'assets/images/Glücksrad.png',
            color: GameColors.violet,
            title: l10n.spinWheelTitle,
            actionLabel: freeSpins > 0 ? '${l10n.spinButton} · ${l10n.free}' : '${l10n.spinButton} · ${EconomyConfig.spinCost}',
            highlight: freeSpins > 0,
            onTap: () => _openWheel(context),
          ),
        ),
      ],
    );
  }
}

class _RewardTile extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final Color color;
  final String title;
  final String actionLabel;
  final bool highlight;
  final VoidCallback? onTap;

  const _RewardTile({
    this.icon,
    this.imageAsset,
    required this.color,
    required this.title,
    required this.actionLabel,
    required this.highlight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: GameColors.glass,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: highlight ? GameColors.mint : GameColors.glassBorder, width: highlight ? 2 : 1),
          boxShadow: highlight ? [BoxShadow(color: GameColors.mint.withValues(alpha: 0.28), blurRadius: 16)] : null,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The artwork takes whatever height the text and padding leave over.
            final art = constraints.hasBoundedHeight ? (constraints.maxHeight - 86).clamp(40.0, 88.0) : 56.0;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageAsset != null)
                  SizedBox(
                    width: art,
                    height: art,
                    child: Image.asset(imageAsset!, fit: BoxFit.contain),
                  )
                else
                  Container(
                    width: art,
                    height: art,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color.lerp(color, Colors.white, 0.25)!, color]),
                    ),
                    child: Center(child: Icon(icon, color: GameColors.night0, size: 28)),
                  ),
                const SizedBox(height: 6),
                GameText(title, size: 15, shadow: null),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: highlight ? GameColors.mint : GameColors.pill, borderRadius: BorderRadius.circular(14)),
                  child: GameText(
                    actionLabel,
                    size: 11,
                    color: highlight ? GameColors.night0 : GameColors.textDim,
                    shadow: null,
                    weight: 700,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
