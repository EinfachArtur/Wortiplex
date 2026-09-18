import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/config/economy_config.dart';

enum PurchaseOutcome { success, cancelled, failed, pending }

class PurchaseResult {
  final String productId;
  final PurchaseOutcome outcome;
  const PurchaseResult({required this.productId, required this.outcome});
}

/// Wraps `in_app_purchase` for consumables (coin packages), the lifetime
/// "remove ads" non-consumable, and subscription products. Kept behind an
/// interface so the UI and coin/subscription logic never talk to the store
/// plugin directly.
abstract class IapService {
  Stream<PurchaseResult> get purchaseStream;
  Future<void> initialize();
  Future<List<ProductDetails>> queryProducts(Set<String> productIds);
  Future<void> buyConsumable(String productId);
  Future<void> buyNonConsumable(String productId);
  Future<void> restorePurchases();
  void dispose();
}

class InAppPurchaseService implements IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final _controller = StreamController<PurchaseResult>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  Stream<PurchaseResult> get purchaseStream => _controller.stream;

  static Set<String> get allProductIds => {
        ...EconomyConfig.coinPackages.map((p) => p.productId),
        EconomyConfig.removeAdsProductId,
        EconomyConfig.subscriptionMonthlyId,
        EconomyConfig.subscriptionYearlyId,
        EconomyConfig.starterPackProductId,
      };

  @override
  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdates, onError: (_) {});
  }

  void _onPurchaseUpdates(List<PurchaseDetails> updates) {
    for (final purchase in updates) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _controller.add(PurchaseResult(productId: purchase.productID, outcome: PurchaseOutcome.pending));
          break;
        case PurchaseStatus.error:
          _controller.add(PurchaseResult(productId: purchase.productID, outcome: PurchaseOutcome.failed));
          break;
        case PurchaseStatus.canceled:
          _controller.add(PurchaseResult(productId: purchase.productID, outcome: PurchaseOutcome.cancelled));
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _controller.add(PurchaseResult(productId: purchase.productID, outcome: PurchaseOutcome.success));
          break;
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> productIds) async {
    final response = await _iap.queryProductDetails(productIds);
    return response.productDetails;
  }

  @override
  Future<void> buyConsumable(String productId) async {
    final products = await queryProducts({productId});
    if (products.isEmpty) return;
    final param = PurchaseParam(productDetails: products.first);
    await _iap.buyConsumable(purchaseParam: param);
  }

  @override
  Future<void> buyNonConsumable(String productId) async {
    final products = await queryProducts({productId});
    if (products.isEmpty) return;
    final param = PurchaseParam(productDetails: products.first);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
