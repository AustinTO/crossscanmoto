import 'dart:convert';

import 'package:http/http.dart' as http;

import 'purchase_config.dart';

class PurchaseBackendException implements Exception {
  const PurchaseBackendException(this.code, {this.statusCode});

  final String code;
  final int? statusCode;

  @override
  String toString() => 'PurchaseBackendException($code)';
}

class EntitlementStatus {
  const EntitlementStatus({required this.unlocked, required this.status, this.verificationConfigured = false});

  final bool unlocked;
  final String status;
  final bool verificationConfigured;
}

class OtpRequestResult {
  const OtpRequestResult({
    required this.ok,
    required this.email,
    required this.expiresIn,
  });

  final bool ok;
  final String email;
  final int expiresIn;
}

class AuthSession {
  const AuthSession({
    required this.ok,
    required this.email,
    required this.sessionToken,
    required this.accountId,
    required this.unlocked,
  });

  final bool ok;
  final String email;
  final String sessionToken;
  final String accountId;
  final bool unlocked;
}

abstract interface class PurchaseBackendApi {
  Future<EntitlementStatus> fetchEntitlement(String sessionToken);

  Future<EntitlementStatus> verifyApple({
    required String sessionToken,
    required String transactionId,
    required String signedTransactionInfo,
  });

  Future<EntitlementStatus> restoreApple({
    required String sessionToken,
    required String transactionId,
    required String signedTransactionInfo,
  });

  Future<EntitlementStatus> verifyGoogle({
    required String sessionToken,
    required String purchaseToken,
  });

  Future<EntitlementStatus> restoreGoogle({
    required String sessionToken,
    required String purchaseToken,
  });

  Future<bool> deleteAccount(String sessionToken);
  Future<void> revokeSession(String sessionToken);

  Future<OtpRequestResult> requestOtp(String email);

  Future<AuthSession> verifyOtp(String email, String code);

  Future<AuthSession> fetchSession(String sessionToken);
}

/// HTTPS client for the production Worker contract. It contains no app secret.
class HttpPurchaseBackendApi implements PurchaseBackendApi {
  HttpPurchaseBackendApi({required this.config, http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final PurchaseConfig config;
  final http.Client _client;
  final bool _ownsClient;

  Uri _uri(String path) =>
      Uri.parse('${config.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}$path');

  Map<String, String> _authHeaders(String sessionToken) => {
    'content-type': 'application/json',
    'authorization': 'Bearer $sessionToken',
  };

  @override
  Future<EntitlementStatus> fetchEntitlement(String sessionToken) async {
    final response = await _client
        .get(_uri('/v1/entitlements'), headers: _authHeaders(sessionToken))
        .timeout(const Duration(seconds: 15));
    return _parse(response);
  }

  @override
  Future<bool> deleteAccount(String sessionToken) async {
    final response = await _client.delete(
      _uri('/v1/account'),
      headers: _authHeaders(sessionToken),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw PurchaseBackendException('delete_failed', statusCode: response.statusCode);
  }

  @override
  Future<void> revokeSession(String sessionToken) async {
    final response = await _post(
      '/v1/auth/logout',
      const {},
      sessionToken: sessionToken,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PurchaseBackendException('logout_failed', statusCode: response.statusCode);
    }
  }

  @override
  Future<EntitlementStatus> verifyApple({
    required String sessionToken,
    required String transactionId,
    required String signedTransactionInfo,
  }) async {
    final response = await _post('/v1/purchases/apple', {
      'transactionId': transactionId,
      'signedTransactionInfo': signedTransactionInfo,
    }, sessionToken: sessionToken);
    return _parse(response);
  }

  @override
  Future<EntitlementStatus> restoreApple({
    required String sessionToken,
    required String transactionId,
    required String signedTransactionInfo,
  }) async {
    final response = await _post('/v1/purchases/apple/restore', {
      'transactionId': transactionId,
      'signedTransactionInfo': signedTransactionInfo,
    }, sessionToken: sessionToken);
    return _parse(response);
  }

  @override
  Future<EntitlementStatus> verifyGoogle({
    required String sessionToken,
    required String purchaseToken,
  }) async {
    final response = await _post('/v1/purchases/google', {
      'purchaseToken': purchaseToken,
    }, sessionToken: sessionToken);
    return _parse(response);
  }

  @override
  Future<EntitlementStatus> restoreGoogle({
    required String sessionToken,
    required String purchaseToken,
  }) async {
    final response = await _post('/v1/purchases/google/restore', {
      'purchaseToken': purchaseToken,
    }, sessionToken: sessionToken);
    return _parse(response);
  }

  @override
  Future<OtpRequestResult> requestOtp(String email) async {
    final response = await _post('/v1/auth/otp/request', {'email': email});
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return OtpRequestResult(
        ok: decoded['ok'] == true,
        email: decoded['email'] as String? ?? email,
        expiresIn: (decoded['expiresIn'] as num?)?.toInt() ?? 600,
      );
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
    final error = decoded?['error'] as String? ?? 'request_otp_failed';
    throw PurchaseBackendException(error, statusCode: response.statusCode);
  }

  @override
  Future<AuthSession> verifyOtp(String email, String code) async {
    final response = await _post('/v1/auth/otp/verify', {'email': email, 'code': code});
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthSession(
        ok: decoded['ok'] == true,
        email: decoded['email'] as String? ?? email,
        sessionToken: decoded['sessionToken'] as String? ?? '',
        accountId: decoded['accountId'] as String? ?? '',
        unlocked: decoded['unlocked'] == true,
      );
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
    final error = decoded?['error'] as String? ?? 'verify_otp_failed';
    throw PurchaseBackendException(error, statusCode: response.statusCode);
  }

  @override
  Future<AuthSession> fetchSession(String sessionToken) async {
    final response = await _client.get(
      _uri('/v1/auth/session'),
      headers: _authHeaders(sessionToken),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthSession(
        ok: decoded['ok'] == true,
        email: decoded['email'] as String? ?? '',
        sessionToken: sessionToken,
        accountId: decoded['accountId'] as String? ?? '',
        unlocked: decoded['unlocked'] == true,
      );
    }
    throw PurchaseBackendException('invalid_session', statusCode: response.statusCode);
  }

  Future<http.Response> _post(
    String path,
    Map<String, Object?> body, {
    String? sessionToken,
  }) => _client
      .post(
        _uri(path),
        headers: sessionToken == null ? const {'content-type': 'application/json'} : _authHeaders(sessionToken),
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 20));

  EntitlementStatus _parse(http.Response response) {
    Map<String, Object?> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object');
      }
      body = decoded;
    } on FormatException {
      throw PurchaseBackendException(
        'invalid_server_response',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode == 200 && body['entitlement'] == true) {
      return const EntitlementStatus(unlocked: true, status: 'active');
    }
    if (response.statusCode == 200 && body['unlocked'] == true) {
      return const EntitlementStatus(unlocked: true, status: 'active');
    }
    if (response.statusCode == 200 && body['unlocked'] == false) {
      return EntitlementStatus(
        unlocked: false,
        status: body['status'] is String ? body['status']! as String : 'none',
        verificationConfigured: body['verificationConfigured'] is Map && (body['verificationConfigured'] as Map)[config.platform == PurchasePlatform.apple ? 'apple' : 'google'] == true,
      );
    }
    if (response.statusCode == 409 &&
        body['valid'] == false &&
        body['entitlement'] == false) {
      return const EntitlementStatus(unlocked: false, status: 'revoked');
    }
    final code = body['error'] is String
        ? body['error']! as String
        : 'verification_failed';
    throw PurchaseBackendException(code, statusCode: response.statusCode);
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
