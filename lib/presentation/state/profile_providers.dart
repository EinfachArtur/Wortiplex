import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/economy_config.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/economy/coin_ledger.dart';
import '../../domain/economy/coin_transaction.dart';
import '../../domain/economy/skip_refill.dart';
import '../../domain/models/game_stats.dart';
import '../../domain/models/language.dart';
import '../../domain/models/subscription_status.dart';
import '../../domain/models/user_profile.dart';

const _skipRefillCalculator = SkipRefillCalculator(
  maxAllowance: EconomyConfig.dailySkipAllowance,
  refillInterval: EconomyConfig.skipRefillInterval,
);

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return HiveProfileRepository();
});

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile>(ProfileController.new);

class ProfileController extends AsyncNotifier<UserProfile> {
  int _txCounter = 0;

  String _nextTxId() => 'tx_${DateTime.now().microsecondsSinceEpoch}_${_txCounter++}';

  @override
  Future<UserProfile> build() async {
    final repo = ref.read(profileRepositoryProvider);
    return repo.load();
  }

  Future<void> _persist(UserProfile profile) async {
    state = AsyncData(profile);
    await ref.read(profileRepositoryProvider).save(profile);
  }

  Future<void> setLanguage(Language language) async {
    final profile = state.valueOrNull;
    if (profile == null) return;
    await _persist(profile.copyWith(language: language));
  }

  Future<void> earnCoins(int amount, CoinTransactionReason reason) async {
    final profile = state.valueOrNull;
    if (profile == null) return;
    final ledger = CoinLedger(balance: profile.coins).earn(
      amount: amount,
      reason: reason,
      transactionId: _nextTxId(),
    );
    await _persist(profile.copyWith(coins: ledger.balance));
  }

  /// Returns true if the spend succeeded (sufficient balance).
  Future<bool> spendCoins(int amount, CoinTransactionReason reason) async {
    final profile = state.valueOrNull;
    if (profile == null) return false;
    if (profile.coins < amount) return false;
    final ledger = CoinLedger(balance: profile.coins).spend(
      amount: amount,
      reason: reason,
      transactionId: _nextTxId(),
    );
    await _persist(profile.copyWith(coins: ledger.balance));
    return true;
  }

  Future<void> recordRoundResult({
    required String mode,
    required Language language,
    required bool won,
    int? guessesUsed,
  }) async {
    final profile = state.valueOrNull;
    if (profile == null) return;
    final key = UserProfile.statsKey(mode, language);
    final currentStats = profile.statsByKey[key] ?? const GameStats();
    final updatedStats = currentStats.recordResult(won: won, guessesUsed: guessesUsed);
    final statsByKey = {...profile.statsByKey, key: updatedStats};

    final ledger = CoinLedger(balance: profile.coins).earn(
      amount: EconomyConfig.roundCompletionReward,
      reason: CoinTransactionReason.roundReward,
      transactionId: _nextTxId(),
    );

    await _persist(profile.copyWith(statsByKey: statsByKey, coins: ledger.balance));
  }

  Future<void> markDailyPuzzleCompleted(Language language) async {
    final profile = state.valueOrNull;
    if (profile == null) return;
    final map = {...profile.lastDailyPuzzleCompletedAt, language.code: DateTime.now()};
    await _persist(profile.copyWith(lastDailyPuzzleCompletedAt: map));
  }

  bool hasCompletedDailyToday(Language language) {
    final profile = state.valueOrNull;
    if (profile == null) return false;
    final last = profile.lastDailyPuzzleCompletedAt[language.code];
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year && last.month == now.month && last.day == now.day;
  }

  Future<void> applySubscriptionUpdate(SubscriptionStatus status) async {
    final profile = state.valueOrNull;
    if (profile == null) return;
    await _persist(profile.copyWith(subscription: status));
  }

  /// Applies any regenerated skip charges based on elapsed time. Safe to
  /// call on every profile load/screen entry; it is a no-op if nothing has
  /// regenerated yet.
  Future<void> refreshSkips() async {
    final profile = state.valueOrNull;
    if (profile == null) return;
    final refilled = _skipRefillCalculator.refill(
      SkipState(available: profile.skipsAvailable, refillStartedAt: profile.lastSkipRefillAt),
    );
    if (refilled.available == profile.skipsAvailable &&
        refilled.refillStartedAt == profile.lastSkipRefillAt) {
      return;
    }
    await _persist(profile.copyWith(
      skipsAvailable: refilled.available,
      lastSkipRefillAt: refilled.refillStartedAt,
      clearLastSkipRefillAt: refilled.refillStartedAt == null,
    ));
  }

  Future<bool> useSkip() async {
    await refreshSkips();
    final profile = state.valueOrNull;
    if (profile == null || profile.skipsAvailable <= 0) return false;
    final consumed = _skipRefillCalculator.consume(
      SkipState(available: profile.skipsAvailable, refillStartedAt: profile.lastSkipRefillAt),
    );
    await _persist(profile.copyWith(
      skipsAvailable: consumed.available,
      lastSkipRefillAt: consumed.refillStartedAt,
    ));
    return true;
  }
}
