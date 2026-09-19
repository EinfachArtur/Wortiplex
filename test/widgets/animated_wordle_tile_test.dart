import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/models/letter_state.dart';
import 'package:wortiplex/presentation/widgets/animated_wordle_tile.dart';

Widget _host(String letter) => MaterialApp(
      home: Scaffold(
        body: Center(child: AnimatedWordleTile(key: const ValueKey('tile'), letter: letter, state: LetterState.unknown)),
      ),
    );

void main() {
  testWidgets('a typed letter drops in from above and settles in the middle of the tile', (tester) async {
    await tester.pumpWidget(_host(''));
    final tileCenter = tester.getCenter(find.byType(AnimatedContainer));

    await tester.pumpWidget(_host('A'));
    await tester.pump(const Duration(milliseconds: 30));
    final falling = tester.getCenter(find.text('A'));
    expect(falling.dy, lessThan(tileCenter.dy - 4), reason: 'the letter starts above its final position');

    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getCenter(find.text('A')).dy, closeTo(tileCenter.dy, 0.5));
  });

  testWidgets('the falling letter fades in', (tester) async {
    await tester.pumpWidget(_host(''));
    await tester.pumpWidget(_host('A'));
    await tester.pump(const Duration(milliseconds: 20));

    final opacity = tester.widget<Opacity>(find.ancestor(of: find.text('A'), matching: find.byType(Opacity)).first);
    expect(opacity.opacity, lessThan(1.0));

    await tester.pump(const Duration(milliseconds: 500));
    final settled = tester.widget<Opacity>(find.ancestor(of: find.text('A'), matching: find.byType(Opacity)).first);
    expect(settled.opacity, 1.0);
  });

  testWidgets('replacing a letter makes the new one drop in again', (tester) async {
    await tester.pumpWidget(_host('A'));
    await tester.pump(const Duration(milliseconds: 500));
    final rest = tester.getCenter(find.text('A')).dy;

    await tester.pumpWidget(_host('B'));
    await tester.pump(const Duration(milliseconds: 30));
    expect(tester.getCenter(find.text('B')).dy, lessThan(rest - 4));
  });
}
