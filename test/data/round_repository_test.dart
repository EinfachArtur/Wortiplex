import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/data/repositories/round_repository.dart';
import 'package:wortiplex/domain/models/game_mode.dart';
import 'package:wortiplex/domain/models/language.dart';
import 'package:wortiplex/domain/models/letter_state.dart';
import 'package:wortiplex/domain/models/round.dart';

void main() {
  group('Round serialization & repository', () {
    test('round toMap and fromMap round-trip preserves state', () {
      final round = Round(
        id: 'test_round_1',
        mode: GameMode.classic,
        language: Language.de,
        solutionWord: 'APFEL',
        startedAt: DateTime(2026, 1, 1, 12, 0),
        guesses: const [
          Guess(
            word: 'AMPEL',
            evaluation: [
              LetterGuess('A', LetterState.correct),
              LetterGuess('M', LetterState.absent),
              LetterGuess('P', LetterState.correct),
              LetterGuess('E', LetterState.correct),
              LetterGuess('L', LetterState.correct),
            ],
          ),
        ],
        disabledLetters: const {'M', 'X'},
        revealedHints: const {0: 'A'},
        extraAttempts: 1,
      );

      final map = round.toMap();
      final restored = Round.fromMap(map);

      expect(restored.id, round.id);
      expect(restored.mode, round.mode);
      expect(restored.language, round.language);
      expect(restored.solutionWord, round.solutionWord);
      expect(restored.guesses.length, 1);
      expect(restored.guesses.first.word, 'AMPEL');
      expect(restored.guesses.first.evaluation[0].state, LetterState.correct);
      expect(restored.guesses.first.evaluation[1].state, LetterState.absent);
      expect(restored.disabledLetters, {'M', 'X'});
      expect(restored.revealedHints, {0: 'A'});
      expect(restored.extraAttempts, 1);
    });

    test('HiveRoundRepository in-memory fallback saves and loads active round', () async {
      final repo = HiveRoundRepository();
      const key = 'classic_de';

      final round = Round(
        id: 'round_123',
        mode: GameMode.classic,
        language: Language.de,
        solutionWord: 'STERN',
        startedAt: DateTime.now(),
      );

      await repo.saveActiveRound(key, round);
      final loaded = await repo.loadActiveRound(key);

      expect(loaded, isNotNull);
      expect(loaded!.solutionWord, 'STERN');

      await repo.clearActiveRound(key);
      final cleared = await repo.loadActiveRound(key);
      expect(cleared, isNull);
    });
  });
}
