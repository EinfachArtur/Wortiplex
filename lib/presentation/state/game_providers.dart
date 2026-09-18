import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/economy_config.dart';
import '../../data/repositories/word_repository.dart';
import '../../domain/economy/booster_rules.dart';
import '../../domain/economy/coin_transaction.dart';
import '../../domain/game/game_session.dart';
import '../../domain/game/word_validator.dart';
import '../../domain/models/game_mode.dart';
import '../../domain/models/language.dart';
import '../../domain/models/round.dart';
import '../../services/daily_puzzle_service.dart';
import 'profile_providers.dart';

final wordRepositoryProvider = Provider<WordRepository>((ref) => AssetWordRepository());
final dailyPuzzleServiceProvider = Provider((ref) => const DailyPuzzleService());
final boosterRulesProvider = Provider((ref) => const BoosterRules());

const _alphabets = {
  Language.en: 'QWERTYUIOPASDFGHJKLZXCVBNM',
  Language.de: 'QWERTZUIOPÜASDFGHJKLÖÄYXCVBNM',
  Language.ru: 'ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ',
};

List<String> alphabetFor(Language language) => _alphabets[language]!.split('');

class GameParams {
  final GameMode mode;
  final Language language;

  /// Calendar day of a daily puzzle (time of day is ignored). Null for other modes.
  final DateTime? date;

  GameParams({required this.mode, required this.language, DateTime? date})
      : date = date == null ? null : DateTime(date.year, date.month, date.day);

  @override
  bool operator ==(Object other) =>
      other is GameParams && other.mode == mode && other.language == language && other.date == date;
  @override
  int get hashCode => Object.hash(mode, language, date);
}

final roundControllerProvider =
    AsyncNotifierProvider.family<RoundController, Round, GameParams>(RoundController.new);

class RoundController extends FamilyAsyncNotifier<Round, GameParams> {
  late WordList _wordList;
  late GameSession _gameSession;
  late WordValidator _validator;

  @override
  Future<Round> build(GameParams params) async {
    final repo = ref.read(wordRepositoryProvider);
    _wordList = await repo.loadWordList(params.language);
    _validator = WordValidator(
      solutions: _wordList.solutions.toSet(),
      validGuesses: _wordList.validGuesses.toSet(),
    );
    _gameSession = GameSession(validator: _validator);
    return _startNewRound(params);
  }

  Round _startNewRound(GameParams params) {
    String solution;
    if (params.mode == GameMode.daily) {
      final service = ref.read(dailyPuzzleServiceProvider);
      solution = service.solutionFor(
        language: params.language,
        solutionPool: _wordList.solutions,
        date: params.date ?? DateTime.now(),
      );
    } else {
      solution = _wordList.solutions[Random().nextInt(_wordList.solutions.length)];
    }
    return Round(
      id: '${params.mode.name}_${DateTime.now().microsecondsSinceEpoch}',
      mode: params.mode,
      language: params.language,
      solutionWord: solution.toUpperCase(),
      startedAt: DateTime.now(),
    );
  }

  GameSession _session() => _gameSession;

  bool isValidWord(String word) => _validator.isValid(word);

  Future<GuessOutcome> submitGuess(String word) async {
    final round = state.valueOrNull;
    if (round == null) return const GuessRejected(GuessRejectReason.roundAlreadyFinished);

    final outcome = _session().submitGuess(round, word);
    if (outcome is GuessAccepted) {
      state = AsyncData(outcome.round);
      if (outcome.round.isFinished) {
        final won = outcome.round.result == RoundResult.won;
        await ref.read(profileControllerProvider.notifier).recordRoundResult(
              mode: outcome.round.mode.name,
              language: outcome.round.language,
              won: won,
              guessesUsed: won ? outcome.round.attemptsUsed : null,
            );
        if (outcome.round.mode == GameMode.daily) {
          await ref.read(profileControllerProvider.notifier).recordDailyResult(
                outcome.round.language,
                arg.date ?? DateTime.now(),
                won: won,
              );
        }
      }
    }
    return outcome;
  }

  Map<String, dynamic> keyboardStates() {
    final round = state.valueOrNull;
    if (round == null) return {};
    return _session().keyboardStates(round);
  }

  Future<bool> newRound(GameParams params) async {
    final fresh = _startNewRound(params);
    state = AsyncData(fresh);
    return true;
  }

  Future<HintResult?> buyHint() async {
    final round = state.valueOrNull;
    if (round == null) return null;
    final profile = ref.read(profileControllerProvider.notifier);
    final affordable = await profile.useHintToken() ||
        await profile.spendCoins(EconomyConfig.hintCost, CoinTransactionReason.hintPurchase);
    if (!affordable) return null;
    final rules = ref.read(boosterRulesProvider);
    return rules.revealHint(round);
  }

  Future<String?> buyLetterStrikeout() async {
    final round = state.valueOrNull;
    if (round == null) return null;
    final profile = ref.read(profileControllerProvider.notifier);
    final affordable = await profile.useStrikeoutToken() ||
        await profile.spendCoins(EconomyConfig.letterStrikeoutCost, CoinTransactionReason.letterStrikeoutPurchase);
    if (!affordable) return null;
    final rules = ref.read(boosterRulesProvider);
    final letter = rules.pickLetterToStrikeOut(round, alphabet: alphabetFor(round.language));
    if (letter == null) return null;
    state = AsyncData(round.copyWith(disabledLetters: {...round.disabledLetters, letter}));
    return letter;
  }
}
