import 'package:flutter/material.dart';

import '../../core/theme/game_style.dart';

/// Wortiplex coin: a gold disc with a raised rim and a "W".
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
          colors: [GameColors.goldLight, GameColors.gold, Color(0xFFD48A00)],
        ),
        border: Border.all(color: const Color(0xFFB87400), width: size / 12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1.5))],
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.66,
        height: size * 0.66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x55FFFFFF), width: size / 24),
        ),
        alignment: Alignment.center,
        child: Text(
          'W',
          style: TextStyle(
            fontFamily: kGameFont,
            fontSize: size * 0.48,
            height: 1,
            color: const Color(0xFFFFF4C2),
            shadows: const [Shadow(color: Color(0xFF9A6100), blurRadius: 0, offset: Offset(0, 1))],
          ),
        ),
      ),
    );
  }
}
