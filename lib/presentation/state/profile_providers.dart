import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/economy_config.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/economy/coin_ledger.dart';
import '../../domain/economy/coin_transaction.dart';
import '../../domain/economy/daily_reward.dart';
import '../../domain/economy/skip_refill.dart';
import '../../domain/economy/spin_wheel.dart';
import '../../domain/models/game_stats.dart';
import '../../domain/models/language.dart';
import '../../domain/models/subscription_status.dart';
import '../../domain/models/user_profile.dart';

const _skipRefillCalculator = SkipRefillCalculator(
  maxAllowance: EconomyConfig.dailySkipAllowance,
  refillInterval: EconomyConfig.skipRefillInterval,
);

const _dailyLoginReward = DailyLoginReward(
  baseCoins: EconomyConfig.dailyLoginBaseCoins,
  streakBonusPerDay: EconomyConfig.dailyLoginStreakBonus,
  maxStreakBonusDays: EconomyConfig.dailyLoginMaxStreakDays,
);

const _spinWheel = SpinWheel();

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

  bool isDailyLoginRewardAvailable() {
    final profile = state.valueOrNull;
    if (profile == null) return false;
    return _dailyLoginReward.isAvailable(profile.lastDailyLoginClaimedAt);
  }

  int nextDailyLoginCoins() {
    final profile = state.valueOrNull;
    if (profile == null) return EconomyConfig.dailyLoginBaseCoins;
    final streak = _dailyLoginReward.nextStreak(profile.dailyLoginStreak, profile.lastDailyLoginClaimedAt);
    return _dailyLoginReward.coinsForStreak(streak);
  }

  /// Returns the coins granted, or null if the reward was already claimed today.
  Future<int?> claimDailyLoginReward() async {
    final profile = state.valueOrNull;
    if (profile == null || !_dailyLoginReward.isAvailable(profile.lastDailyLoginClaimedAt)) {
      return null;
    }
    final now = DateTime.now();
    final streak = _dailyLoginReward.nextStreak(profile.dailyLoginStreak, profile.lastDailyLoginClaimedAt, now: now);
    final coins = _dailyLoginReward.coinsForStreak(streak);

    final ledger = CoinLedger(balance: profile.coins).earn(
      amount: coins,
      reason: CoinTransactionReason.dailyLoginBonus,
      transactionId: _nextTxId(),
    );
    await _persist(profile.copyWith(
      coins: ledger.balance,
      lastDailyLoginClaimedAt: now,
      dailyLoginStreak: streak,
    ));
    return coins;
  }

  bool isSpinAvailable() {
    final profile = state.valueOrNull;
    if (profile == null) return false;
    return _spinWheel.isAvailable(profile.lastSpinAt);
  }

  /// Returns the coins won, or null if today's spin was already used.
  Future<int?> spinWheel() async {
    final profile = state.valueOrNull;
    if (profile == null || !_spinWheel.isAvailable(profile.lastSpinAt)) return null;
    final outcome = _spinWheel.spin();
    final ledger = CoinLedger(balance: profile.coins).earn(
      amount: outcome.coins,
      reason: CoinTransactionReason.spinWheelReward,
      transactionId: _nextTxId(),
    );
    await _persist(profile.copyWith(coins: ledger.balance, lastSpinAt: DateTime.now()));
    return outcome.coins;
  }
}
