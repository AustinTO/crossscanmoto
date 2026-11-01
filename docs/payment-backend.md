# CrossScan Moto — Backend & Purchase Verification

Developed by **Puphr LLC** for **CrossScan Moto** (`com.puphr.crossscanmoto`).

The Cloudflare Worker at `backend/worker` (`crossscanmoto-payment-backend`) verifies Apple App Store and Google Play purchases before it writes a one-time unlock entitlement to Cloudflare D1 (`crossscanmoto-payments`). It also hosts GDPR/CCPA compliant account deletion APIs, Apple & Google Play store compliance pages (Privacy Policy, Terms of Service, Account Deletion portal), and enforces strict HTTP security headers. Store IDs and private credentials are set via Wrangler secrets. Missing configuration returns `503`; no request can unlock the app by supplying a transaction ID alone.

## Endpoints

### 1. Verification & Entitlements
`GET /health` returns service status and attribution to Puphr LLC. `GET /v1/config` returns USD 24.99 as product display metadata. Apple and Google set the actual localized price, collect the payment, and provide the amount to the customer; this Worker never charges cards and does not assert that every storefront transaction totals USD 24.99.

`POST /v1/purchases/apple` accepts JSON with:

```json
{
  "accountId": "<stable lowercase UUID>",
  "transactionId": "<StoreKit transaction ID>",
  "signedTransactionInfo": "<StoreKit signed transaction JWS>"
}
```

The Worker verifies the submitted JWS against configured Apple root certificates, checks bundle ID (`com.puphr.crossscanmoto`), product ID, environment, product type, transaction ID, and `appAccountToken`, then retrieves the same transaction through Apple's App Store Server API and verifies the server JWS and claims again. A revoked transaction is persisted as revoked and does not grant access.

`POST /v1/purchases/google` accepts JSON with:

```json
{
  "accountId": "<stable lowercase UUID>",
  "purchaseToken": "<Play Billing purchase token>"
}
```

The Worker obtains a short-lived Google OAuth token from its service account, requests the `purchases.productsv2.getproductpurchasev2` record, validates the configured package (`com.puphr.crossscanmoto`), product, `PURCHASED` state, completion time, and `obfuscatedExternalAccountId`, then acknowledges a completed purchase if required. Pending purchases never create an active entitlement. Google test purchase records are rejected unless the explicit local-only `GOOGLE_ALLOW_TEST_PURCHASES=true` setting is set.

Google's account binding is `lowercase_hex(SHA-256(UTF-8(lowercase(accountId))))`. The Android Billing client must pass that value as `obfuscatedAccountId` when initiating the purchase. The iOS client must pass the UUID as StoreKit's `appAccountToken`. Purchases without the required binding fail closed. The purchase token is used for Google verification and hashed before it is stored; raw tokens and Apple JWS values are not persisted.

`GET /v1/entitlements/{accountId}` returns only whether the `premium_unlock` entitlement is active. Account IDs are stable opaque UUIDs, not an authentication system.

### 2. Email OTP Authentication & Cross-Platform Sync (`auth.trusthentic.com`)
The Worker provides optional email OTP login via Cloudflare Workers' native `send_email` binding, dispatching 6-digit verification codes from `CrossScan Moto <noreply@auth.trusthentic.com>`.

- `POST /v1/auth/otp/request`:
  - Body: `{ "email": "user@example.com", "accountId": "<optional client UUID>" }`
  - Generates a cryptographically random 6-digit code.
  - Rate-limited to 1 request per 60 seconds per email.
  - Sends multipart text/HTML email from `noreply@auth.trusthentic.com`.
  - Stores salt and `SHA-256(code:salt)` in D1 `auth_otps` with a 10-minute expiration.
- `POST /v1/auth/otp/verify`:
  - Body: `{ "email": "user@example.com", "code": "123456", "accountId": "<optional client UUID>" }`
  - Validates code hash against D1. Lockout triggered after 5 failed attempts.
  - Links/creates user in `users` table and merges entitlements.
  - Returns signed 30-day HMAC-SHA256 session JWT (`iss: auth.trusthentic.com`), linked `accountId`, and entitlement unlock status.
- `GET /v1/auth/session`:
  - Header: `Authorization: Bearer <sessionToken>`
  - Verifies JWT and returns current email, accountId, and unlock status.

### 3. Account Deletion (Store Compliance & GDPR/CCPA)
`DELETE /v1/account/:accountId` and `POST /v1/account/delete` accept an `accountId` UUID. When invoked, all corresponding purchase records, entitlement records, and user rows in Cloudflare D1 are permanently purged.

### 4. Public Compliance Web Pages
The worker serves standalone, clean, responsive HTML pages with full Puphr LLC legal and safety notices:
- `GET /privacy` and `GET /privacy-policy`: Official Privacy Policy declaring local telemetry processing, zero data broker transmission, and user privacy rights.
- `GET /terms` and `GET /terms-of-service`: Terms of Service and Workshop Safety Disclaimers.
- `GET /delete-account`: Web-accessible portal allowing users to submit account deletion requests (as mandated by Apple App Store Guideline 5.1.1(v) and Google Play policy).

### 5. Hardened HTTP Security Headers
All responses emitted by the worker include:
- `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- `Content-Security-Policy: default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'`
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Cross-Origin-Opener-Policy: same-origin`
- CORS Preflight support (`OPTIONS *`) with authorized methods (`GET, POST, DELETE, OPTIONS`).

## D1 and replay protection

The migration at `backend/worker/migrations/0001_purchase_entitlements.sql` creates:

- `purchase_records`, uniquely keyed by store and transaction/purchase-token hash, with a second uniqueness constraint on store and transaction ID;
- `entitlements`, keyed by account UUID and the internal `premium_unlock` feature key.

Writes use D1 batches. Replaying the same verified transaction for the same account is idempotent. Replaying a transaction under a different account/product is rejected. Re-verifying a refunded/revoked transaction updates its persisted purchase state and recomputes the entitlement from all active purchase records for that account.

Account deletion purges both tables for the given UUID in an atomic batch.

## Configuration

| Worker variable or secret | Source | Value / Format |
| --- | --- | --- |
| `APPLE_BUNDLE_ID` | iOS bundle identifier | `com.puphr.crossscanmoto` |
| `APPLE_UNLOCK_PRODUCT_ID` | One-time App Store product | `crossscanmoto_premium_unlock` |
| `APPLE_ENVIRONMENT` | App Store environment | `Sandbox` or `Production` |
| `APPLE_APP_ID` | Numeric App Store app ID | e.g. `6741234567` |
| `APPLE_ISSUER_ID` | App Store Connect issuer UUID | UUID |
| `APPLE_KEY_ID` | App Store Connect In-App Purchase key ID | 10-char Key ID |
| `APPLE_PRIVATE_KEY` | App Store Connect `.p8` private key | `wrangler secret put APPLE_PRIVATE_KEY` |
| `APPLE_ROOT_CERTIFICATES` | Apple PKI Root Certs | Base64 DER array |
| `GOOGLE_PACKAGE_NAME` | Play Console package name | `com.puphr.crossscanmoto` |
| `GOOGLE_UNLOCK_PRODUCT_ID` | Play one-time product ID | `crossscanmoto_premium_unlock` |
| `GOOGLE_SERVICE_ACCOUNT_EMAIL` | Android Publisher Service Account | `*@*.iam.gserviceaccount.com` |
| `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`| Service account private key | `wrangler secret put GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY` |
| `PRICE_METADATA_USD` | Display metadata only | `24.99` |

## Local setup and deployment

From `backend/worker`:

```sh
pnpm install
pnpm test
pnpm exec wrangler d1 create crossscanmoto-payments
```

Copy the newly created D1 database ID into `wrangler.jsonc`, then apply migrations:

```sh
# Local migration:
pnpm db:migrate:local
pnpm dev

# Remote production deployment:
pnpm exec wrangler d1 migrations apply crossscanmoto-payments --remote
pnpm exec wrangler deploy
```

For local credential testing, use sandbox/test store products and a private local `.dev.vars` file. Do not put real private keys into tracked files. For a production environment, configure Wrangler secrets/vars and apply the remote D1 migration only after the app IDs and product IDs exist. `wrangler.jsonc` contains a deliberate database-ID placeholder; the worker has not been deployed.

The unit tests mock upstream stores and cover app/product/account mismatches, Apple revocation, Google pending state, acknowledgement, D1 idempotency, and replay attempts across accounts. They do not replace sandbox transactions or real Apple/Google credential tests. Before launch, test both stores' sandbox/license flows, verify Cloudflare's runtime support for Apple's verifier in the deployed Worker, and wire the client to use the same account UUID and configured products.

## API errors

The Worker returns short machine-readable error codes without echoing receipts or provider details. Missing configuration is `503 store_not_configured`; invalid evidence is `422`; pending Google payments are `409 purchase_pending`; token/transaction replay across identities is `409 purchase_replayed`; provider outages are `502`. All JSON responses use `Cache-Control: no-store`.

## Official API references

- [Apple App Store Server API](https://developer.apple.com/documentation/appstoreserverapi) and [Get Transaction Info](https://developer.apple.com/documentation/appstoreserverapi/get-transaction-info).
- [Apple App Store Server Node.js Library](https://github.com/apple/app-store-server-library-node), including `SignedDataVerifier` and obtaining Apple root certificates.
- [Google Play purchase verification guidance](https://developer.android.com/google/play/billing/security) recommends verifying purchase tokens with the Developer API before granting entitlements.
- [Google `purchases.productsv2.getproductpurchasev2`](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.productsv2) provides product, state, and obfuscated account identifiers.
- [Google product acknowledgement endpoint](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products/acknowledge).
