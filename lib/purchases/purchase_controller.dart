import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'purchase_backend_api.dart';
import 'purchase_config.dart';
import 'purchase_identity_store.dart';
import 'purchase_store_gateway.dart';

enum PurchasePhase {
  initial,
  checking,
  locked,
  ready,
  purchasing,
  pending,
  verifying,
  unlocked,
  unavailable,
  error,
}

class PurchaseController extends ChangeNotifier {
  PurchaseController({
    required this.config,
    required PurchaseStoreGateway store,
    required PurchaseIdentityStore identityStore,
    required PurchaseBackendApi backend,
  }) : _store = store,
       _identityStore = identityStore,
       _backend = backend;

  factory PurchaseController.fromEnvironment() {
    final config = PurchaseConfig.fromEnvironment();
    return PurchaseController(
      config: config,
      store: InAppPurchaseStoreGateway(),
      identityStore: SecurePurchaseIdentityStore(),
      backend: HttpPurchaseBackendApi(config: config),
    );
  }

  final PurchaseConfig config;
  final PurchaseStoreGateway _store;
  final PurchaseIdentityStore _identityStore;
  final PurchaseBackendApi _backend;

  PurchasePhase _phase = PurchasePhase.initial;
  PurchasePhase get phase => _phase;

  bool _hasUnlock = false;
  bool get hasUnlock => _hasUnlock;

  bool _storeAvailable = false;
  bool get storeAvailable => _storeAvailable;
  bool _backendReachable = false;
  bool _verificationConfigured = false;

  bool get isConfigured => config.isConfigured;
  bool get canAuthenticate =>
      config.platform != PurchasePlatform.unsupported && config.hasBackend;
  bool get canPurchase =>
      isConfigured &&
      isAuthenticated &&
      _backendReachable &&
      _verificationConfigured &&
      _storeAvailable &&
      product != null &&
      !_hasUnlock;

  String? _message;
  String? get message => _message;

  StoreProduct? _product;
  StoreProduct? get product => _product;

  String? _accountId;
  String? get accountId => _accountId;

  CachedEntitlement? _cachedEntitlement;
  CachedEntitlement? get cachedEntitlement => _cachedEntitlement;

  String? _userEmail;
  String? get userEmail => _userEmail;

  String? _sessionToken;
  String? get sessionToken => _sessionToken;
  bool _sessionValidated = false;

  bool get isAuthenticated =>
      _sessionValidated && _userEmail != null && _sessionToken != null;

  StreamSubscription<List<StorePurchaseUpdate>>? _purchaseSubscription;
  Future<void> _purchaseQueue = Future<void>.value();
  Future<void>? _initialization;
  Completer<void>? _restoreEvent;
  String? _restoreMessage;
  bool _disposed = false;

  Future<void> initialize() => _initialization ??= _initialize();

  /// Requeries the store and server without replacing the secure identity or
  /// resetting any purchase updates that are already being processed.
  Future<void> retry() {
    _initialization = null;
    return initialize();
  }

  Future<void> _initialize() async {
    _setPhase(PurchasePhase.checking, message: null);
    if (config.platform == PurchasePlatform.unsupported) {
      _setPhase(
        PurchasePhase.unavailable,
        message: 'Purchases are supported on iOS and Android.',
      );
      return;
    }
    ({String email, String sessionToken})? savedSession;
    try {
      _accountId = await _identityStore.loadOrCreateAccountId();
      _cachedEntitlement = await _identityStore.readCachedEntitlement();
      savedSession = await _identityStore.readAuthSession();
    } on Object {
      _setPhase(
        PurchasePhase.error,
        message: 'Secure purchase identity storage is unavailable.',
      );
      return;
    }

    if (savedSession != null && config.hasBackend) {
      try {
        final session = await _backend.fetchSession(savedSession.sessionToken);
        if (!session.ok || !_isUuid(session.accountId) || session.email.isEmpty) {
          throw const PurchaseBackendException('invalid_session');
        }
        _userEmail = session.email;
        _sessionToken = savedSession.sessionToken;
        _sessionValidated = true;
        if (_accountId != session.accountId) {
          await _identityStore.adoptVerifiedAccountId(session.accountId);
          _accountId = session.accountId;
        }
      } on PurchaseBackendException catch (error) {
        if (error.statusCode == 401) {
          await _identityStore.clearAuthSession();
          _cachedEntitlement = null;
          await _identityStore.clearCachedEntitlement();
          _sessionToken = null;
          _userEmail = null;
        } else {
          _sessionToken = savedSession.sessionToken;
          _userEmail = savedSession.email;
          _message = 'Sign in again to verify your account with the server.';
        }
      } on Object {
        _sessionToken = savedSession.sessionToken;
        _userEmail = savedSession.email;
        _message = 'Connect to verify your saved account session.';
      }
    } else if (savedSession != null) {
      _userEmail = savedSession.email;
      _sessionToken = savedSession.sessionToken;
      _message = 'Configure the payment server to verify this account session.';
    }

    if (config.hasBackend && isAuthenticated) {
      await refreshEntitlement();
    }

    if (!config.isConfigured) {
      _setPhase(
        PurchasePhase.unavailable,
        message: 'In-app purchases are not configured for this build.',
      );
      return;
    }

    _purchaseSubscription ??= _store.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (Object _) => _setPhase(
          _hasUnlock ? PurchasePhase.unlocked : PurchasePhase.error,
          message: 'The store purchase stream stopped unexpectedly.',
        ),
        onDone: () {
          _purchaseSubscription = null;
        },
      );

    try {
      _storeAvailable = await _store.isAvailable();
      if (!_storeAvailable) {
        _setPhase(
          PurchasePhase.unavailable,
          message: 'The app store is not available on this device.',
        );
        return;
      }
      final result = await _store.queryProduct(config.productId!);
      _product = result.product;
      if (_product == null) {
        _setPhase(
          PurchasePhase.unavailable,
          message:
              result.error ?? 'The configured store product is not available.',
        );
        return;
      }
      if (!isAuthenticated) {
        _hasUnlock = false;
        _setPhase(
          PurchasePhase.ready,
          message: _message ?? 'Sign in with an email code to purchase or restore access.',
        );
      }
    } on PurchaseBackendException catch (error) {
      _hasUnlock = false;
      _setPhase(PurchasePhase.locked, message: _messageFor(error));
    } on Object {
      _hasUnlock = false;
      _setPhase(
        PurchasePhase.locked,
        message:
            'Connect to the internet to verify your purchase before unlocking.',
      );
    }
  }

  /// Entitlements are rechecked with the backend; the secure cache is only a
  /// recovery hint and is never sufficient by itself to unlock the app.
  Future<void> refreshEntitlement() async {
    final sessionToken = _sessionToken;
    if (!config.isConfigured || !isAuthenticated || sessionToken == null) {
      _hasUnlock = false;
      _setPhase(
        config.isConfigured ? PurchasePhase.ready : PurchasePhase.unavailable,
        message: config.isConfigured
            ? 'Sign in with an email code to verify purchase access.'
            : 'Purchases are not configured for this build.',
      );
      return;
    }
    _setPhase(PurchasePhase.checking, message: null);
    _hasUnlock = false;
    try {
      final result = await _backend.fetchEntitlement(sessionToken);
      _backendReachable = true;
      await _applyServerEntitlement(_accountId!, result);
    } on PurchaseBackendException catch (error) {
      _backendReachable = false;
      _hasUnlock = false;
      if (error.statusCode == 401) {
        await _identityStore.clearAuthSession();
        _sessionToken = null;
        _userEmail = null;
        _sessionValidated = false;
      }
      _setPhase(
        PurchasePhase.locked,
        message: error.statusCode == 401
            ? 'Your sign-in expired. Sign in again to verify purchase access.'
            : 'Connect to the internet to verify your purchase. Offline unlocks are disabled.',
      );
    } on Object {
      _backendReachable = false;
      _hasUnlock = false;
      _setPhase(
        PurchasePhase.locked,
        message:
            'Connect to the internet to verify your purchase. Offline unlocks are disabled.',
      );
    }
  }

  Future<void> buy() async {
    final product = _product;
    final account = _accountId;
    if (!canPurchase || product == null || account == null) return;
    _setPhase(PurchasePhase.purchasing, message: null);
    try {
      final accountBinding = config.platform == PurchasePlatform.google
          ? sha256.convert(utf8.encode(account)).toString()
          : account;
      final started = await _store.buyNonConsumable(
        product,
        accountBinding: accountBinding,
      );
      if (!started) {
        _setPhase(
          PurchasePhase.ready,
          message: 'The store did not start the purchase.',
        );
      }
    } on Object {
      _setPhase(
        _hasUnlock ? PurchasePhase.unlocked : PurchasePhase.ready,
        message: 'The purchase could not be started. Please try again.',
      );
    }
  }

  Future<void> restorePurchases() async {
    final account = _accountId;
    if (!config.isConfigured || !_storeAvailable || account == null) {
      _setPhase(
        PurchasePhase.unavailable,
        message: 'Purchases cannot be restored in this build.',
      );
      return;
    }
    if (!isAuthenticated) {
      _setPhase(PurchasePhase.ready,
          message: 'Sign in with your email before restoring purchases.');
      return;
    }
    _setPhase(
      PurchasePhase.verifying,
      message: 'Checking purchases with the store…',
    );
    _restoreEvent = Completer<void>();
    _restoreMessage = null;
    try {
      await _store.restorePurchases(accountBinding: account);
      try {
        await _restoreEvent!.future.timeout(const Duration(seconds: 8));
      } on TimeoutException {
        // A store with no restorable transactions may emit no updates.
      }
      await _purchaseQueue;
      await refreshEntitlement();
      if (!_hasUnlock && _restoreMessage != null) {
        _setPhase(PurchasePhase.locked, message: _restoreMessage);
      } else if (!_hasUnlock && _message == null) {
        _setPhase(
          PurchasePhase.locked,
          message: 'No verified purchase was found for this app identity.',
        );
      }
    } on PurchaseBackendException catch (error) {
      _setPhase(PurchasePhase.locked, message: _messageFor(error));
    } on Object {
      _setPhase(
        PurchasePhase.locked,
        message: 'The store could not restore purchases. Please try again.',
      );
    } finally {
      _restoreEvent = null;
    }
  }

  void _onPurchaseUpdates(List<StorePurchaseUpdate> updates) {
    for (final update in updates) {
      _purchaseQueue = _purchaseQueue.then((_) async {
        try {
          await _processPurchase(update);
        } on Object catch (error) {
          if (error is PurchaseBackendException) {
            if (update.status == StorePurchaseStatus.restored) {
              _restoreMessage = _messageFor(error);
            }
            if ((error.statusCode ?? 0) >= 500) {
              _backendReachable = false;
              _hasUnlock = false;
            }
            _setPhase(
              _hasUnlock ? PurchasePhase.unlocked : PurchasePhase.locked,
              message: _messageFor(error),
            );
          } else {
            _backendReachable = false;
            _hasUnlock = false;
            if (update.status == StorePurchaseStatus.restored) {
              _restoreMessage =
                  'The restored purchase could not be verified with the store.';
            }
            _setPhase(
              _hasUnlock ? PurchasePhase.unlocked : PurchasePhase.error,
              message: 'The purchase could not be verified. Please try again.',
            );
          }
        } finally {
          final completer = _restoreEvent;
          if (update.status == StorePurchaseStatus.restored &&
              completer != null &&
              !completer.isCompleted) {
            completer.complete();
          }
        }
      });
    }
  }

  Future<void> _processPurchase(StorePurchaseUpdate update) async {
    if (update.productId != config.productId) return;
    if (!isAuthenticated || _sessionToken == null) {
      throw const PurchaseBackendException('authentication_required');
    }
    switch (update.status) {
      case StorePurchaseStatus.pending:
        _setPhase(
          PurchasePhase.pending,
          message: 'The store is processing your payment.',
        );
        return;
      case StorePurchaseStatus.canceled:
        _setPhase(
          _hasUnlock ? PurchasePhase.unlocked : PurchasePhase.ready,
          message: 'Purchase cancelled.',
        );
        return;
      case StorePurchaseStatus.error:
        _setPhase(
          _hasUnlock ? PurchasePhase.unlocked : PurchasePhase.ready,
          message:
              update.errorMessage ??
              'The store could not complete the purchase.',
        );
        return;
      case StorePurchaseStatus.purchased:
      case StorePurchaseStatus.restored:
        break;
    }

    _setPhase(PurchasePhase.verifying, message: 'Verifying the purchase…');
    final signedData = update.serverVerificationData;
    if (signedData.isEmpty)
      throw const PurchaseBackendException('missing_store_proof');
    if (_accountId == null)
      throw const PurchaseBackendException('missing_account_id');

    EntitlementStatus result;
    switch (config.platform) {
      case PurchasePlatform.apple:
        final transactionId = update.purchaseId;
        if (transactionId == null || transactionId.isEmpty) {
          throw const PurchaseBackendException('missing_transaction_id');
        }
        result = update.status == StorePurchaseStatus.restored
            ? await _backend.restoreApple(
                sessionToken: _sessionToken!,
                transactionId: transactionId,
                signedTransactionInfo: signedData,
              )
            : await _backend.verifyApple(
                sessionToken: _sessionToken!,
                transactionId: transactionId,
                signedTransactionInfo: signedData,
              );
        break;
      case PurchasePlatform.google:
        result = update.status == StorePurchaseStatus.restored
            ? await _backend.restoreGoogle(
                sessionToken: _sessionToken!,
                purchaseToken: signedData,
              )
            : await _backend.verifyGoogle(
                sessionToken: _sessionToken!,
                purchaseToken: signedData,
              );
        break;
      case PurchasePlatform.unsupported:
        throw const PurchaseBackendException('unsupported_platform');
    }

    if (!result.unlocked) {
      _hasUnlock = false;
      await _identityStore.clearCachedEntitlement();
      _cachedEntitlement = null;
      throw const PurchaseBackendException('purchase_not_entitled');
    }
    _backendReachable = true;
    final account = _accountId!;
    await _identityStore.saveVerifiedEntitlement(
      CachedEntitlement(
        accountId: account,
        productId: config.productId!,
        verifiedAt: DateTime.now().toUtc(),
      ),
    );
    _cachedEntitlement = CachedEntitlement(
      accountId: account,
      productId: config.productId!,
      verifiedAt: DateTime.now().toUtc(),
    );
    _hasUnlock = true;
    _setPhase(PurchasePhase.unlocked, message: null);

    // StoreKit/Play finalization happens only after the server confirms the
    // store proof and the verified entitlement is persisted securely.
    if (update.pendingCompletePurchase) {
      try {
        await _store.completePurchase(update);
      } on Object {
        _setPhase(
          PurchasePhase.unlocked,
          message: 'Purchase verified. Store confirmation will retry.',
        );
      }
    }
  }

  Future<void> _applyServerEntitlement(
    String accountId,
    EntitlementStatus result,
  ) async {
    _hasUnlock = result.unlocked;
    _verificationConfigured = result.verificationConfigured;
    if (result.unlocked) {
      final cached = CachedEntitlement(
        accountId: accountId,
        productId: config.productId!,
        verifiedAt: DateTime.now().toUtc(),
      );
      await _identityStore.saveVerifiedEntitlement(cached);
      _cachedEntitlement = cached;
      _setPhase(PurchasePhase.unlocked, message: null);
    } else {
      await _identityStore.clearCachedEntitlement();
      _cachedEntitlement = null;
      _setPhase(PurchasePhase.ready, message: result.verificationConfigured ? null : 'Purchases are not available yet. Store verification is awaiting configuration.');
    }
  }

  Future<OtpRequestResult> requestEmailOtp(String email) async {
    if (!canAuthenticate) {
      throw const PurchaseBackendException('backend_not_configured');
    }
    return _backend.requestOtp(email.trim().toLowerCase());
  }

  Future<bool> verifyEmailOtp(String email, String code) async {
    final session = await _backend.verifyOtp(
      email.trim().toLowerCase(),
      code.trim(),
    );
    if (!session.ok || session.sessionToken.isEmpty || !_isUuid(session.accountId)) {
      throw const PurchaseBackendException('invalid_session');
    }
    _userEmail = session.email;
    _sessionToken = session.sessionToken;
    _sessionValidated = true;
    _backendReachable = true;
    await _identityStore.saveAuthSession(
      email: session.email,
      sessionToken: session.sessionToken,
    );
    if (session.accountId.isNotEmpty && session.accountId != _accountId) {
      _accountId = session.accountId;
      await _identityStore.adoptVerifiedAccountId(session.accountId);
    }
    await refreshEntitlement();
    return true;
  }

  Future<void> signOut() async {
    final token = _sessionToken;
    String? warning;
    if (token != null) {
      try {
        await _backend.revokeSession(token);
      } on Object {
        warning = 'Signed out on this device; the server session could not be revoked offline.';
      }
    }
    await _identityStore.clearAuthSession();
    _userEmail = null;
    _sessionToken = null;
    _sessionValidated = false;
    _hasUnlock = false;
    _backendReachable = false;
    _setPhase(PurchasePhase.ready, message: warning);
  }

  Future<bool> deleteAccountAndData() async {
    final token = _sessionToken;
    if (!isAuthenticated || token == null) {
      throw const PurchaseBackendException('authentication_required');
    }
    final remoteDeleted = await _backend.deleteAccount(token);
    if (!remoteDeleted) throw const PurchaseBackendException('delete_failed');
    await _identityStore.clearCachedEntitlement();
    await _identityStore.clearAuthSession();
    _cachedEntitlement = null;
    _userEmail = null;
    _sessionToken = null;
    _sessionValidated = false;
    _hasUnlock = false;
    _backendReachable = false;
    _accountId = await _identityStore.resetAccountId();
    _setPhase(
      PurchasePhase.ready,
      message: 'Account records and local entitlements have been purged.',
    );
    return remoteDeleted;
  }

  static bool _isUuid(String value) => RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value);

  String _messageFor(PurchaseBackendException error) => switch (error.code) {
    'authentication_required' => 'Sign in with your email before purchasing or restoring.',
    'account_mismatch' => 'This purchase is linked to a different app account.',
    'recovery_unavailable' => 'This store purchase has no existing verified server record to recover.',
    'purchase_pending' => 'The store is still processing your payment.',
    'purchase_replayed' =>
      'This purchase is already linked to another app identity.',
    'store_not_configured' => 'Purchases are not configured for this build.',
    _ => 'The store could not verify this purchase. Please try again.',
  };

  void _setPhase(PurchasePhase phase, {String? message}) {
    if (_disposed) return;
    _phase = phase;
    _message = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_purchaseSubscription?.cancel());
    if (_backend is HttpPurchaseBackendApi) {
      _backend.close();
    }
    super.dispose();
  }
}
