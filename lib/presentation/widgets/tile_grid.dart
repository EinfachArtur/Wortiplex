import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/letter_state.dart';
import '../../domain/models/round.dart';

class TileGrid extends StatelessWidget {
  final Round round;
  final String currentInput;

  const TileGrid({super.key, required this.round, required this.currentInput});

  @override
  Widget build(BuildContext context) {
    final wordLength = round.solutionWord.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < round.maxAttempts; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _buildRow(row, wordLength),
          ),
      ],
    );
  }

  Widget _buildRow(int row, int wordLength) {
    final isPastGuess = row < round.guesses.length;
    final isCurrentRow = row == round.guesses.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var col = 0; col < wordLength; col++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _Tile(
              letter: isPastGuess
                  ? round.guesses[row].evaluation[col].letter
                  : (isCurrentRow && col < currentInput.length ? currentInput[col] : ''),
              state: isPastGuess ? round.guesses[row].evaluation[col].state : LetterState.unknown,
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String letter;
  final LetterState state;

  const _Tile({required this.letter, required this.state});

  Color _bgColor() => switch (state) {
        LetterState.correct => AppColors.correct,
        LetterState.present => AppColors.present,
        LetterState.absent => AppColors.absent,
        LetterState.unknown => Colors.transparent,
      };

  Color _borderColor() =>
      state == LetterState.unknown ? AppColors.tileBorder : _bgColor();

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _bgColor(),
        border: Border.all(color: _borderColor(), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: state == LetterState.unknown ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }
}
