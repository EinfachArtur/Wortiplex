import 'dart:async';

enum PurchaseOutcome { success, cancelled, failed, pending }

class AppPurchaseResult {
  final String productId;
  final PurchaseOutcome outcome;
  final String? errorMessage;

  const AppPurchaseResult({
    required this.productId,
    required this.outcome,
    this.errorMessage,
  });
}

/// Abstract IAP service interface used across Wortiplex.
abstract class IapService {
  Stream<AppPurchaseResult> get purchaseStream;
  Future<void> initialize();
  Future<void> buyConsumable(String productId);
  Future<void> buyNonConsumable(String productId);
  Future<void> restorePurchases();
  void dispose();
}
