import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/game_style.dart';
import '../state/profile_providers.dart';
import 'coin_icon.dart';

/// Dark glass pill with the coin balance and a mint "+" button.
class CoinPill extends ConsumerWidget {
  final VoidCallback onAdd;
  const CoinPill({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(profileControllerProvider.select((p) => p.valueOrNull?.coins ?? 0));
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        height: 42,
        padding: const EdgeInsets.only(left: 8, right: 6),
        decoration: BoxDecoration(
          color: GameColors.pill,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: GameColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CoinIcon(size: 28),
            const SizedBox(width: 8),
            GameText('$coins', size: 20, shadow: null),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: GameColors.mint, shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, size: 20, color: GameColors.night0),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark glass pill with an icon and a number, e.g. the spin ticket counter.
class CountPill extends StatelessWidget {
  final int count;
  final IconData icon;
  final Color iconColor;
  const CountPill({super.key, required this.count, required this.icon, this.iconColor = GameColors.amber});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: GameColors.pill,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: GameColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 8),
          GameText('$count', size: 20, shadow: null),
        ],
      ),
    );
  }
}

/// Round glass back button.
class GameBackButton extends StatelessWidget {
  const GameBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(color: GameColors.glass, shape: BoxShape.circle, border: Border.all(color: GameColors.glassBorder)),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
      ),
    );
  }
}
