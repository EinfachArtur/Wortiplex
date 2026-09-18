import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/economy/coin_ledger.dart';
import 'package:wortiplex/domain/economy/coin_transaction.dart';

void main() {
  test('earn increases balance and records a transaction', () {
    const ledger = CoinLedger(balance: 0);
    final updated = ledger.earn(
      amount: 5,
      reason: CoinTransactionReason.roundReward,
      transactionId: 't1',
    );
    expect(updated.balance, 5);
    expect(updated.history.single.amount, 5);
  });

  test('spend decreases balance when affordable', () {
    const ledger = CoinLedger(balance: 200);
    final updated = ledger.spend(
      amount: 150,
      reason: CoinTransactionReason.hintPurchase,
      transactionId: 't1',
    );
    expect(updated.balance, 50);
  });

  test('spend throws when balance is insufficient', () {
    const ledger = CoinLedger(balance: 100);
    expect(
      () => ledger.spend(amount: 150, reason: CoinTransactionReason.hintPurchase, transactionId: 't1'),
      throwsA(isA<InsufficientCoinsException>()),
    );
  });

  test('canAfford reflects current balance', () {
    const ledger = CoinLedger(balance: 100);
    expect(ledger.canAfford(100), isTrue);
    expect(ledger.canAfford(101), isFalse);
  });
}
