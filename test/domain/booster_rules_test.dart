import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/economy/booster_rules.dart';
import 'package:wortiplex/domain/game/game_session.dart';
import 'package:wortiplex/domain/game/word_validator.dart';
import 'package:wortiplex/domain/models/game_mode.dart';
import 'package:wortiplex/domain/models/language.dart';
import 'package:wortiplex/domain/models/letter_state.dart';
import 'package:wortiplex/domain/models/round.dart';

void main() {
  group('BoosterRules - revealHint', () {
    const rules = BoosterRules();

    test('reveals unsolved letter and never repeats already hinted positions', () {
      var round = Round(
        id: 'r1',
        mode: GameMode.classic,
        language: Language.de,
        solutionWord: 'TRAUM',
        startedAt: DateTime.now(),
      );

      final hintedPositions = <int>{};
      for (var i = 0; i < 5; i++) {
        final hint = rules.revealHint(round);
        expect(hintedPositions.contains(hint.position), isFalse);
        expect(hint.letter, round.solutionWord[hint.position]);
        hintedPositions.add(hint.position);
        round = round.copyWith(
          revealedHints: {...round.revealedHints, hint.position: hint.letter},
        );
      }

      expect(hintedPositions, {0, 1, 2, 3, 4});
      expect(() => rules.revealHint(round), throwsStateError);
    });

    test('does not hint letters already solved in previous guesses', () {
      final session = GameSession(
        validator: WordValidator(solutions: {'TRAUM'}, validGuesses: {'TRAMP'}),
      );
      var round = Round(
        id: 'r2',
        mode: GameMode.classic,
        language: Language.de,
        solutionWord: 'TRAUM',
        startedAt: DateTime.now(),
      );

      final outcome = session.submitGuess(round, 'TRAMP') as GuessAccepted;
      round = outcome.round;
      // 'T', 'R', 'A', 'M' are in TRAMP -> T(0)=correct, R(1)=correct, A(2)=correct, M(3)=present, P(4)=absent
      // Unsolved correct positions are 3 ('U') and 4 ('M')

      final hint1 = rules.revealHint(round);
      expect(hint1.position, isIn([3, 4]));
      round = round.copyWith(
        revealedHints: {...round.revealedHints, hint1.position: hint1.letter},
      );

      final hint2 = rules.revealHint(round);
      expect(hint2.position, isIn([3, 4]));
      expect(hint2.position, isNot(hint1.position));
    });
  });

  group('GameSession - keyboardStates with hints', () {
    test('marks hinted letters as correct on the keyboard', () {
      final session = GameSession(
        validator: WordValidator(solutions: {'TRAUM'}, validGuesses: {'TRAUM'}),
      );
      final round = Round(
        id: 'r3',
        mode: GameMode.classic,
        language: Language.de,
        solutionWord: 'TRAUM',
        startedAt: DateTime.now(),
        revealedHints: {3: 'U'},
      );

      final states = session.keyboardStates(round);
      expect(states['U'], LetterState.correct);
    });
  });

  group('BoosterRules - canStrikeOut & canHint', () {
    const rules = BoosterRules();

    test('canStrikeOut returns true when eligible letters remain and false when exhausted', () {
      const alphabet = ['A', 'B', 'C'];
      final round = Round(
        id: 'r4',
        mode: GameMode.classic,
        language: Language.de,
        solutionWord: 'A',
        startedAt: DateTime.now(),
      );

      // 'B' and 'C' are candidates
      expect(rules.canStrikeOut(round, alphabet: alphabet), isTrue);

      final roundWithBDisabled = round.copyWith(disabledLetters: {'B'});
      expect(rules.canStrikeOut(roundWithBDisabled, alphabet: alphabet), isTrue);

      final roundWithAllDisabled = round.copyWith(disabledLetters: {'B', 'C'});
      expect(rules.canStrikeOut(roundWithAllDisabled, alphabet: alphabet), isFalse);
      expect(rules.pickLetterToStrikeOut(roundWithAllDisabled, alphabet: alphabet), isNull);
    });

    test('canHint returns true until all positions are hinted or solved', () {
      final round = Round(
        id: 'r5',
        mode: GameMode.classic,
        language: Language.de,
        solutionWord: 'AB',
        startedAt: DateTime.now(),
      );

      expect(rules.canHint(round), isTrue);

      final roundHint1 = round.copyWith(revealedHints: {0: 'A'});
      expect(rules.canHint(roundHint1), isTrue);

      final roundHint2 = roundHint1.copyWith(revealedHints: {0: 'A', 1: 'B'});
      expect(rules.canHint(roundHint2), isFalse);
    });
  });
}
