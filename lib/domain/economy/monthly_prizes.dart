class MonthlyPrizeTier {
  final int wins;
  final int coins;
  const MonthlyPrizeTier(this.wins, this.coins);
}

/// Monthly milestone rewards for daily-puzzle wins (bronze / silver / gold).
class MonthlyPrizes {
  final List<MonthlyPrizeTier> tiers;

  const MonthlyPrizes(this.tiers);

  static String claimKey(String languageCode, int year, int month, int tierIndex) =>
      '${languageCode}_$year-${month.toString().padLeft(2, '0')}_$tierIndex';

  bool isReached(int tierIndex, int wins) => wins >= tiers[tierIndex].wins;

  int get maxWins => tiers.last.wins;

  /// 0..1 progress towards a single tier.
  double tierProgress(int tierIndex, int wins) => (wins / tiers[tierIndex].wins).clamp(0.0, 1.0);
}
