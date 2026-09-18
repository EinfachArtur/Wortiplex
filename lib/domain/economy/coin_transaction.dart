enum CoinTransactionReason {
  roundReward,
  hintPurchase,
  letterStrikeoutPurchase,
  skipPurchase,
  iapPurchase,
  adReward,
  subscriptionBonus,
  dailyLoginBonus,
  spinWheelReward,
  spinPurchase,
  monthlyPrize,
  extraAttemptPurchase,
}

class CoinTransaction {
  final String id;
  final DateTime timestamp;
  final int amount; // positive = earned, negative = spent
  final CoinTransactionReason reason;

  const CoinTransaction({
    required this.id,
    required this.timestamp,
    required this.amount,
    required this.reason,
  });
}
