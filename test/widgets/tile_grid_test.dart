import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/models/game_mode.dart';
import 'package:wortiplex/domain/models/language.dart';
import 'package:wortiplex/domain/models/letter_state.dart';
import 'package:wortiplex/domain/models/round.dart';
import 'package:wortiplex/presentation/widgets/tile_grid.dart';

Round _round({List<Guess> guesses = const [], RoundResult result = RoundResult.inProgress}) => Round(
      id: 'r',
      mode: GameMode.classic,
      language: Language.en,
      solutionWord: 'APPLE',
      startedAt: DateTime(2024),
      guesses: guesses,
      result: result,
    );

Guess _correctGuess() => Guess(
      word: 'APPLE',
      evaluation: [for (final c in 'APPLE'.split('')) LetterGuess(c, LetterState.correct)],
    );

Widget _host(Round round, {int shake = 0, List<String>? letters}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: TileGrid(round: round, currentLetters: letters ?? List.filled(5, ''), shakeCount: shake),
        ),
      ),
    );

// The drawn face sits inside every transform of the tile (hop, pop, flip),
// so its position and size reflect what the player actually sees.
Finder _face(int row, int col) =>
    find.descendant(of: find.byKey(ValueKey('tile_${row}_$col')), matching: find.byType(AnimatedContainer)).first;

Offset _tile(WidgetTester tester, int row, int col) => tester.getCenter(_face(row, col));

void main() {
  testWidgets('the current row wobbles when shakeCount increases and settles again', (tester) async {
    await tester.pumpWidget(_host(_round()));
    final rest = _tile(tester, 0, 0);

    await tester.pumpWidget(_host(_round(), shake: 1));
    await tester.pump(const Duration(milliseconds: 40));
    expect((_tile(tester, 0, 0).dx - rest.dx).abs(), greaterThan(1), reason: 'row should be displaced mid-shake');
    // Rows below the current one must not move.
    expect(_tile(tester, 1, 0).dx, closeTo(rest.dx, 0.01));

    await tester.pump(const Duration(milliseconds: 700));
    expect(_tile(tester, 0, 0).dx, closeTo(rest.dx, 0.01));
  });

  testWidgets('a winning row hops one tile after the other once it has flipped', (tester) async {
    await tester.pumpWidget(_host(_round()));
    final rest = _tile(tester, 0, 0);

    await tester.pumpWidget(_host(_round(guesses: [_correctGuess()], result: RoundResult.won)));
    await tester.pump(); // fires the zero-delay flip of the first tile

    // Flip (500ms) + small pause (80ms) starts the hop of column 0 ...
    await tester.pump(const Duration(milliseconds: 600));
    // ... and mid-hop the first tile is well above its resting place.
    await tester.pump(const Duration(milliseconds: 130));
    expect(_tile(tester, 0, 0).dy, lessThan(rest.dy - 5), reason: 'first tile should be in the air');
    // The last column has not started hopping yet: it is delayed by 4 * 250ms.
    expect((_tile(tester, 0, 4).dy - rest.dy).abs(), lessThan(1));

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(_tile(tester, 0, 0).dy, closeTo(rest.dy, 0.01));
    expect(_tile(tester, 0, 4).dy, closeTo(rest.dy, 0.01));
  });

  testWidgets('a typed letter pops from a smaller size back to normal', (tester) async {
    // getSize ignores transforms, so measure the drawn width through the corners.
    double drawnWidth() => 2 * (tester.getCenter(_face(0, 0)).dx - tester.getTopLeft(_face(0, 0)).dx);

    await tester.pumpWidget(_host(_round()));
    final normal = drawnWidth();

    await tester.pumpWidget(_host(_round(), letters: ['A', '', '', '', '']));
    await tester.pump(const Duration(milliseconds: 10));
    expect(drawnWidth(), lessThan(normal), reason: 'the pop starts smaller than the resting size');

    await tester.pump(const Duration(milliseconds: 600));
    expect(drawnWidth(), closeTo(normal, 0.01));
  });

  test('reveal duration covers the staggered flip of the whole row', () {
    expect(TileGrid.revealDuration(5), TileGrid.flipStagger * 4 + TileGrid.flipDuration);
  });
}
