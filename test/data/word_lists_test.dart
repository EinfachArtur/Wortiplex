import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/game/game_session.dart';
import 'package:wortiplex/domain/game/word_validator.dart';
import 'package:wortiplex/domain/models/game_mode.dart';
import 'package:wortiplex/domain/models/language.dart';
import 'package:wortiplex/domain/models/letter_state.dart';
import 'package:wortiplex/domain/models/round.dart';

class _Lists {
  final Set<String> solutions;
  final Set<String> valid;
  _Lists(this.solutions, this.valid);
}

_Lists load(String code) {
  final json = jsonDecode(File('assets/words/${code}_5.json').readAsStringSync()) as Map<String, dynamic>;
  return _Lists(
    (json['solutions'] as List).cast<String>().toSet(),
    (json['valid_guesses'] as List).cast<String>().toSet(),
  );
}

void main() {
  const alphabets = {
    'de': 'ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ',
    'en': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    'ru': 'АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ',
    // French/Italian/Spanish words are stored with accents folded to their
    // plain Latin letter, so they share the English A-Z keyboard.
    'fr': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    'it': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    'es': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  };

  for (final code in alphabets.keys) {
    group('word list $code', () {
      final lists = load(code);
      final all = {...lists.solutions, ...lists.valid};

      test('has a large enough dictionary', () {
        expect(lists.solutions.length, greaterThan(1000));
        expect(all.length, greaterThan(5000));
      });

      test('every word is 5 uppercase letters from the keyboard alphabet', () {
        final bad = all.where((w) => w.length != 5 || w.split('').any((c) => !alphabets[code]!.contains(c)));
        expect(bad, isEmpty);
      });

      test('solutions and extra guesses do not overlap', () {
        expect(lists.solutions.intersection(lists.valid), isEmpty);
      });
    });
  }

  test('German: HALLO is a valid guess and gets coloured against a solution', () {
    final de = load('de');
    final session = GameSession(validator: WordValidator(solutions: de.solutions, validGuesses: de.valid));
    final round = Round(
      id: 'r',
      mode: GameMode.classic,
      language: Language.de,
      solutionWord: 'HELLE',
      startedAt: DateTime(2024),
    );

    final outcome = session.submitGuess(round, 'HALLO');
    expect(outcome, isA<GuessAccepted>());

    final states = (outcome as GuessAccepted).round.guesses.single.evaluation.map((g) => g.state).toList();
    // H correct, A absent, L correct, L correct, O absent
    expect(states, [
      LetterState.correct,
      LetterState.absent,
      LetterState.correct,
      LetterState.correct,
      LetterState.absent,
    ]);
  });

  test('French, Italian and Spanish have real common words as valid guesses', () {
    final fr = load('fr');
    expect(fr.solutions.union(fr.valid), containsAll(['MERCI', 'CHIEN', 'TABLE']));

    final it = load('it');
    expect(it.solutions.union(it.valid), containsAll(['AMORE', 'NOTTE', 'GATTO']));

    final es = load('es');
    expect(es.solutions.union(es.valid), containsAll(['AMIGO', 'PERRO', 'LIBRO']));
  });
}
