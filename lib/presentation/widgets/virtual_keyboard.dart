import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/game_style.dart';
import '../../domain/models/language.dart';
import '../../domain/models/letter_state.dart';

const _layouts = {
  Language.en: [
    'QWERTYUIOP',
    'ASDFGHJKL',
    'ZXCVBNM',
  ],
  Language.de: [
    'QWERTZUIOPÜ',
    'ASDFGHJKLÖÄ',
    'YXCVBNM',
  ],
  Language.ru: [
    'ЙЦУКЕНГШЩЗХЪ',
    'ФЫВАПРОЛДЖЭ',
    'ЯЧСМИТЬБЮ',
  ],
};

class VirtualKeyboard extends StatefulWidget {
  final Language language;
  final Map<String, LetterState> letterStates;
  final Set<String> disabledLetters;
  final void Function(String letter) onLetter;
  final VoidCallback onBackspace;

  /// New letter colours are applied this long after they arrive, so the
  /// keyboard does not spoil the tile flip that is still running.
  final Duration revealDelay;

  const VirtualKeyboard({
    super.key,
    required this.language,
    required this.letterStates,
    required this.disabledLetters,
    required this.onLetter,
    required this.onBackspace,
    this.revealDelay = const Duration(milliseconds: 1600),
  });

  @override
  State<VirtualKeyboard> createState() => _VirtualKeyboardState();
}

class _VirtualKeyboardState extends State<VirtualKeyboard> {
  late Map<String, LetterState> _shown = widget.letterStates;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant VirtualKeyboard old) {
    super.didUpdateWidget(old);
    if (mapEquals(widget.letterStates, old.letterStates)) return;

    _timer?.cancel();
    final next = widget.letterStates;
    final reset = next.length < _shown.length || widget.language != old.language;
    if (reset) {
      _shown = next; // a new round starts: clear the colours immediately
    } else {
      _timer = Timer(widget.revealDelay, () {
        if (mounted) setState(() => _shown = widget.letterStates);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _keyColor(String letter) {
    if (widget.disabledLetters.contains(letter)) return const Color(0x14FFFFFF);
    return switch (_shown[letter]) {
      LetterState.correct => AppColors.correct,
      LetterState.present => AppColors.present,
      LetterState.absent => AppColors.absentKey,
      _ => AppColors.keyDefault,
    };
  }

  Color _textColor(String letter) {
    if (widget.disabledLetters.contains(letter)) return Colors.white24;
    return switch (_shown[letter]) {
      LetterState.present => GameColors.night0,
      LetterState.absent => Colors.white54,
      _ => Colors.white,
    };
  }

  @override
  Widget build(BuildContext context) {
    final rows = _layouts[widget.language]!;
    // Every row is laid out on the width of the longest row so that keys keep
    // one uniform size regardless of how many letters a language has per row.
    final maxKeys = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) _buildRow(rows, i, maxKeys),
        ],
      ),
    );
  }

  // Flex units: one letter key = 4, backspace = 6, remaining space is split
  // into spacers so every row spans the same width and keys stay uniform.
  Widget _buildRow(List<String> rows, int i, int maxKeys) {
    final isLast = i == rows.length - 1;
    final letters = rows[i].split('');
    final used = letters.length * 4 + (isLast ? 6 : 0);
    final remaining = (maxKeys * 4 - used).clamp(0, 1000);
    final left = remaining ~/ 2;
    final right = remaining - left;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          if (left > 0) Spacer(flex: left),
          for (final letter in letters)
            Expanded(
              flex: 4,
              child: _Key(
                color: _keyColor(letter),
                enabled: !widget.disabledLetters.contains(letter),
                onTap: () => widget.onLetter(letter),
                child: Text(letter, style: gameText(19, color: _textColor(letter), weight: 700)),
              ),
            ),
          if (isLast)
            Expanded(
              flex: 6,
              child: _Key(
                color: AppColors.keyDefault,
                onTap: widget.onBackspace,
                child: const Icon(Icons.backspace_rounded, color: Colors.white, size: 22),
              ),
            ),
          if (right > 0) Spacer(flex: right),
        ],
      ),
    );
  }
}

/// A key that shrinks and brightens while pressed and gives a light haptic tick.
class _Key extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _Key({required this.child, required this.color, required this.onTap, this.enabled = true});

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.enabled && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final color = _pressed ? Color.lerp(widget.color, Colors.white, 0.3)! : widget.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: Duration(milliseconds: _pressed ? 50 : 320),
            curve: Curves.easeOut,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
