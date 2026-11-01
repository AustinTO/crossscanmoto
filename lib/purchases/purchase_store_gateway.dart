import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

enum StorePurchaseStatus { pending, purchased, restored, canceled, error }

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.nativeProduct,
  });

  final String id;
  final String title;
  final String description;
  final String price;
  final String currencyCode;
  final Object nativeProduct;
}

class StoreProductResult {
  const StoreProductResult({this.product, this.error});

  final StoreProduct? product;
  final String? error;
}

class StorePurchaseUpdate {
  const StorePurchaseUpdate({
    required this.productId,
    required this.status,
    required this.purchaseId,
    required this.serverVerificationData,
    required this.pendingCompletePurchase,
    required this.nativePurchase,
    this.errorMessage,
  });

  final String productId;
  final StorePurchaseStatus status;
  final String? purchaseId;
  final String serverVerificationData;
  final bool pendingCompletePurchase;
  final Object nativePurchase;
  final String? errorMessage;
}

abstract interface class PurchaseStoreGateway {
  Stream<List<StorePurchaseUpdate>> get purchaseStream;
  Future<bool> isAvailable();
  Future<StoreProductResult> queryProduct(String productId);
  Future<bool> buyNonConsumable(
    StoreProduct product, {
    required String accountBinding,
  });
  Future<void> restorePurchases({required String accountBinding});
  Future<void> completePurchase(StorePurchaseUpdate purchase);
}

/// Thin adapter over Flutter's endorsed StoreKit / Google Play plugin.
class InAppPurchaseStoreGateway implements PurchaseStoreGateway {
  InAppPurchaseStoreGateway({InAppPurchase? store})
    : _store = store ?? _safeInstance();

  static InAppPurchase? _safeInstance() {
    try {
      return InAppPurchase.instance;
    } catch (_) {
      return null;
    }
  }

  final InAppPurchase? _store;

  @override
  Stream<List<StorePurchaseUpdate>> get purchaseStream =>
      _store?.purchaseStream
          .map((purchases) => purchases.map(_mapPurchase).toList(growable: false)) ??
      const Stream.empty();

  @override
  Future<bool> isAvailable() async => _store?.isAvailable() ?? false;

  @override
  Future<StoreProductResult> queryProduct(String productId) async {
    final store = _store;
    if (store == null) {
      return const StoreProductResult(
        error: 'In-app purchases are unavailable on this environment.',
      );
    }
    final result = await store.queryProductDetails({productId});
    if (result.error != null) {
      return StoreProductResult(error: result.error!.message);
    }
    if (result.productDetails.isEmpty) {
      return const StoreProductResult(
        error: 'The configured store product is not available.',
      );
    }
    final detail = result.productDetails.firstWhere(
      (product) => product.id == productId,
      orElse: () =>
          throw StateError('Store returned an unexpected product identifier'),
    );
    return StoreProductResult(
      product: StoreProduct(
        id: detail.id,
        title: detail.title,
        description: detail.description,
        price: detail.price,
        currencyCode: detail.currencyCode,
        nativeProduct: detail,
      ),
    );
  }

  @override
  Future<bool> buyNonConsumable(
    StoreProduct product, {
    required String accountBinding,
  }) {
    final store = _store;
    if (store == null) return Future.value(false);
    final detail = product.nativeProduct;
    if (detail is! ProductDetails)
      throw ArgumentError('Invalid store product object');
    return store.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: detail,
        applicationUserName: accountBinding,
      ),
    );
  }

  @override
  Future<void> restorePurchases({required String accountBinding}) async =>
      _store?.restorePurchases(applicationUserName: accountBinding);

  @override
  Future<void> completePurchase(StorePurchaseUpdate purchase) async {
    final native = purchase.nativePurchase;
    if (native is! PurchaseDetails)
      throw ArgumentError('Invalid store purchase object');
    await _store?.completePurchase(native);
  }

  StorePurchaseUpdate _mapPurchase(PurchaseDetails purchase) =>
      StorePurchaseUpdate(
        productId: purchase.productID,
        status: switch (purchase.status) {
          PurchaseStatus.pending => StorePurchaseStatus.pending,
          PurchaseStatus.purchased => StorePurchaseStatus.purchased,
          PurchaseStatus.restored => StorePurchaseStatus.restored,
          PurchaseStatus.canceled => StorePurchaseStatus.canceled,
          PurchaseStatus.error => StorePurchaseStatus.error,
        },
        purchaseId: purchase.purchaseID,
        serverVerificationData:
            purchase.verificationData.serverVerificationData,
        pendingCompletePurchase: purchase.pendingCompletePurchase,
        nativePurchase: purchase,
        errorMessage: purchase.error?.message,
      );
}
