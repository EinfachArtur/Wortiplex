import 'coin_transaction.dart';

class InsufficientCoinsException implements Exception {
  final int balance;
  final int required;
  InsufficientCoinsException({required this.balance, required this.required});
}

/// Pure bookkeeping for the coin balance. Holds no I/O — callers are
/// responsible for persisting the resulting balance/transactions.
class CoinLedger {
  final int balance;
  final List<CoinTransaction> history;

  const CoinLedger({required this.balance, this.history = const []});

  CoinLedger earn({
    required int amount,
    required CoinTransactionReason reason,
    required String transactionId,
    DateTime? at,
  }) {
    assert(amount > 0);
    final tx = CoinTransaction(
      id: transactionId,
      timestamp: at ?? DateTime.now(),
      amount: amount,
      reason: reason,
    );
    return CoinLedger(balance: balance + amount, history: [...history, tx]);
  }

  CoinLedger spend({
    required int amount,
    required CoinTransactionReason reason,
    required String transactionId,
    DateTime? at,
  }) {
    assert(amount > 0);
    if (balance < amount) {
      throw InsufficientCoinsException(balance: balance, required: amount);
    }
    final tx = CoinTransaction(
      id: transactionId,
      timestamp: at ?? DateTime.now(),
      amount: -amount,
      reason: reason,
    );
    return CoinLedger(balance: balance - amount, history: [...history, tx]);
  }

  bool canAfford(int amount) => balance >= amount;
}
