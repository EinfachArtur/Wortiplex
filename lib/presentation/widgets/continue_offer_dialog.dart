import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/economy_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/game_style.dart';
import '../screens/shop/shop_screen.dart';
import '../state/profile_providers.dart';
import 'coin_icon.dart';

/// Shown right after a round was lost: offers one more attempt for coins so
/// the player can keep their streak. Resolves to `true` if the player wants
/// to buy the attempt and `false` if they give up.
class ContinueOfferDialog extends ConsumerWidget {
  final int streak;

  const ContinueOfferDialog({super.key, required this.streak});

  static Future<bool> show(BuildContext context, {required int streak}) async {
    final choice = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'ContinueOffer',
      barrierColor: const Color(0xFF0B0724).withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, _, _) => ContinueOfferDialog(streak: streak),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(scale: curved, child: FadeTransition(opacity: anim, child: child));
      },
    );
    // Dismissing the dialog any other way (e.g. system back) counts as giving up.
    return choice ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final coins = ref.watch(profileControllerProvider.select((p) => p.valueOrNull?.coins ?? 0));
    final cost = EconomyConfig.extraAttemptCost;
    final canAfford = coins >= cost;
    final hasStreak = streak > 0;

    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3B2A8C), Color(0xFF221860)]),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: GameColors.coral, width: 2.5),
              boxShadow: [BoxShadow(color: GameColors.coral.withValues(alpha: 0.35), blurRadius: 40)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Badge(streak: streak),
                const SizedBox(height: 16),
                GameText(hasStreak ? l10n.continueTitleStreak : l10n.continueTitleNoStreak, size: 28),
                const SizedBox(height: 8),
                GameText(
                  hasStreak ? l10n.continueBodyStreak(streak) : l10n.continueBodyNoStreak,
                  size: 15,
                  color: GameColors.textDim,
                  shadow: null,
                  weight: 500,
                ),
                const SizedBox(height: 22),
                ChunkyButton(
                  width: double.infinity,
                  height: 60,
                  onPressed: canAfford ? () => Navigator.of(context).pop(true) : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_rounded, color: canAfford ? GameColors.night0 : Colors.white54, size: 26),
                      const SizedBox(width: 8),
                      GameText(l10n.continueBuy, size: 19, color: canAfford ? GameColors.night0 : Colors.white54, shadow: null),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
                        decoration: BoxDecoration(color: GameColors.night0.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CoinIcon(size: 20),
                            const SizedBox(width: 5),
                            GameText('$cost', size: 15, shadow: null),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!canAfford) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CoinIcon(size: 18),
                      const SizedBox(width: 6),
                      GameText('$coins · ${l10n.notEnoughCoins}', size: 13, color: GameColors.coral, shadow: null, weight: 600),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen())),
                    child: GameText(l10n.continueGetCoins, size: 14, color: GameColors.mint, shadow: null),
                  ),
                ],
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: GameText(hasStreak ? l10n.continueDeclineStreak : l10n.continueDeclineNoStreak, size: 15, color: GameColors.textDim, shadow: null, weight: 600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A flame with the streak number, or a plain "retry" badge without a streak.
class _Badge extends StatelessWidget {
  final int streak;
  const _Badge({required this.streak});

  @override
  Widget build(BuildContext context) {
    final hasStreak = streak > 0;
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF9A9A), GameColors.coral]),
        boxShadow: [BoxShadow(color: GameColors.coral.withValues(alpha: 0.6), blurRadius: 24)],
      ),
      child: hasStreak
          ? Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.local_fire_department_rounded, color: GameColors.amber, size: 68),
                Positioned(bottom: 16, child: GameText('$streak', size: 24, color: GameColors.night0, shadow: null)),
              ],
            )
          : const Icon(Icons.replay_rounded, color: GameColors.night0, size: 50),
    );
  }
}
