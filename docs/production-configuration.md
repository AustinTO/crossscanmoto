# Production configuration

See [Apple release setup](apple-release.md) for the GitHub Actions signing certificate, app-specific profile, team, bundle identifier, and optional TestFlight upload settings. No signing material is committed. The existing distribution certificate can be reused for the same team when the new app's profile includes it.

The app uses `PAYMENT_API_URL`, `APPLE_UNLOCK_PRODUCT_ID`, and `GOOGLE_UNLOCK_PRODUCT_ID` Dart defines. The actual localized store price comes from the store product. Configure the one-time product at the intended USD 24.99 price in the stores. A listed product does not enable checkout until the server reports its receipt-verification configuration present.

## Worker configuration

`backend/worker/wrangler.jsonc` declares the D1 and email bindings. Apply migrations in order. Put private values in Wrangler secrets, never in Flutter source or GitHub public variables:

- `SESSION_SECRET`: cryptographically random, at least 32 characters; there is no default signing secret.
- `APPLE_PRIVATE_KEY`: App Store Server API key PEM. Configure `APPLE_ISSUER_ID`, `APPLE_KEY_ID`, `APPLE_BUNDLE_ID`, `APPLE_UNLOCK_PRODUCT_ID`, `APPLE_ENVIRONMENT`, and public `APPLE_ROOT_CERTIFICATES` (JSON array of base64 DER Apple roots). Production also requires numeric `APPLE_APP_ID`.
- `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`: Android Publisher service-account key PEM. Configure `GOOGLE_SERVICE_ACCOUNT_EMAIL`, `GOOGLE_PACKAGE_NAME`, and `GOOGLE_UNLOCK_PRODUCT_ID`.

Use the provider's sandbox/license-test products to verify real store transactions before enabling the production products. Apple/Google API keys and product records were not created or substituted using credentials from the unrelated app.

## Authentication and restoration

Email OTP establishes a server-issued canonical account and a revocable bearer session. Purchases, entitlements, and account deletion require that session. Signed store evidence is verified against the original store binding before a restored purchase is linked to the authenticated user; a caller-provided account UUID cannot transfer ownership.

Store notifications are not configured by this setup. Store revocation is checked during purchase verification/restoration; immediate push-driven refund updates require Apple Server Notifications and Google RTDN configuration and validation before relying on that behavior.

## Verification boundaries

The local suite exercises diagnostic framing, target rebinding, cleanup/cancellation, UI flows, billing/auth mocks and real loopback relay traffic. Actual motorcycle/adapter combinations, signed iOS device builds, real store transactions, and email delivery need their respective hardware or configured provider accounts. A passing local suite is not proof of every hardware combination or an absence of all possible bugs.

## Owner VIP entitlement

The backend grants `premium_unlock` with `vip: true`, `unlimited: true`, and `source: vip` to the exact normalized email `austintaylorodell@gmail.com`. The email must come from successful OTP verification or a valid, non-revoked server session that matches the database user. Client headers, query parameters, request bodies, account UUIDs, plus-address aliases, and similar-looking domains cannot grant VIP. Session expiration/logout and account ownership checks still apply. The rule creates no purchase or subscription records and does not alter ordinary customers' purchase entitlements.
