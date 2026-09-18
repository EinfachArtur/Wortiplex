import 'package:flutter/material.dart';

import '../../core/theme/game_style.dart';

/// Wortiplex coin: a gold disc with a raised rim and an embossed star.
class CoinIcon extends StatelessWidget {
  final double size;
  const CoinIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GameColors.amberLight, GameColors.amber, Color(0xFFE8920A)],
        ),
        border: Border.all(color: const Color(0xFFC77A00), width: size / 13),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1.5))],
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.68,
        height: size * 0.68,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x66FFFFFF), width: size / 26)),
        alignment: Alignment.center,
        child: Icon(
          Icons.star_rounded,
          size: size * 0.5,
          color: const Color(0xFFFFF6D6),
          shadows: const [Shadow(color: Color(0xFFB36B00), offset: Offset(0, 1))],
        ),
      ),
    );
  }
}
