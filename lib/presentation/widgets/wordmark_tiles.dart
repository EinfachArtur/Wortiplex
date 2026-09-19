import 'package:flutter/material.dart';

import '../../core/theme/game_style.dart';

/// The app name spelled out in chunky letter tiles that pop in one after the
/// other when the screen opens.
class WordmarkTiles extends StatefulWidget {
  final String word;
  final double maxTileSize;
  final double gap;

  const WordmarkTiles({super.key, this.word = 'WORTIPLEX', this.maxTileSize = 50, this.gap = 6});

  @override
  State<WordmarkTiles> createState() => _WordmarkTilesState();
}

class _WordmarkTilesState extends State<WordmarkTiles> with SingleTickerProviderStateMixin {
  static const _palette = [
    GameColors.mint,
    GameColors.amber,
    GameColors.coral,
    GameColors.violet,
    GameColors.sky,
  ];

  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.word.characters.toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - widget.gap * (letters.length - 1);
        final size = (available / letters.length).clamp(20.0, widget.maxTileSize);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < letters.length; i++) ...[
              if (i > 0) SizedBox(width: widget.gap),
              _tile(letters[i], _palette[i % _palette.length], size, i, letters.length),
            ],
          ],
        );
      },
    );
  }

  Widget _tile(String letter, Color color, double size, int index, int count) {
    // Each tile owns a slice of the intro animation, so they pop in one by one.
    final start = index / (count + 3);
    final animation = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, (start + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutBack),
    );
    final lip = size * 0.1;
    return ScaleTransition(
      scale: animation,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.28),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.white, 0.22)!, color],
          ),
          boxShadow: [
            BoxShadow(color: Color.lerp(color, Colors.black, 0.35)!, offset: Offset(0, lip)),
            BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: Offset(0, lip + 2)),
          ],
        ),
        child: GameText(letter, size: size * 0.6, color: Colors.white),
      ),
    );
  }
}
