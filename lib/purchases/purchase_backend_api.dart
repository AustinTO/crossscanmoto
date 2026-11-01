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
  const EntitlementStatus({required this.unlocked, required this.status});

  final bool unlocked;
  final String status;
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
  Future<EntitlementStatus> fetchEntitlement(String accountId);

  Future<EntitlementStatus> verifyApple({
    required String accountId,
    required String transactionId,
    required String signedTransactionInfo,
  });

  Future<EntitlementStatus> verifyGoogle({
    required String accountId,
    required String purchaseToken,
  });

  Future<bool> deleteAccount(String accountId);

  Future<OtpRequestResult> requestOtp(String email, {String? accountId});

  Future<AuthSession> verifyOtp(
    String email,
    String code, {
    String? accountId,
  });

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

  @override
  Future<EntitlementStatus> fetchEntitlement(String accountId) async {
    final response = await _client
        .get(_uri('/v1/entitlements/${Uri.encodeComponent(accountId)}'))
        .timeout(const Duration(seconds: 15));
    return _parse(response);
  }

  @override
  Future<bool> deleteAccount(String accountId) async {
    final response = await _client.delete(
      _uri('/v1/account/${Uri.encodeComponent(accountId)}'),
      headers: const {'content-type': 'application/json'},
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw PurchaseBackendException('delete_failed', statusCode: response.statusCode);
  }

  @override
  Future<EntitlementStatus> verifyApple({
    required String accountId,
    required String transactionId,
    required String signedTransactionInfo,
  }) async {
    final response = await _post('/v1/purchases/apple', {
      'accountId': accountId,
      'transactionId': transactionId,
      'signedTransactionInfo': signedTransactionInfo,
    });
    return _parse(response);
  }

  @override
  Future<EntitlementStatus> verifyGoogle({
    required String accountId,
    required String purchaseToken,
  }) async {
    final response = await _post('/v1/purchases/google', {
      'accountId': accountId,
      'purchaseToken': purchaseToken,
    });
    return _parse(response);
  }

  @override
  Future<OtpRequestResult> requestOtp(String email, {String? accountId}) async {
    final body = <String, Object?>{'email': email};
    if (accountId != null) body['accountId'] = accountId;
    final response = await _post('/v1/auth/otp/request', body);
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
  Future<AuthSession> verifyOtp(
    String email,
    String code, {
    String? accountId,
  }) async {
    final body = <String, Object?>{'email': email, 'code': code};
    if (accountId != null) body['accountId'] = accountId;
    final response = await _post('/v1/auth/otp/verify', body);
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
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $sessionToken',
      },
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

  Future<http.Response> _post(String path, Map<String, Object?> body) => _client
      .post(
        _uri(path),
        headers: const {'content-type': 'application/json'},
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
