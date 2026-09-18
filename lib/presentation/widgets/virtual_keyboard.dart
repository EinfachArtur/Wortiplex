import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
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
    if (disabledLetters.contains(letter)) return AppColors.absent.withValues(alpha: 0.4);
    return switch (letterStates[letter]) {
      LetterState.correct => AppColors.correct,
      LetterState.present => AppColors.present,
      LetterState.absent => AppColors.absentKey,
      _ => AppColors.keyDefault,
    };
  }

  Color _textColor(String letter) {
    if (disabledLetters.contains(letter) || letterStates[letter] != null) return Colors.white;
    return Colors.black87;
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
              child: _LetterKey(
                letter: letter,
                color: _keyColor(letter),
                textColor: _textColor(letter),
                enabled: !disabledLetters.contains(letter),
                onTap: () => onLetter(letter),
              ),
            ),
          if (isLast) Expanded(flex: 6, child: _BackspaceKey(onTap: onBackspace)),
          if (right > 0) Spacer(flex: right),
        ],
      ),
    );
  }
}

class _LetterKey extends StatelessWidget {
  final String letter;
  final Color color;
  final Color textColor;
  final bool enabled;
  final VoidCallback onTap;

  const _LetterKey({
    required this.letter,
    required this.color,
    required this.textColor,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Text(
              letter,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackspaceKey extends StatelessWidget {
  final VoidCallback onTap;
  const _BackspaceKey({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: AppColors.keyDefault,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: const Icon(Icons.backspace_outlined, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
