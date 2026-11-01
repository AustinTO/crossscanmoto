import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CachedEntitlement {
  const CachedEntitlement({
    required this.accountId,
    required this.productId,
    required this.verifiedAt,
  });

  final String accountId;
  final String productId;
  final DateTime verifiedAt;
}

abstract interface class PurchaseIdentityStore {
  Future<String> loadOrCreateAccountId();
  Future<void> adoptVerifiedAccountId(String accountId);
  Future<void> saveVerifiedEntitlement(CachedEntitlement entitlement);
  Future<CachedEntitlement?> readCachedEntitlement();
  Future<void> clearCachedEntitlement();
  Future<void> saveAuthSession({required String email, required String sessionToken});
  Future<({String email, String sessionToken})?> readAuthSession();
  Future<void> clearAuthSession();
}

/// Keeps the stable purchase binding in Keychain/Keystore-backed storage.
class SecurePurchaseIdentityStore implements PurchaseIdentityStore {
  SecurePurchaseIdentityStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accountIdKey = 'purchase.account_uuid.v1';
  static const _entitlementKey = 'purchase.verified_entitlement.v1';
  static const _authSessionKey = 'auth.session_token.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String> loadOrCreateAccountId() async {
    final saved = await _storage.read(key: _accountIdKey);
    if (_isUuid(saved)) return saved!.toLowerCase();
    final generated = _newUuidV4();
    await _storage.write(key: _accountIdKey, value: generated);
    return generated;
  }

  @override
  Future<void> adoptVerifiedAccountId(String accountId) async {
    if (!_isUuid(accountId))
      throw const FormatException('Expected a UUID account binding');
    await _storage.write(key: _accountIdKey, value: accountId.toLowerCase());
  }

  @override
  Future<void> saveVerifiedEntitlement(CachedEntitlement entitlement) =>
      _storage.write(
        key: _entitlementKey,
        value: jsonEncode({
          'accountId': entitlement.accountId,
          'productId': entitlement.productId,
          'verifiedAt': entitlement.verifiedAt.toUtc().toIso8601String(),
        }),
      );

  @override
  Future<CachedEntitlement?> readCachedEntitlement() async {
    final value = await _storage.read(key: _entitlementKey);
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;
      final accountId = decoded['accountId'];
      final productId = decoded['productId'];
      final verifiedAt = DateTime.tryParse(
        decoded['verifiedAt'] as String? ?? '',
      );
      if (!_isUuid(accountId) || productId is! String || verifiedAt == null)
        return null;
      return CachedEntitlement(
        accountId: accountId.toLowerCase(),
        productId: productId,
        verifiedAt: verifiedAt,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> clearCachedEntitlement() =>
      _storage.delete(key: _entitlementKey);

  @override
  Future<void> saveAuthSession({
    required String email,
    required String sessionToken,
  }) =>
      _storage.write(
        key: _authSessionKey,
        value: jsonEncode({'email': email, 'sessionToken': sessionToken}),
      );

  @override
  Future<({String email, String sessionToken})?> readAuthSession() async {
    final value = await _storage.read(key: _authSessionKey);
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;
      final email = decoded['email'];
      final sessionToken = decoded['sessionToken'];
      if (email is! String || sessionToken is! String) return null;
      return (email: email, sessionToken: sessionToken);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearAuthSession() => _storage.delete(key: _authSessionKey);

  static bool _isUuid(Object? value) =>
      value is String &&
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(value);

  static String _newUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
