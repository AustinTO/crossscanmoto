import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/purchases/purchase_backend_api.dart';
import 'package:crossscanmoto/purchases/purchase_config.dart';
import 'package:crossscanmoto/purchases/purchase_controller.dart';
import 'package:crossscanmoto/purchases/purchase_identity_store.dart';
import 'package:crossscanmoto/purchases/purchase_store_gateway.dart';

const firstAccount = '59341044-17c8-47a3-8db9-5a9549956d9f';
const restoredAccount = '1c2bcd2c-48cf-41f5-b3c8-66939cc33333';

PurchaseConfig config(PurchasePlatform platform) => PurchaseConfig(
  platform: platform,
  apiBaseUrl: 'https://payments.example.invalid',
  appleProductId: 'app.example.unlock.ios',
  googleProductId: 'app.example.unlock.android',
);

class FakeIdentityStore implements PurchaseIdentityStore {
  FakeIdentityStore(this.accountId, {this.cached});

  String accountId;
  CachedEntitlement? cached;
  String? savedEmail;
  String? savedToken;

  @override
  Future<String> loadOrCreateAccountId() async => accountId;

  @override
  Future<void> adoptVerifiedAccountId(String accountId) async {
    this.accountId = accountId;
  }

  @override
  Future<void> saveVerifiedEntitlement(CachedEntitlement entitlement) async {
    cached = entitlement;
  }

  @override
  Future<CachedEntitlement?> readCachedEntitlement() async => cached;

  @override
  Future<void> clearCachedEntitlement() async => cached = null;

  @override
  Future<void> saveAuthSession({
    required String email,
    required String sessionToken,
  }) async {
    savedEmail = email;
    savedToken = sessionToken;
  }

  @override
  Future<({String email, String sessionToken})?> readAuthSession() async {
    if (savedEmail != null && savedToken != null) {
      return (email: savedEmail!, sessionToken: savedToken!);
    }
    return null;
  }

  @override
  Future<void> clearAuthSession() async {
    savedEmail = null;
    savedToken = null;
  }
}

class FakeBackend implements PurchaseBackendApi {
  EntitlementStatus initialEntitlement = const EntitlementStatus(
    unlocked: false,
    status: 'none',
  );
  Object? initialError;
  EntitlementStatus purchaseResult = const EntitlementStatus(
    unlocked: true,
    status: 'active',
  );
  Object? purchaseError;
  String? verifiedAccountId;
  String? verifiedPurchaseToken;
  String? verifiedJws;
  int verificationCalls = 0;
  String? requestedOtpEmail;
  String? verifiedOtpEmail;
  String? verifiedOtpCode;

  @override
  Future<EntitlementStatus> fetchEntitlement(String accountId) async {
    if (initialError case final error?) throw error;
    return initialEntitlement;
  }

  @override
  Future<EntitlementStatus> verifyApple({
    required String accountId,
    required String transactionId,
    required String signedTransactionInfo,
  }) async {
    verificationCalls++;
    verifiedAccountId = accountId;
    verifiedJws = signedTransactionInfo;
    if (purchaseError case final error?) throw error;
    return purchaseResult;
  }

  @override
  Future<EntitlementStatus> verifyGoogle({
    required String accountId,
    required String purchaseToken,
  }) async {
    verificationCalls++;
    verifiedAccountId = accountId;
    verifiedPurchaseToken = purchaseToken;
    if (purchaseError case final error?) throw error;
    return purchaseResult;
  }

  int deleteCalls = 0;
  String? deletedAccountId;

  @override
  Future<bool> deleteAccount(String accountId) async {
    deleteCalls++;
    deletedAccountId = accountId;
    return true;
  }

  @override
  Future<OtpRequestResult> requestOtp(String email, {String? accountId}) async {
    requestedOtpEmail = email;
    return OtpRequestResult(ok: true, email: email, expiresIn: 600);
  }

  @override
  Future<AuthSession> verifyOtp(
    String email,
    String code, {
    String? accountId,
  }) async {
    verifiedOtpEmail = email;
    verifiedOtpCode = code;
    return AuthSession(
      ok: true,
      email: email,
      sessionToken: 'fake-jwt-token',
      accountId: accountId ?? firstAccount,
      unlocked: true,
    );
  }

  @override
  Future<AuthSession> fetchSession(String sessionToken) async {
    return AuthSession(
      ok: true,
      email: 'test@example.com',
      sessionToken: sessionToken,
      accountId: firstAccount,
      unlocked: true,
    );
  }
}

class FakeStore implements PurchaseStoreGateway {
  final updates = StreamController<List<StorePurchaseUpdate>>.broadcast();
  bool available = true;
  int availabilityChecks = 0;
  int completions = 0;
  String? purchaseBinding;
  String? restoreBinding;

  @override
  Stream<List<StorePurchaseUpdate>> get purchaseStream => updates.stream;

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<StoreProductResult> queryProduct(String productId) async =>
      StoreProductResult(
        product: StoreProduct(
          id: productId,
          title: 'Unlock',
          description: 'One-time unlock',
          price: r'$24.99',
          currencyCode: 'USD',
          nativeProduct: Object(),
        ),
      );

  @override
  Future<bool> buyNonConsumable(
    StoreProduct product, {
    required String accountBinding,
  }) async {
    purchaseBinding = accountBinding;
    return true;
  }

  @override
  Future<void> restorePurchases({required String accountBinding}) async {
    restoreBinding = accountBinding;
  }

  @override
  Future<void> completePurchase(StorePurchaseUpdate purchase) async {
    completions++;
  }

  StorePurchaseUpdate update({
    required PurchasePlatform platform,
    required StorePurchaseStatus status,
    required String proof,
    String? purchaseId,
    bool pendingComplete = true,
  }) => StorePurchaseUpdate(
    productId: platform == PurchasePlatform.apple
        ? 'app.example.unlock.ios'
        : 'app.example.unlock.android',
    status: status,
    purchaseId: purchaseId,
    serverVerificationData: proof,
    pendingCompletePurchase: pendingComplete,
    nativePurchase: Object(),
  );
}

String signedTransactionFor(String accountId) {
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'appAccountToken': accountId,
            'transactionId': 'apple-transaction-1',
          }),
        ),
      )
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 15));

void main() {
  test(
    'missing product or backend configuration never starts billing',
    () async {
      final store = FakeStore();
      final controller = PurchaseController(
        config: const PurchaseConfig(
          platform: PurchasePlatform.google,
          apiBaseUrl: '',
          appleProductId: '',
          googleProductId: '',
        ),
        store: store,
        identityStore: FakeIdentityStore(firstAccount),
        backend: FakeBackend(),
      );

      await controller.initialize();
      await controller.buy();

      expect(controller.hasUnlock, isFalse);
      expect(controller.canPurchase, isFalse);
      expect(store.availabilityChecks, 0);
      expect(store.purchaseBinding, isNull);
      await store.updates.close();
      controller.dispose();
    },
  );

  test(
    'a saved entitlement is not trusted while the backend is offline',
    () async {
      final store = FakeStore();
      final backend = FakeBackend()..initialError = StateError('offline');
      final cached = CachedEntitlement(
        accountId: firstAccount,
        productId: 'app.example.unlock.android',
        verifiedAt: DateTime.utc(2026, 10, 30),
      );
      final identity = FakeIdentityStore(firstAccount, cached: cached);
      final controller = PurchaseController(
        config: config(PurchasePlatform.google),
        store: store,
        identityStore: identity,
        backend: backend,
      );

      await controller.initialize();

      expect(controller.cachedEntitlement, same(cached));
      expect(controller.hasUnlock, isFalse);
    expect(controller.canPurchase, isFalse);
      expect(controller.phase, PurchasePhase.locked);
      await store.updates.close();
      controller.dispose();
    },
  );

  test(
    'Google binding is SHA-256 UUID and completion follows server verification',
    () async {
      final store = FakeStore();
      final backend = FakeBackend();
      final identity = FakeIdentityStore(firstAccount);
      final controller = PurchaseController(
        config: config(PurchasePlatform.google),
        store: store,
        identityStore: identity,
        backend: backend,
      );
      await controller.initialize();
      await controller.buy();
      expect(
        store.purchaseBinding,
        sha256.convert(utf8.encode(firstAccount)).toString(),
      );

      store.updates.add([
        store.update(
          platform: PurchasePlatform.google,
          status: StorePurchaseStatus.purchased,
          proof: 'google-purchase-token',
        ),
      ]);
      await settle();

      expect(backend.verifiedAccountId, firstAccount);
      expect(backend.verifiedPurchaseToken, 'google-purchase-token');
      expect(controller.hasUnlock, isTrue);
      expect(identity.cached?.accountId, firstAccount);
      expect(store.completions, 1);
      await store.updates.close();
      controller.dispose();
    },
  );

  test('pending Google payment is neither verified nor completed', () async {
    final store = FakeStore();
    final backend = FakeBackend();
    final controller = PurchaseController(
      config: config(PurchasePlatform.google),
      store: store,
      identityStore: FakeIdentityStore(firstAccount),
      backend: backend,
    );
    await controller.initialize();
    store.updates.add([
      store.update(
        platform: PurchasePlatform.google,
        status: StorePurchaseStatus.pending,
        proof: 'pending-token',
      ),
    ]);
    await settle();

    expect(controller.phase, PurchasePhase.pending);
    expect(controller.hasUnlock, isFalse);
    expect(backend.verificationCalls, 0);
    expect(store.completions, 0);
    await store.updates.close();
    controller.dispose();
  });

  test(
    'Google account mismatch fails closed and leaves the transaction unfinished',
    () async {
      final store = FakeStore();
      final backend = FakeBackend()
        ..purchaseError = const PurchaseBackendException('account_mismatch');
      final controller = PurchaseController(
        config: config(PurchasePlatform.google),
        store: store,
        identityStore: FakeIdentityStore(firstAccount),
        backend: backend,
      );
      await controller.initialize();
      store.updates.add([
        store.update(
          platform: PurchasePlatform.google,
          status: StorePurchaseStatus.restored,
          proof: 'token-bound-to-another-uuid',
        ),
      ]);
      await settle();

      expect(controller.hasUnlock, isFalse);
      expect(controller.phase, PurchasePhase.locked);
      expect(controller.message, contains('new install'));
      expect(store.completions, 0);
      await store.updates.close();
      controller.dispose();
    },
  );

  test(
    'Apple restore selects JWS appAccountToken then persists only after backend success',
    () async {
      final store = FakeStore();
      final backend = FakeBackend();
      final identity = FakeIdentityStore(firstAccount);
      final controller = PurchaseController(
        config: config(PurchasePlatform.apple),
        store: store,
        identityStore: identity,
        backend: backend,
      );
      await controller.initialize();
      final jws = signedTransactionFor(restoredAccount);
      store.updates.add([
        store.update(
          platform: PurchasePlatform.apple,
          status: StorePurchaseStatus.restored,
          proof: jws,
          purchaseId: 'apple-transaction-1',
        ),
      ]);
      await settle();

      expect(backend.verifiedAccountId, restoredAccount);
      expect(backend.verifiedJws, jws);
      expect(identity.accountId, restoredAccount);
      expect(identity.cached?.accountId, restoredAccount);
      expect(controller.hasUnlock, isTrue);
      expect(store.completions, 1);
      await store.updates.close();
      controller.dispose();
    },
  );

  test(
    'deleteAccountAndData calls backend deletion API and clears cached identity and entitlements',
    () async {
      final store = FakeStore();
      final backend = FakeBackend();
      backend.initialEntitlement = const EntitlementStatus(
        unlocked: true,
        status: 'active',
      );
      final identity = FakeIdentityStore(
        firstAccount,
        cached: CachedEntitlement(
          accountId: firstAccount,
          productId: 'app.example.unlock.ios',
          verifiedAt: DateTime.now().toUtc(),
        ),
      );
      final controller = PurchaseController(
        config: config(PurchasePlatform.apple),
        store: store,
        identityStore: identity,
        backend: backend,
      );
      await controller.initialize();
      expect(controller.hasUnlock, isTrue);

      final deleted = await controller.deleteAccountAndData();
      expect(deleted, isTrue);
      expect(backend.deleteCalls, 1);
      expect(backend.deletedAccountId, firstAccount);
      expect(identity.cached, isNull);
      expect(controller.hasUnlock, isFalse);
      expect(controller.phase, PurchasePhase.ready);
      await store.updates.close();
      controller.dispose();
    },
  );

  test(
    'email OTP request, verification, session persistence and sign out',
    () async {
      final store = FakeStore();
      final backend = FakeBackend();
      final identity = FakeIdentityStore(firstAccount);
      final controller = PurchaseController(
        config: config(PurchasePlatform.apple),
        store: store,
        identityStore: identity,
        backend: backend,
      );
      await controller.initialize();
      expect(controller.isAuthenticated, isFalse);

      final reqResult = await controller.requestEmailOtp('mechanic@example.com');
      expect(reqResult.ok, isTrue);
      expect(backend.requestedOtpEmail, 'mechanic@example.com');

      final verifyResult = await controller.verifyEmailOtp(
        'mechanic@example.com',
        '123456',
      );
      expect(verifyResult, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.userEmail, 'mechanic@example.com');
      expect(identity.savedEmail, 'mechanic@example.com');
      expect(identity.savedToken, 'fake-jwt-token');
      expect(controller.hasUnlock, isTrue);

      await controller.signOut();
      expect(controller.isAuthenticated, isFalse);
      expect(controller.userEmail, isNull);
      expect(identity.savedEmail, isNull);
      expect(identity.savedToken, isNull);

      await store.updates.close();
      controller.dispose();
    },
  );
}
