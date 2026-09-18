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
  final VoidCallback onEnter;
  final VoidCallback onBackspace;

  const VirtualKeyboard({
    super.key,
    required this.language,
    required this.letterStates,
    required this.disabledLetters,
    required this.onLetter,
    required this.onEnter,
    required this.onBackspace,
  });

  Color _keyColor(String letter) {
    if (disabledLetters.contains(letter)) return AppColors.absent.withValues(alpha: 0.4);
    final state = letterStates[letter];
    return switch (state) {
      LetterState.correct => AppColors.correct,
      LetterState.present => AppColors.present,
      LetterState.absent => AppColors.absent,
      _ => AppColors.keyDefault,
    };
  }

  Color _textColor(String letter) {
    final state = letterStates[letter];
    final isDisabled = disabledLetters.contains(letter);
    if (isDisabled || state != null) return Colors.white;
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _layouts[language]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (i == rows.length - 1) _ActionKey(label: 'ENTER', onTap: onEnter, flex: 3),
                for (final letter in rows[i].split(''))
                  _LetterKey(
                    letter: letter,
                    color: _keyColor(letter),
                    textColor: _textColor(letter),
                    enabled: !disabledLetters.contains(letter),
                    onTap: () => onLetter(letter),
                  ),
                if (i == rows.length - 1) _ActionKey(label: '⌫', onTap: onBackspace, flex: 2),
              ],
            ),
          ),
      ],
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
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 30,
            height: 44,
            alignment: Alignment.center,
            child: Text(
              letter,
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final int flex;

  const _ActionKey({required this.label, required this.onTap, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: AppColors.keyDefault,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 22.0 * flex,
            height: 44,
            alignment: Alignment.center,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ),
      ),
    );
  }
}
