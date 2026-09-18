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

  /// Position of tier [index]'s marker along the bar (0..1): markers sit in
  /// the middle of equal segments, so a medal fits above each of them.
  double markerPosition(int index) => (index + 0.5) / tiers.length;

  /// 0..1 position of the progress knob. It travels from the start to the
  /// first marker for the first tier's wins, on to the next marker for the
  /// next tier, and stops at the last marker.
  double progress(int wins) {
    if (wins <= 0) return 0;
    var previousWins = 0;
    var previousPos = 0.0;
    for (var i = 0; i < tiers.length; i++) {
      final pos = markerPosition(i);
      if (wins <= tiers[i].wins) {
        final within = (wins - previousWins) / (tiers[i].wins - previousWins);
        return previousPos + (pos - previousPos) * within;
      }
      previousWins = tiers[i].wins;
      previousPos = pos;
    }
    return previousPos;
  }
}
