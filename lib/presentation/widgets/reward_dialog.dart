import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/game_style.dart';
import 'coin_icon.dart';

/// Small celebration card shown when the player receives coins (daily gift).
class RewardCelebrationDialog extends StatelessWidget {
  final int coins;
  final String title;
  final String message;
  final IconData icon;

  const RewardCelebrationDialog({
    super.key,
    required this.coins,
    required this.title,
    required this.message,
    this.icon = Icons.card_giftcard_rounded,
  });

  static Future<void> show(
    BuildContext context, {
    required int coins,
    required String title,
    required String message,
    IconData icon = Icons.card_giftcard_rounded,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'RewardCelebration',
      barrierColor: const Color(0xFF0B0724).withValues(alpha: 0.78),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, _, _) => RewardCelebrationDialog(coins: coins, title: title, message: message, icon: icon),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(scale: curved, child: FadeTransition(opacity: anim, child: child));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3B2A8C), Color(0xFF221860)]),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: GameColors.amber, width: 2.5),
            boxShadow: [BoxShadow(color: GameColors.amber.withValues(alpha: 0.3), blurRadius: 40)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [GameColors.amber.withValues(alpha: 0.5), GameColors.amber.withValues(alpha: 0)]),
                    ),
                  ),
                  const CoinIcon(size: 96),
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: GameColors.coral, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              GameText(title, size: 24),
              const SizedBox(height: 6),
              GameText(message, size: 14, color: GameColors.textDim, shadow: null, weight: 500),
              const SizedBox(height: 14),
              GameText('+$coins', size: 46, color: GameColors.amber),
              GameText(l10n.coins, size: 16, color: GameColors.textDim, shadow: null, weight: 600),
              const SizedBox(height: 22),
              ChunkyButton(
                width: 200,
                height: 56,
                onPressed: () => Navigator.of(context).pop(),
                child: GameText(l10n.ok, size: 22, color: GameColors.night0, shadow: null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
