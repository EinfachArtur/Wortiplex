import 'package:flutter/material.dart';

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

class VirtualKeyboard extends StatelessWidget {
  final Language language;
  final Map<String, LetterState> letterStates;
  final Set<String> disabledLetters;
  final void Function(String letter) onLetter;
  final VoidCallback onBackspace;

  const VirtualKeyboard({
    super.key,
    required this.language,
    required this.letterStates,
    required this.disabledLetters,
    required this.onLetter,
    required this.onBackspace,
  });

  Color _keyColor(String letter) {
    if (disabledLetters.contains(letter)) return const Color(0x14FFFFFF);
    return switch (letterStates[letter]) {
      LetterState.correct => AppColors.correct,
      LetterState.present => AppColors.present,
      LetterState.absent => AppColors.absentKey,
      _ => AppColors.keyDefault,
    };
  }

  Color _textColor(String letter) {
    if (disabledLetters.contains(letter)) return Colors.white24;
    return switch (letterStates[letter]) {
      LetterState.present => GameColors.night0,
      LetterState.absent => Colors.white54,
      _ => Colors.white,
    };
  }

  @override
  Widget build(BuildContext context) {
    final rows = _layouts[language]!;
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
                enabled: !disabledLetters.contains(letter),
                onTap: () => onLetter(letter),
                child: Text(letter, style: gameText(19, color: _textColor(letter), weight: 700)),
              ),
            ),
          if (isLast)
            Expanded(
              flex: 6,
              child: _Key(
                color: AppColors.keyDefault,
                onTap: onBackspace,
                child: const Icon(Icons.backspace_rounded, color: Colors.white, size: 22),
              ),
            ),
          if (right > 0) Spacer(flex: right),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final Widget child;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _Key({required this.child, required this.color, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(height: 50, alignment: Alignment.center, child: child),
        ),
      ),
    );
  }
}
