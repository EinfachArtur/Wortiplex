import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/core/localization/app_localizations.dart';
import 'package:wortiplex/domain/models/game_mode.dart';
import 'package:wortiplex/domain/models/language.dart';
import 'package:wortiplex/domain/models/round.dart';
import 'package:wortiplex/presentation/widgets/game_result_dialog.dart';

Widget _host(Round round) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: GameResultDialog(
          round: round,
          streak: 0,
          onNextRound: () {},
        ),
      ),
    );

void main() {
  testWidgets('renders lost round with 8-character solution without overflow', (tester) async {
    final round = Round(
      id: 'test-8',
      mode: GameMode.daily,
      language: Language.de,
      solutionWord: '11042017',
      maxAttempts: 6,
      guesses: const [],
      result: RoundResult.lost,
      startedAt: DateTime.now(),
    );

    await tester.pumpWidget(_host(round));
    await tester.pumpAndSettle();

    expect(find.byType(GameResultDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders lost round with 5-letter word without overflow', (tester) async {
    final round = Round(
      id: 'test-5',
      mode: GameMode.classic,
      language: Language.de,
      solutionWord: 'TRAUM',
      maxAttempts: 6,
      guesses: const [],
      result: RoundResult.lost,
      startedAt: DateTime.now(),
    );

    await tester.pumpWidget(_host(round));
    await tester.pumpAndSettle();

    expect(find.byType(GameResultDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
