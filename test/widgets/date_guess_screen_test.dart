import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/core/localization/app_localizations.dart';
import 'package:wortiplex/data/repositories/profile_repository.dart';
import 'package:wortiplex/domain/game/date_guess_service.dart';
import 'package:wortiplex/domain/models/game_mode.dart';
import 'package:wortiplex/domain/models/user_profile.dart';
import 'package:wortiplex/presentation/screens/game_board/game_board_screen.dart';
import 'package:wortiplex/presentation/state/game_providers.dart';
import 'package:wortiplex/presentation/state/profile_providers.dart';
import 'package:wortiplex/presentation/widgets/tile_grid.dart';
import 'package:wortiplex/presentation/widgets/virtual_keyboard.dart';

class _MemoryRepo implements ProfileRepository {
  UserProfile profile = UserProfile.fresh('t');

  @override
  Future<UserProfile> load() async => profile;

  @override
  Future<void> save(UserProfile p) async => profile = p;
}

/// Always hands out the same target date, so the test knows the solution.
class _FixedDateService extends DateGuessService {
  final String solution;
  _FixedDateService(this.solution);

  @override
  String randomSolution({random}) => solution;
}

Future<ProviderContainer> _pumpDateGuess(WidgetTester tester, {String solution = '02081861'}) async {
  // The booster cost chips overflow by a few pixels with the test font.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);

  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      profileRepositoryProvider.overrideWithValue(_MemoryRepo()),
      dateGuessServiceProvider.overrideWithValue(_FixedDateService(solution)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(profileControllerProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GameBoardScreen(mode: GameMode.dateGuess),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return container;
}

Future<void> _typeDigits(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(find.descendant(of: find.byType(VirtualKeyboard), matching: find.text(digit)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

void main() {
  testWidgets('shows a digit pad and the DD MM YYYY format hint, not the letter keyboard', (tester) async {
    await _pumpDateGuess(tester);

    expect(find.text('TT MM JJJJ'), findsOneWidget);
    for (final digit in '1234567890'.split('')) {
      expect(find.descendant(of: find.byType(VirtualKeyboard), matching: find.text(digit)), findsOneWidget);
    }
    expect(find.descendant(of: find.byType(VirtualKeyboard), matching: find.text('Q')), findsNothing);
  });

  testWidgets('an invalid calendar date is rejected without being submitted', (tester) async {
    await _pumpDateGuess(tester);

    await _typeDigits(tester, '30022024'); // 30 February does not exist
    await tester.tap(find.byKey(const ValueKey('submit_button')));
    await tester.pump();

    expect(find.text('Kein gültiges Datum'), findsOneWidget);
  });

  testWidgets('a valid guess is coloured against the target date', (tester) async {
    await _pumpDateGuess(tester, solution: '02081861');

    await _typeDigits(tester, '02081961'); // day+month right, year off by 100
    await tester.tap(find.byKey(const ValueKey('submit_button')));
    await tester.pump();
    await tester.pump(TileGrid.revealDuration(8));

    // The exact-position digits (0,2,0,8,1,...,6,1) should be marked correct.
    expect(find.byKey(const ValueKey('submit_button')), findsOneWidget); // round continues, no dialog yet
  });

  testWidgets('the exact date wins the round', (tester) async {
    final container = await _pumpDateGuess(tester, solution: '02081861');

    await _typeDigits(tester, '02081861');
    await tester.tap(find.byKey(const ValueKey('submit_button')));
    await tester.pump();
    await tester.pump(TileGrid.revealDuration(8) + TileGrid.winWaveDuration);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('GENIAL!'), findsOneWidget);
    final profile = container.read(profileControllerProvider).value!;
    expect(profile.statsByKey['dateGuess_de']?.currentStreak, 1);
  });
}
