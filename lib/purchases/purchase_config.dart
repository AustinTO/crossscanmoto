import 'package:flutter/foundation.dart';

enum PurchasePlatform { apple, google, unsupported }

/// Store identifiers are supplied at build time after App Store Connect and
/// Play Console products have been created. An unset value disables checkout.
class PurchaseConfig {
  const PurchaseConfig({
    required this.platform,
    required this.apiBaseUrl,
    required this.appleProductId,
    required this.googleProductId,
  });

  final PurchasePlatform platform;
  final String apiBaseUrl;
  final String appleProductId;
  final String googleProductId;

  factory PurchaseConfig.fromEnvironment({TargetPlatform? targetPlatform}) {
    final platform = kIsWeb
        ? PurchasePlatform.unsupported
        : switch (targetPlatform ?? defaultTargetPlatform) {
            TargetPlatform.iOS => PurchasePlatform.apple,
            TargetPlatform.android => PurchasePlatform.google,
            _ => PurchasePlatform.unsupported,
          };
    const envApi = String.fromEnvironment('PAYMENT_API_URL');
    const envApple = String.fromEnvironment('APPLE_UNLOCK_PRODUCT_ID');
    const envGoogle = String.fromEnvironment('GOOGLE_UNLOCK_PRODUCT_ID');
    return PurchaseConfig(
      platform: platform,
      apiBaseUrl: envApi.trim().isNotEmpty
          ? envApi.trim()
          : 'https://crossscanmoto-payment-backend.austintaylorodell.workers.dev',
      appleProductId: envApple.trim().isNotEmpty
          ? envApple.trim()
          : 'crossscanmoto_premium_unlock',
      googleProductId: envGoogle.trim().isNotEmpty
          ? envGoogle.trim()
          : 'crossscanmoto_premium_unlock',
    );
  }

  String? get productId => switch (platform) {
    PurchasePlatform.apple when appleProductId.isNotEmpty => appleProductId,
    PurchasePlatform.google when googleProductId.isNotEmpty => googleProductId,
    _ => null,
  };

  bool get isConfigured =>
      platform != PurchasePlatform.unsupported && productId != null && hasBackend;

  bool get hasBackend => _validApiBase(apiBaseUrl);

  static bool _validApiBase(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      return false;
    }
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' &&
        const {'localhost', '127.0.0.1', '10.0.2.2'}.contains(uri.host);
  }
}
