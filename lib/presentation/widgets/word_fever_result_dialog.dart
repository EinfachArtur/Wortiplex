import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/game_style.dart';
import '../../domain/game/word_fever_run.dart';
import '../state/profile_providers.dart';
import 'coin_icon.dart';

/// Shown when the Word Fever clock runs out: score, solved words, record and
/// the coins paid out for the run.
class WordFeverResultDialog extends StatelessWidget {
  final WordFeverRun run;
  final WordFeverPayout payout;
  final int best;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const WordFeverResultDialog({
    super.key,
    required this.run,
    required this.payout,
    required this.best,
    required this.onPlayAgain,
    required this.onHome,
  });

  static Future<void> show(
    BuildContext context, {
    required WordFeverRun run,
    required WordFeverPayout payout,
    required int best,
    required VoidCallback onPlayAgain,
    required VoidCallback onHome,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'WordFeverResult',
      barrierColor: const Color(0xFF0B0724).withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, _, _) => WordFeverResultDialog(
        run: run,
        payout: payout,
        best: best,
        onPlayAgain: onPlayAgain,
        onHome: onHome,
      ),
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
          width: 320,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3B2A8C), Color(0xFF221860)],
            ),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: GameColors.coral, width: 2.5),
            boxShadow: [BoxShadow(color: GameColors.coral.withValues(alpha: 0.3), blurRadius: 40)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, color: GameColors.amber, size: 46),
              const SizedBox(height: 6),
              GameText(l10n.feverTimeUp, size: 26),
              const SizedBox(height: 14),
              GameText(l10n.feverScore.toUpperCase(), size: 12, color: GameColors.textDim, shadow: null, weight: 600),
              GameText(key: const ValueKey('fever_score'), '${run.score}', size: 54, color: GameColors.amber),
              if (payout.isNewBest)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 6),
                  child: GameText(l10n.feverNewBest, size: 16, color: GameColors.mint, shadow: null),
                ),
              const SizedBox(height: 8),
              _StatRow(label: l10n.feverWordsSolved, value: '${run.solved}'),
              _StatRow(label: l10n.feverBestLabel, value: '$best'),
              if (payout.coins > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 16, 6),
                  decoration: BoxDecoration(color: GameColors.pill, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CoinIcon(size: 26),
                      const SizedBox(width: 8),
                      GameText('+${payout.coins}', size: 20, shadow: null),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ChunkyButton(
                key: const ValueKey('fever_again'),
                width: double.infinity,
                height: 58,
                onPressed: () {
                  Navigator.of(context).pop();
                  onPlayAgain();
                },
                child: GameText(l10n.feverPlayAgain.toUpperCase(), size: 19, color: GameColors.night0, shadow: null),
              ),
              const SizedBox(height: 4),
              TextButton(
                key: const ValueKey('fever_home'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onHome();
                },
                child: GameText(l10n.mainMenu, size: 15, color: GameColors.textDim, shadow: null, weight: 600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: GameText(label, size: 15, color: GameColors.textDim, textAlign: TextAlign.left, shadow: null, weight: 600)),
          GameText(value, size: 18, shadow: null),
        ],
      ),
    );
  }
}
