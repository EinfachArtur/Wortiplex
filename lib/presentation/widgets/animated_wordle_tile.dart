import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/game_style.dart';
import '../../domain/models/letter_state.dart';

/// An animated letter tile for Wordle that supports:
/// 1. Tactile pop-in / bounce when a letter is typed or updated.
/// 2. 3D card flip with perspective when evaluated, keeping letters upright.
/// 3. Staggered vertical bounce wave on victory.
class AnimatedWordleTile extends StatefulWidget {
  final String letter;
  final String? placeholder;
  final LetterState state;
  final Duration flipDelay;
  final Duration flipDuration;
  final bool winWave;
  final Duration? winWaveDelay;
  final Duration winWaveDuration;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;

  /// Tile height, when it should differ from [size] (its width) — e.g. a
  /// tall, narrow tile in date-guess mode, where 8 columns leave little
  /// width to spare but plenty of height. Defaults to a square tile.
  final double? height;
  final double borderRadius;
  final double fontSize;

  const AnimatedWordleTile({
    super.key,
    required this.letter,
    this.placeholder,
    required this.state,
    this.flipDelay = Duration.zero,
    this.flipDuration = const Duration(milliseconds: 500),
    this.winWave = false,
    this.winWaveDelay,
    this.winWaveDuration = const Duration(milliseconds: 480),
    this.isSelected = false,
    this.onTap,
    this.size = 56.0,
    this.height,
    this.borderRadius = 14.0,
    this.fontSize = 28.0,
  });

  @override
  State<AnimatedWordleTile> createState() => _AnimatedWordleTileState();
}

class _AnimatedWordleTileState extends State<AnimatedWordleTile> with TickerProviderStateMixin {
  late final AnimationController _popController = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));

  late final AnimationController _flipController = AnimationController(vsync: this, duration: widget.flipDuration);

  late final AnimationController _winWaveController = AnimationController(vsync: this, duration: widget.winWaveDuration);

  late final Animation<double> _popScaleAnimation = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 0.85, end: 1.15).chain(CurveTween(curve: Curves.easeOutQuad)), weight: 45),
    TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeInOutQuad)), weight: 55),
  ]).animate(_popController);

  late final Animation<double> _borderHighlightAnimation = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).animate(CurvedAnimation(parent: _popController, curve: Curves.easeOut));

  Timer? _flipTimer;
  Timer? _winWaveTimer;
  LetterState _beforeState = LetterState.unknown;

  @override
  void initState() {
    super.initState();
    if (widget.letter.isNotEmpty && widget.state == LetterState.unknown) {
      _popController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedWordleTile old) {
    super.didUpdateWidget(old);

    // 1. Pop-in / bounce when typing or replacing a letter while un-evaluated.
    if (widget.state == LetterState.unknown && widget.letter.isNotEmpty && widget.letter != old.letter) {
      _popController.forward(from: 0.0);
    }

    // 2. 3D Card Flip when row is evaluated.
    if (old.state == LetterState.unknown && widget.state != LetterState.unknown) {
      _beforeState = LetterState.unknown;
      _flipTimer?.cancel();
      _flipTimer = Timer(widget.flipDelay, () {
        if (mounted) _flipController.forward(from: 0.0);
      });
    }

    // 3. Staggered Victory Wave Hop.
    if (!old.winWave && widget.winWave) {
      _winWaveTimer?.cancel();
      final delay = widget.winWaveDelay ?? (widget.flipDelay + widget.flipDuration + const Duration(milliseconds: 80));
      _winWaveTimer = Timer(delay, () {
        if (mounted) _winWaveController.forward(from: 0.0);
      });
    }
  }

  @override
  void dispose() {
    _flipTimer?.cancel();
    _winWaveTimer?.cancel();
    _popController.dispose();
    _flipController.dispose();
    _winWaveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_popController, _flipController, _winWaveController]),
      builder: (context, _) {
        final t = _flipController.value;
        final isFlipping = _flipController.isAnimating;

        // Phase 1 (0ms - 250ms): show pre-evaluation face.
        // Phase 2 (250ms - 500ms): show evaluated face.
        final shownState = (isFlipping && t < 0.5) ? _beforeState : widget.state;

        // Angle rotation: 0° -> 90° for first half, -90° -> 0° for second half.
        // This ensures the letter always stays upright without upside-down mirroring.
        final double angle;
        if (!isFlipping) {
          angle = 0.0;
        } else if (t < 0.5) {
          angle = (t * 2.0) * (math.pi / 2);
        } else {
          angle = (1.0 - (t - 0.5) * 2.0) * (-math.pi / 2);
        }

        final popScale = _popController.isAnimating ? _popScaleAnimation.value : 1.0;
        final hopY = _winWaveController.isAnimating ? -18.0 * math.sin(_winWaveController.value * math.pi) : 0.0;
        final hopScale = _winWaveController.isAnimating ? 1.0 + 0.06 * math.sin(_winWaveController.value * math.pi) : 1.0;

        return Transform.translate(
          offset: Offset(0, hopY),
          child: Transform.scale(
            scale: popScale * hopScale,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(angle),
              child: _buildTileFace(shownState),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTileFace(LetterState state) {
    final evaluated = state != LetterState.unknown;
    final Color fill = switch (state) {
      LetterState.correct => AppColors.correct,
      LetterState.present => AppColors.present,
      LetterState.absent => AppColors.absent,
      LetterState.unknown => AppColors.tileEmpty,
    };
    final Color textColor = switch (state) {
      LetterState.present => GameColors.night0,
      LetterState.absent => Colors.white70,
      _ => Colors.white,
    };
    final hasLetter = widget.letter.isNotEmpty;
    final hasPlaceholder = !hasLetter && widget.placeholder != null && widget.placeholder!.isNotEmpty;

    final borderHighlight = _popController.isAnimating ? _borderHighlightAnimation.value : 0.0;
    final Color borderColor = widget.isSelected
        ? GameColors.mint
        : (hasLetter ? (Color.lerp(Colors.white70, Colors.white, borderHighlight) ?? Colors.white70) : AppColors.tileBorder);

    final double borderWidth = widget.isSelected ? 2.5 : (_popController.isAnimating ? 2.2 : 2.0);

    final List<BoxShadow>? shadows = evaluated && state != LetterState.absent
        ? [BoxShadow(color: fill.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 3))]
        : (widget.isSelected
              ? [BoxShadow(color: GameColors.mint.withValues(alpha: 0.55), blurRadius: 12)]
              : (_popController.isAnimating && hasLetter
                    ? [BoxShadow(color: Colors.white.withValues(alpha: 0.25 * borderHighlight), blurRadius: 8)]
                    : null));

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: widget.size,
        height: widget.height ?? widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: evaluated ? null : Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: !evaluated && hasLetter
            // A freshly typed letter drops in from above and fades in.
            ? TweenAnimationBuilder<double>(
                key: ValueKey('drop_${widget.letter}'),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 190),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Opacity(
                  opacity: (v * 1.6).clamp(0.0, 1.0),
                  child: Transform.translate(offset: Offset(0, -18.0 * (1.0 - v)), child: child),
                ),
                child: Text(widget.letter, style: gameText(widget.fontSize, color: textColor, weight: 800)),
              )
            : (!evaluated && hasPlaceholder
                ? Text(
                    widget.placeholder!,
                    style: gameText(
                      widget.fontSize,
                      color: Colors.white.withValues(alpha: 0.22),
                      weight: 700,
                    ),
                  )
                : Text(widget.letter, style: gameText(widget.fontSize, color: textColor, weight: 800))),
      ),
    );
  }
}
