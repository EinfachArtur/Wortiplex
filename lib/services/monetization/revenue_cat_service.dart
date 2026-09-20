import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/revenue_cat_config.dart';
import 'iap_service.dart';

class RevenueCatService implements IapService {
  RevenueCatService();

  final _purchaseController = StreamController<AppPurchaseResult>.broadcast();
  final _customerInfoController = StreamController<CustomerInfo>.broadcast();

  String? _userId;
  bool _isInitialized = false;

  @override
  Stream<AppPurchaseResult> get purchaseStream => _purchaseController.stream;

  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  String? get userId => _userId;
  bool get isInitialized => _isInitialized;

  Future<String> getAppUserId() async {
    if (_userId != null && _userId!.isNotEmpty) {
      return _userId!;
    }
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString('local_user_id');
    if (storedId != null && storedId.isNotEmpty) {
      _userId = storedId;
      return storedId;
    }
    try {
      final id = await Purchases.appUserID;
      if (id.isNotEmpty) return id;
    } catch (_) {}
    return 'unknown';
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      final apiKey = RevenueCatConfig.apiKey;
      if (apiKey.isEmpty) {
        debugPrint('[RevenueCat] Kein API-Key konfiguriert.');
        return;
      }

      await Purchases.configure(PurchasesConfiguration(apiKey));
      debugPrint('[RevenueCat] Konfiguriert für ${Platform.operatingSystem} 🚀');

      // 1. Stabile lokale User-ID (wie in Party Clash)
      final prefs = await SharedPreferences.getInstance();
      var storedId = prefs.getString('local_user_id');
      if (storedId == null || storedId.isEmpty) {
        storedId = const Uuid().v4();
        await prefs.setString('local_user_id', storedId);
        debugPrint('[RevenueCat] Neue User-ID erstellt: $storedId');
      }
      _userId = storedId;

      // 2. LogIn vor Käufen
      try {
        final loginResult = await Purchases.logIn(_userId!);
        debugPrint('[RevenueCat] LogIn erfolgreich: ${_userId!} (created: ${loginResult.created})');
        _customerInfoController.add(loginResult.customerInfo);
      } catch (e) {
        debugPrint('[RevenueCat] Fehler bei logIn: $e');
      }

      // 3. Profil-Attribute indexieren
      try {
        await Purchases.setAttributes({'profile_created': 'true', 'app': 'wortiplex'});
      } catch (e) {
        debugPrint('[RevenueCat] Fehler bei setAttributes: $e');
      }

      // 4. CustomerInfo Listener
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        debugPrint('[RevenueCat] CustomerInfo aktualisiert: ${customerInfo.entitlements.active.keys}');
        _customerInfoController.add(customerInfo);
      });

      // 5. Initial CustomerInfo laden
      try {
        final info = await Purchases.getCustomerInfo();
        _customerInfoController.add(info);
      } catch (e) {
        debugPrint('[RevenueCat] Fehler beim Abrufen der CustomerInfo: $e');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[RevenueCat] Initialisierungsfehler: $e');
    }
  }

  /// Dynamische Offerings von RevenueCat abrufen (inkl. lokalisierter Preise)
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } on PlatformException catch (e) {
      debugPrint('[RevenueCat] Fehler beim Laden der Offerings: $e');
      return null;
    } catch (e) {
      debugPrint('[RevenueCat] Unerwarteter Fehler bei Offerings: $e');
      return null;
    }
  }

  /// Kauf eines RevenueCat Packages (z. B. aus Offerings)
  Future<AppPurchaseResult> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      _customerInfoController.add(purchaseResult.customerInfo);
      final result = AppPurchaseResult(
        productId: package.storeProduct.identifier,
        outcome: PurchaseOutcome.success,
      );
      _purchaseController.add(result);
      return result;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        final result = AppPurchaseResult(
          productId: package.storeProduct.identifier,
          outcome: PurchaseOutcome.cancelled,
        );
        _purchaseController.add(result);
        return result;
      }
      final result = AppPurchaseResult(
        productId: package.storeProduct.identifier,
        outcome: PurchaseOutcome.failed,
        errorMessage: e.message,
      );
      _purchaseController.add(result);
      return result;
    } catch (e) {
      final result = AppPurchaseResult(
        productId: package.storeProduct.identifier,
        outcome: PurchaseOutcome.failed,
        errorMessage: e.toString(),
      );
      _purchaseController.add(result);
      return result;
    }
  }

  /// Kauf über Product-ID (sucht das passende Package in den Offerings)
  @override
  Future<void> buyConsumable(String productId) async {
    await _buyById(productId);
  }

  @override
  Future<void> buyNonConsumable(String productId) async {
    await _buyById(productId);
  }

  Future<AppPurchaseResult> _buyById(String productId) async {
    try {
      final offerings = await getOfferings();
      Package? matchedPackage;

      if (offerings != null) {
        // Suche in aktuellem Offering
        for (final pkg in offerings.current?.availablePackages ?? <Package>[]) {
          if (pkg.storeProduct.identifier == productId || pkg.identifier == productId) {
            matchedPackage = pkg;
            break;
          }
        }
        // Falls nicht im current, suche in allen Offerings
        if (matchedPackage == null) {
          for (final offering in offerings.all.values) {
            for (final pkg in offering.availablePackages) {
              if (pkg.storeProduct.identifier == productId || pkg.identifier == productId) {
                matchedPackage = pkg;
                break;
              }
            }
            if (matchedPackage != null) break;
          }
        }
      }

      if (matchedPackage != null) {
        return await purchasePackage(matchedPackage);
      }

      // Fallback: StoreProduct direkt über ID kaufen
      final products = await Purchases.getProducts([productId]);
      if (products.isNotEmpty) {
        final purchaseResult = await Purchases.purchase(PurchaseParams.storeProduct(products.first));
        _customerInfoController.add(purchaseResult.customerInfo);
        final result = AppPurchaseResult(productId: productId, outcome: PurchaseOutcome.success);
        _purchaseController.add(result);
        return result;
      }

      final errorResult = AppPurchaseResult(
        productId: productId,
        outcome: PurchaseOutcome.failed,
        errorMessage: 'Produkt $productId im Store nicht gefunden.',
      );
      _purchaseController.add(errorResult);
      return errorResult;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      final outcome = errorCode == PurchasesErrorCode.purchaseCancelledError
          ? PurchaseOutcome.cancelled
          : PurchaseOutcome.failed;
      final result = AppPurchaseResult(
        productId: productId,
        outcome: outcome,
        errorMessage: e.message,
      );
      _purchaseController.add(result);
      return result;
    } catch (e) {
      final result = AppPurchaseResult(
        productId: productId,
        outcome: PurchaseOutcome.failed,
        errorMessage: e.toString(),
      );
      _purchaseController.add(result);
      return result;
    }
  }

  Future<List<StoreProduct>> queryProducts(Set<String> productIds) async {
    try {
      return await Purchases.getProducts(productIds.toList());
    } catch (e) {
      debugPrint('[RevenueCat] Fehler bei queryProducts: $e');
      return [];
    }
  }

  @override
  Future<CustomerInfo?> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      debugPrint('[RevenueCat] Restore erfolgreich: ${customerInfo.entitlements.active.keys}');
      _customerInfoController.add(customerInfo);

      // Falls aktive Entitlements vorhanden sind, success an Stream melden
      for (final entitlement in customerInfo.entitlements.active.values) {
        _purchaseController.add(
          AppPurchaseResult(productId: entitlement.productIdentifier, outcome: PurchaseOutcome.success),
        );
      }
      return customerInfo;
    } on PlatformException catch (e) {
      debugPrint('[RevenueCat] Restore fehlgeschlagen: $e');
      return null;
    } catch (e) {
      debugPrint('[RevenueCat] Unerwarteter Restore-Fehler: $e');
      return null;
    }
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('[RevenueCat] getCustomerInfo Fehler: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _purchaseController.close();
    _customerInfoController.close();
  }
}
