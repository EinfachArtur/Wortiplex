import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/economy_config.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/economy/coin_ledger.dart';
import '../../domain/economy/coin_transaction.dart';
import '../../domain/economy/daily_reward.dart';
import '../../domain/economy/monthly_prizes.dart';
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

  Future<void> recordDailyResult(Language language, DateTime date, {required bool won}) async {
    final profile = state.valueOrNull;
    if (profile == null) return;
    await _persist(profile.copyWith(
      dailyHistory: profile.dailyHistory.withResult(language, date, won: won),
    ));
  }

  bool hasCompletedDailyToday(Language language) {
    final profile = state.valueOrNull;
    if (profile == null) return false;
    return profile.dailyHistory.hasPlayed(language, DateTime.now());
  }

  /// Returns the coins granted, or null if the tier isn't reached / already claimed.
  Future<int?> claimMonthlyPrize(Language language, int year, int month, int tierIndex) async {
    final profile = state.valueOrNull;
    if (profile == null) return null;
    final prizes = EconomyConfig.monthlyPrizes;
    final key = MonthlyPrizes.claimKey(language.code, year, month, tierIndex);
    final wins = profile.dailyHistory.winsInMonth(language, year, month);
    if (!prizes.isReached(tierIndex, wins) || profile.claimedMonthlyPrizes.contains(key)) return null;

    final coins = prizes.tiers[tierIndex].coins;
    final ledger = CoinLedger(balance: profile.coins).earn(
      amount: coins,
      reason: CoinTransactionReason.monthlyPrize,
      transactionId: _nextTxId(),
    );
    await _persist(profile.copyWith(
      coins: ledger.balance,
      claimedMonthlyPrizes: {...profile.claimedMonthlyPrizes, key},
    ));
    return coins;
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

  bool isFreeSpinAvailable() {
    final profile = state.valueOrNull;
    if (profile == null) return false;
    return _spinWheel.isFreeSpinAvailable(profile.lastSpinAt);
  }

  /// Spins that cost nothing right now: today's free spin plus won tickets.
  int freeSpinsAvailable() {
    final profile = state.valueOrNull;
    if (profile == null) return 0;
    return (isFreeSpinAvailable() ? 1 : 0) + profile.spinTickets;
  }

  /// Phase 1 of a spin: pays for it (daily free spin, then a ticket, then
  /// coins) and picks the outcome. The prize is only granted by
  /// [grantSpinPrize] once the wheel has stopped, so the HUD does not spoil it.
  /// Returns null if the player can't afford a spin.
  Future<SpinResult?> beginSpin() async {
    final profile = state.valueOrNull;
    if (profile == null) return null;

    if (_spinWheel.isFreeSpinAvailable(profile.lastSpinAt)) {
      await _persist(profile.copyWith(lastSpinAt: DateTime.now()));
    } else if (profile.spinTickets > 0) {
      await _persist(profile.copyWith(spinTickets: profile.spinTickets - 1));
    } else {
      final paid = await spendCoins(EconomyConfig.spinCost, CoinTransactionReason.spinPurchase);
      if (!paid) return null;
    }
    return _spinWheel.spin();
  }

  Future<void> grantSpinPrize(SpinPrize prize) async {
    final profile = state.valueOrNull;
    if (profile == null) return;
    switch (prize.kind) {
      case PrizeKind.coins:
        final ledger = CoinLedger(balance: profile.coins).earn(
          amount: prize.amount,
          reason: CoinTransactionReason.spinWheelReward,
          transactionId: _nextTxId(),
        );
        await _persist(profile.copyWith(coins: ledger.balance));
      case PrizeKind.hint:
        await _persist(profile.copyWith(hintTokens: profile.hintTokens + prize.amount));
      case PrizeKind.strikeout:
        await _persist(profile.copyWith(strikeoutTokens: profile.strikeoutTokens + prize.amount));
      case PrizeKind.skip:
        await _persist(profile.copyWith(skipsAvailable: profile.skipsAvailable + prize.amount));
      case PrizeKind.spin:
        await _persist(profile.copyWith(spinTickets: profile.spinTickets + prize.amount));
    }
  }

  Future<bool> useHintToken() async {
    final profile = state.valueOrNull;
    if (profile == null || profile.hintTokens <= 0) return false;
    await _persist(profile.copyWith(hintTokens: profile.hintTokens - 1));
    return true;
  }

  Future<bool> useStrikeoutToken() async {
    final profile = state.valueOrNull;
    if (profile == null || profile.strikeoutTokens <= 0) return false;
    await _persist(profile.copyWith(strikeoutTokens: profile.strikeoutTokens - 1));
    return true;
  }
}
