import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/game_style.dart';
import '../state/profile_providers.dart';
import 'coin_icon.dart';

/// Dark pill with the coin balance and a green "+" (matches the reference HUD).
class CoinPill extends ConsumerWidget {
  final VoidCallback onAdd;
  const CoinPill({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(profileControllerProvider.select((p) => p.valueOrNull?.coins ?? 0));
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 16, right: 6),
        decoration: BoxDecoration(color: GameColors.pill, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedText('$coins', size: 22),
            const SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                const CoinIcon(size: 30),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: const BoxDecoration(color: Color(0xFF3DC23D), shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

/// Dark pill with a number and a small icon, e.g. the spin ticket counter.
class CountPill extends StatelessWidget {
  final int count;
  final IconData icon;
  final Color iconColor;
  const CountPill({super.key, required this.count, required this.icon, this.iconColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 16, right: 10),
      decoration: BoxDecoration(color: GameColors.pill, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedText('$count', size: 22),
          const SizedBox(width: 8),
          Icon(icon, color: iconColor, size: 26),
        ],
      ),
    );
  }
}

/// Round white back chevron used in the game-style screens.
class GameBackButton extends StatelessWidget {
  const GameBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      iconSize: 40,
      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, shadows: [
        Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
      ]),
    );
  }
}
