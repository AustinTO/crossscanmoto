const APPLE_PRODUCTION = 'Production';
const APPLE_SANDBOX = 'Sandbox';
const GOOGLE_SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token';
const GOOGLE_API = 'https://androidpublisher.googleapis.com/androidpublisher/v3';
const MAX_BODY_BYTES = 64 * 1024;
const ENTITLEMENT_ID = 'premium_unlock';
const SESSION_ISSUER = 'https://api.puphr.com';
const SESSION_AUDIENCE = 'com.puphr.crossscanmoto';
const SESSION_TTL_SECONDS = 7 * 24 * 60 * 60;
const googleTokenCache = new Map();

export class PurchaseError extends Error {
  constructor(status, code, message = code) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

export function purchaseVerificationConfiguration(env) {
  const has = (keys) => Boolean(env.DB) && keys.every((key) => typeof env[key] === 'string' && env[key].trim());
  return {
    apple: has(['APPLE_BUNDLE_ID', 'APPLE_UNLOCK_PRODUCT_ID', 'APPLE_ENVIRONMENT', 'APPLE_ISSUER_ID', 'APPLE_KEY_ID', 'APPLE_PRIVATE_KEY', 'APPLE_ROOT_CERTIFICATES']) &&
      ['Production', 'Sandbox'].includes(env.APPLE_ENVIRONMENT) &&
      (env.APPLE_ENVIRONMENT !== 'Production' || /^\d+$/.test(env.APPLE_APP_ID ?? '')),
    google: has(['GOOGLE_PACKAGE_NAME', 'GOOGLE_UNLOCK_PRODUCT_ID', 'GOOGLE_SERVICE_ACCOUNT_EMAIL', 'GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY']),
  };
}

// Evaluated only after OTP verification or requireSession's database checks.
// Never accept a VIP flag, email header, or request-body email as authority.
export function effectiveAccountAccess(verifiedEmail, storedEntitlement) {
  const vip = typeof verifiedEmail === 'string' &&
    verifiedEmail.trim().toLowerCase() === 'austintaylorodell@gmail.com';
  const unlocked = vip || storedEntitlement?.status === 'active';
  return {
    unlocked,
    status: unlocked ? 'active' : storedEntitlement?.status ?? 'none',
    vip,
    unlimited: vip,
    source: vip ? 'vip' : unlocked ? 'store' : 'none',
  };
}

function requireConfig(config, keys) {
  const missing = keys.filter((key) => !config[key]);
  if (missing.length) {
    throw new PurchaseError(503, 'store_not_configured', `Missing store configuration: ${missing.join(', ')}`);
  }
}

function validAccountId(value) {
  return typeof value === 'string' &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}

function requiredString(value, maxLength) {
  return typeof value === 'string' && value.length > 0 && value.length <= maxLength;
}

function validateRequestIdentity(accountId, productId) {
  if (!validAccountId(accountId)) throw new PurchaseError(400, 'invalid_account_id');
  if (!requiredString(productId, 200)) throw new PurchaseError(400, 'invalid_product_id');
}

function assertAppleTransaction(transaction, config, expected = {}) {
  if (!transaction || typeof transaction !== 'object') {
    throw new PurchaseError(422, 'invalid_transaction');
  }
  if (transaction.bundleId !== config.APPLE_BUNDLE_ID) {
    throw new PurchaseError(422, 'wrong_app');
  }
  if (transaction.productId !== config.APPLE_UNLOCK_PRODUCT_ID) {
    throw new PurchaseError(422, 'wrong_product');
  }
  if (transaction.type !== 'Non-Consumable') {
    throw new PurchaseError(422, 'wrong_product_type');
  }
  if (transaction.environment !== config.APPLE_ENVIRONMENT) {
    throw new PurchaseError(422, 'wrong_environment');
  }
  if (typeof transaction.transactionId !== 'string' ||
      (expected.transactionId && transaction.transactionId !== expected.transactionId)) {
    throw new PurchaseError(422, 'transaction_id_mismatch');
  }
  if (typeof transaction.appAccountToken !== 'string' ||
      transaction.appAccountToken.toLowerCase() !== expected.accountId?.toLowerCase()) {
    throw new PurchaseError(422, 'account_mismatch');
  }
  if (!Number.isSafeInteger(transaction.purchaseDate) || transaction.purchaseDate <= 0) {
    throw new PurchaseError(422, 'invalid_purchase_date');
  }
  if (transaction.revocationDate != null &&
      (!Number.isSafeInteger(transaction.revocationDate) || transaction.revocationDate <= 0)) {
    throw new PurchaseError(422, 'invalid_revocation_date');
  }
}

/** Verify the device JWS, retrieve Apple's authoritative transaction, then verify its JWS too. */
export async function verifyApplePurchase(body, config, deps, identity = {}) {
  const appleConfig = [
    'APPLE_BUNDLE_ID', 'APPLE_UNLOCK_PRODUCT_ID', 'APPLE_ENVIRONMENT',
    'APPLE_ISSUER_ID', 'APPLE_KEY_ID', 'APPLE_PRIVATE_KEY', 'APPLE_ROOT_CERTIFICATES',
  ];
  if (config.APPLE_ENVIRONMENT === APPLE_PRODUCTION) appleConfig.push('APPLE_APP_ID');
  requireConfig(config, appleConfig);
  if (![APPLE_PRODUCTION, APPLE_SANDBOX].includes(config.APPLE_ENVIRONMENT)) {
    throw new PurchaseError(503, 'store_not_configured');
  }
  if (config.APPLE_ENVIRONMENT === APPLE_PRODUCTION && !/^\d+$/.test(config.APPLE_APP_ID)) {
    throw new PurchaseError(503, 'store_not_configured');
  }
  const { transactionId, signedTransactionInfo } = body ?? {};
  const accountId = identity.accountId ?? body?.accountId;
  validateRequestIdentity(accountId, config.APPLE_UNLOCK_PRODUCT_ID);
  if (!requiredString(transactionId, 128) || !requiredString(signedTransactionInfo, 60_000)) {
    throw new PurchaseError(400, 'invalid_apple_receipt');
  }

  const deviceTransaction = await deps.verifySignedTransaction(signedTransactionInfo, config);
  const storeAccountId = identity.allowStoreAccountRecovery
    ? deviceTransaction.appAccountToken
    : identity.storeAccountId ?? accountId;
  if (!validAccountId(storeAccountId)) throw new PurchaseError(422, 'missing_app_account_token');
  assertAppleTransaction(deviceTransaction, config, { accountId: storeAccountId, transactionId });

  let response;
  try {
    response = await deps.lookupAppleTransaction(transactionId, config);
  } catch (error) {
    if (error instanceof PurchaseError) throw error;
    throw new PurchaseError(502, 'apple_unavailable');
  }
  if (!response?.signedTransactionInfo || typeof response.signedTransactionInfo !== 'string') {
    throw new PurchaseError(502, 'invalid_apple_response');
  }
  const serverTransaction = await deps.verifySignedTransaction(response.signedTransactionInfo, config);
  assertAppleTransaction(serverTransaction, config, { accountId: storeAccountId, transactionId });
  if (serverTransaction.originalTransactionId !== deviceTransaction.originalTransactionId ||
      serverTransaction.productId !== deviceTransaction.productId ||
      serverTransaction.appAccountToken?.toLowerCase() !== deviceTransaction.appAccountToken?.toLowerCase()) {
    throw new PurchaseError(422, 'transaction_mismatch');
  }

  return {
    store: 'apple',
    storeKey: serverTransaction.transactionId,
    transactionId: serverTransaction.transactionId,
    originalTransactionId: serverTransaction.originalTransactionId ?? null,
    accountId: accountId.toLowerCase(),
    storeAccountId: storeAccountId.toLowerCase(),
    productId: serverTransaction.productId,
    entitlementId: ENTITLEMENT_ID,
    purchasedAt: serverTransaction.purchaseDate,
    revokedAt: Number.isSafeInteger(serverTransaction.revocationDate) ? serverTransaction.revocationDate : null,
    state: serverTransaction.revocationDate ? 'revoked' : 'active',
  };
}

export async function verifyGooglePurchase(body, config, deps, identity = {}) {
  requireConfig(config, [
    'GOOGLE_PACKAGE_NAME', 'GOOGLE_UNLOCK_PRODUCT_ID',
    'GOOGLE_SERVICE_ACCOUNT_EMAIL', 'GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY',
  ]);
  const { purchaseToken } = body ?? {};
  const accountId = identity.accountId ?? body?.accountId;
  const storeAccountId = identity.storeAccountId ?? accountId;
  validateRequestIdentity(accountId, config.GOOGLE_UNLOCK_PRODUCT_ID);
  if (!validAccountId(storeAccountId)) throw new PurchaseError(400, 'invalid_account_id');
  if (!requiredString(purchaseToken, 4_000)) throw new PurchaseError(400, 'invalid_google_purchase_token');

  let purchase;
  try {
    purchase = await deps.lookupGooglePurchase(purchaseToken, config);
  } catch (error) {
    if (error instanceof PurchaseError) throw error;
    throw new PurchaseError(502, 'google_play_unavailable');
  }
  const lineItems = Array.isArray(purchase?.productLineItem) ? purchase.productLineItem : [];
  if (!lineItems.some((line) => line?.productId === config.GOOGLE_UNLOCK_PRODUCT_ID)) {
    throw new PurchaseError(422, 'wrong_product');
  }
  const expectedAccountId = await deps.hashAccountId(storeAccountId.toLowerCase());
  if (purchase.obfuscatedExternalAccountId !== expectedAccountId) {
    throw new PurchaseError(422, 'account_mismatch');
  }
  const state = purchase.purchaseStateContext?.purchaseState;
  if (state === 'PENDING') throw new PurchaseError(409, 'purchase_pending');
  if (state !== 'PURCHASED' && state !== 'CANCELLED') {
    throw new PurchaseError(422, 'invalid_purchase_state');
  }
  if (state === 'PURCHASED' && !purchase.purchaseCompletionTime) {
    throw new PurchaseError(422, 'purchase_incomplete');
  }
  if (state === 'PURCHASED' && !Number.isFinite(Date.parse(purchase.purchaseCompletionTime))) {
    throw new PurchaseError(422, 'invalid_purchase_date');
  }
  if (state === 'PURCHASED' && ![
    'ACKNOWLEDGEMENT_STATE_PENDING', 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED',
  ].includes(purchase.acknowledgementState)) {
    throw new PurchaseError(422, 'invalid_acknowledgement_state');
  }
  if (purchase.testPurchaseContext && config.GOOGLE_ALLOW_TEST_PURCHASES !== 'true') {
    throw new PurchaseError(422, 'test_purchase_not_allowed');
  }

  if (state === 'PURCHASED' &&
      purchase.acknowledgementState === 'ACKNOWLEDGEMENT_STATE_PENDING') {
    try {
      await deps.acknowledgeGooglePurchase(purchaseToken, config);
    } catch (_) {
      // Do not issue access until Google accepts acknowledgement; the caller can safely retry.
      throw new PurchaseError(502, 'google_acknowledgement_failed');
    }
  }

  const storeKey = await deps.hashPurchaseToken(purchaseToken);
  return {
    store: 'google',
    storeKey,
    transactionId: purchase.orderId || storeKey,
    originalTransactionId: null,
    accountId: accountId.toLowerCase(),
    storeAccountId: storeAccountId.toLowerCase(),
    productId: config.GOOGLE_UNLOCK_PRODUCT_ID,
    entitlementId: ENTITLEMENT_ID,
    purchasedAt: state === 'PURCHASED' ? Date.parse(purchase.purchaseCompletionTime) : Date.now(),
    revokedAt: state === 'CANCELLED' ? Date.now() : null,
    state: state === 'PURCHASED' ? 'active' : 'revoked',
  };
}

function utf8(value) {
  return new TextEncoder().encode(value);
}

function base64Url(bytes) {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

function decodeBase64(value) {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_+/-]*={0,2}$/.test(value)) {
    throw new Error('Invalid base64url value');
  }
  const normalized = value.replace(/-/g, '+').replace(/_/g, '/').replace(/=+$/, '');
  if (normalized.length % 4 === 1) throw new Error('Invalid base64url length');
  const binary = atob(normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '='));
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function pemToDer(pem) {
  return decodeBase64(pem.replace(/-----BEGIN [^-]+-----|-----END [^-]+-----|\s/g, ''));
}

async function signJwt(header, claims, key, algorithm) {
  const encodedHeader = base64Url(utf8(JSON.stringify(header)));
  const encodedClaims = base64Url(utf8(JSON.stringify(claims)));
  const signingInput = `${encodedHeader}.${encodedClaims}`;
  const signature = await crypto.subtle.sign(algorithm, key, utf8(signingInput));
  return `${signingInput}.${base64Url(new Uint8Array(signature))}`;
}

async function appleApiToken(config) {
  const key = await crypto.subtle.importKey(
    'pkcs8', pemToDer(config.APPLE_PRIVATE_KEY),
    { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign'],
  );
  const now = Math.floor(Date.now() / 1000);
  return signJwt(
    { alg: 'ES256', kid: config.APPLE_KEY_ID, typ: 'JWT' },
    { iss: config.APPLE_ISSUER_ID, iat: now, exp: now + 300,
      aud: 'appstoreconnect-v1', bid: config.APPLE_BUNDLE_ID },
    key, { name: 'ECDSA', hash: 'SHA-256' },
  );
}

export async function lookupAppleTransaction(transactionId, config, fetchImpl = fetch) {
  const host = config.APPLE_ENVIRONMENT === APPLE_SANDBOX
    ? 'https://api.storekit-sandbox.apple.com'
    : 'https://api.storekit.apple.com';
  const token = await appleApiToken(config);
  const response = await fetchImpl(`${host}/inApps/v1/transactions/${encodeURIComponent(transactionId)}`, {
    headers: { authorization: `Bearer ${token}`, accept: 'application/json' },
  });
  if (response.status === 404) throw new PurchaseError(422, 'transaction_not_found');
  if (!response.ok) throw new PurchaseError(502, 'apple_unavailable');
  return response.json();
}

async function googleAccessToken(config, fetchImpl = fetch) {
  const cached = googleTokenCache.get(config.GOOGLE_SERVICE_ACCOUNT_EMAIL);
  if (cached && cached.expiresAt > Date.now() + 60_000) return cached.token;
  const key = await crypto.subtle.importKey(
    'pkcs8', pemToDer(config.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'],
  );
  const now = Math.floor(Date.now() / 1000);
  const assertion = await signJwt(
    { alg: 'RS256', typ: 'JWT' },
    { iss: config.GOOGLE_SERVICE_ACCOUNT_EMAIL, scope: GOOGLE_SCOPE,
      aud: GOOGLE_TOKEN_URL, iat: now, exp: now + 3600 },
    key, 'RSASSA-PKCS1-v1_5',
  );
  const response = await fetchImpl(GOOGLE_TOKEN_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion,
    }),
  });
  if (!response.ok) throw new PurchaseError(502, 'google_auth_failed');
  const body = await response.json();
  if (typeof body.access_token !== 'string' || !Number.isFinite(body.expires_in)) {
    throw new PurchaseError(502, 'google_auth_failed');
  }
  googleTokenCache.set(config.GOOGLE_SERVICE_ACCOUNT_EMAIL, {
    token: body.access_token, expiresAt: Date.now() + body.expires_in * 1000,
  });
  return body.access_token;
}

async function googleApiRequest(path, config, fetchImpl = fetch, options = {}) {
  const token = await googleAccessToken(config, fetchImpl);
  const response = await fetchImpl(`${GOOGLE_API}${path}`, {
    ...options,
    headers: { authorization: `Bearer ${token}`, ...(options.headers ?? {}) },
  });
  if (!response.ok) {
    if (response.status === 404) throw new PurchaseError(422, 'purchase_not_found');
    throw new PurchaseError(502, 'google_play_unavailable');
  }
  if (options.expectJson === false || response.status === 204 || response.headers.get('content-length') === '0') return null;
  return response.json();
}

export async function lookupGooglePurchase(purchaseToken, config, fetchImpl = fetch) {
  const packageName = encodeURIComponent(config.GOOGLE_PACKAGE_NAME);
  const token = encodeURIComponent(purchaseToken);
  return googleApiRequest(
    `/applications/${packageName}/purchases/productsv2/tokens/${token}`,
    config, fetchImpl,
  );
}

export async function acknowledgeGooglePurchase(purchaseToken, config, fetchImpl = fetch) {
  const packageName = encodeURIComponent(config.GOOGLE_PACKAGE_NAME);
  const productId = encodeURIComponent(config.GOOGLE_UNLOCK_PRODUCT_ID);
  const token = encodeURIComponent(purchaseToken);
  await googleApiRequest(
    `/applications/${packageName}/purchases/products/${productId}/tokens/${token}:acknowledge`,
    config, fetchImpl, { method: 'POST', headers: { 'content-type': 'application/json' }, body: '{}', expectJson: false },
  );
}

export async function verifyAppleSignedTransaction(signedTransactionInfo, config) {
  requireConfig(config, ['APPLE_BUNDLE_ID', 'APPLE_ENVIRONMENT', 'APPLE_ROOT_CERTIFICATES']);
  let encodedRoots;
  try {
    encodedRoots = JSON.parse(config.APPLE_ROOT_CERTIFICATES);
  } catch (_) {
    throw new PurchaseError(503, 'apple_verification_not_configured');
  }
  if (!Array.isArray(encodedRoots) || encodedRoots.length === 0 ||
      encodedRoots.some((certificate) => typeof certificate !== 'string' || certificate.length < 100)) {
    throw new PurchaseError(503, 'apple_verification_not_configured');
  }
  try {
    const { Environment, SignedDataVerifier } = await import('@apple/app-store-server-library');
    const environment = config.APPLE_ENVIRONMENT === APPLE_PRODUCTION
      ? Environment.PRODUCTION : Environment.SANDBOX;
    const roots = encodedRoots.map((certificate) => Buffer.from(certificate, 'base64'));
    const verifier = new SignedDataVerifier(
      roots, true, environment, config.APPLE_BUNDLE_ID,
      environment === Environment.PRODUCTION ? Number(config.APPLE_APP_ID) : undefined,
    );
    return await verifier.verifyAndDecodeTransaction(signedTransactionInfo);
  } catch (_) {
    throw new PurchaseError(422, 'invalid_apple_signature');
  }
}

export async function hashHex(value) {
  const digest = await crypto.subtle.digest('SHA-256', utf8(value));
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

export async function hashOtpCode(code, salt, pepper) {
  requireSecret(pepper, 'otp');
  const key = await crypto.subtle.importKey(
    'raw', utf8(pepper), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'HMAC', key, utf8(`crossscanmoto-otp-v1:${salt}:${code}`),
  );
  return [...new Uint8Array(signature)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

function constantTimeEqual(left, right) {
  if (typeof left !== 'string' || typeof right !== 'string' || left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index++) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return difference === 0;
}

export function validEmail(email) {
  return typeof email === 'string' &&
    email.length <= 254 &&
    /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/.test(email);
}

export function formatOtpEmail(fromAddress, fromName, toEmail, code) {
  const boundary = `boundary_crossscan_${Date.now()}`;
  const subject = `Your CrossScan Moto Login Code: ${code}`;
  const dateStr = new Date().toUTCString();
  const messageId = `<otp-${Date.now()}-${Math.random().toString(36).slice(2, 8)}@auth.trusthentic.com>`;

  const textBody = [
    `CrossScan Moto — Workshop Diagnostic Suite`,
    `Developed by Puphr LLC`,
    ``,
    `Your one-time verification code is:`,
    `   ${code}`,
    ``,
    `This code will expire in 10 minutes.`,
    `Enter this code in CrossScan Moto to verify your email and sync your purchases and coding backups.`,
    ``,
    `If you did not request this login code, you can safely ignore this message.`,
    ``,
    `Support: https://auth.trusthentic.com • Puphr LLC`,
  ].join('\r\n');

  const htmlBody = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0b0f14; color: #e6edf3; padding: 30px 15px; margin: 0; }
    .card { max-width: 520px; margin: 0 auto; background: #161b22; border: 1px solid #30363d; border-radius: 10px; padding: 32px; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 6px; background: rgba(188, 235, 88, 0.12); color: #bceb58; font-size: 13px; font-weight: 600; margin-bottom: 16px; border: 1px solid rgba(188, 235, 88, 0.3); }
    h1 { color: #ffffff; font-size: 22px; margin: 0 0 16px; font-weight: 700; }
    p { font-size: 14px; line-height: 1.6; color: #8b949e; margin: 0 0 20px; }
    .code-box { background: #090c10; border: 2px dashed #bceb58; border-radius: 8px; padding: 18px; text-align: center; margin: 24px 0; }
    .code { font-family: monospace; font-size: 32px; letter-spacing: 8px; font-weight: bold; color: #bceb58; }
    .footer { border-top: 1px solid #30363d; margin-top: 24px; padding-top: 16px; font-size: 12px; color: #6e7681; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">CrossScan Moto • Puphr LLC</div>
    <h1>Verify Your Workshop Account</h1>
    <p>Use the 6-digit verification code below to link your email account and synchronize purchases and vehicle backups:</p>
    <div class="code-box">
      <div class="code">${code}</div>
    </div>
    <p>This verification code is valid for <strong>10 minutes</strong>. If you did not initiate this request, no action is required.</p>
    <div class="footer">
      Sent via auth.trusthentic.com by Puphr LLC for CrossScan Moto.<br>
      © 2026 Puphr LLC. All rights reserved.
    </div>
  </div>
</body>
</html>`;

  return [
    `From: "${fromName}" <${fromAddress}>`,
    `To: <${toEmail}>`,
    `Subject: ${subject}`,
    `Date: ${dateStr}`,
    `Message-ID: ${messageId}`,
    `MIME-Version: 1.0`,
    `Content-Type: multipart/alternative; boundary="${boundary}"`,
    ``,
    `--${boundary}`,
    `Content-Type: text/plain; charset=UTF-8`,
    `Content-Transfer-Encoding: 7bit`,
    ``,
    textBody,
    ``,
    `--${boundary}`,
    `Content-Type: text/html; charset=UTF-8`,
    `Content-Transfer-Encoding: 7bit`,
    ``,
    htmlBody,
    ``,
    `--${boundary}--`,
  ].join('\r\n');
}

export async function sendOtpEmail(email, code, env, sendEmailImpl) {
  if (sendEmailImpl) {
    return sendEmailImpl(email, code);
  }
  if (!env?.EMAIL || typeof env.EMAIL.send !== 'function') {
    throw new PurchaseError(503, 'email_delivery_not_configured');
  }
  const fromAddress = env?.EMAIL_FROM_ADDRESS || 'noreply@auth.trusthentic.com';
  const fromName = env?.EMAIL_FROM_NAME || 'CrossScan Moto';
  const raw = formatOtpEmail(fromAddress, fromName, email, code);

  if (env?.EMAIL && typeof env.EMAIL.send === 'function') {
    let EmailMessageClass = globalThis.EmailMessage;
    if (!EmailMessageClass) {
      try {
        const mod = await import('cloudflare:email');
        EmailMessageClass = mod.EmailMessage;
      } catch (_) {
        EmailMessageClass = class {
          constructor(from, to, raw) { this.from = from; this.to = to; this.raw = raw; }
        };
      }
    }
    const msg = new EmailMessageClass(fromAddress, email, raw);
    await env.EMAIL.send(msg);
  }
}

function requireSecret(secret, purpose) {
  if (typeof secret !== 'string' || utf8(secret).byteLength < 32) {
    throw new PurchaseError(503, `${purpose}_not_configured`);
  }
}

export async function createSessionToken(user, secret, options = {}) {
  requireSecret(secret, 'auth');
  const userId = user.userId || user.user_id;
  const accountId = user.accountId || user.account_id;
  if (!validAccountId(userId) || !validAccountId(accountId) || !validEmail(user.email)) {
    throw new PurchaseError(500, 'invalid_session_identity');
  }
  const header = { alg: 'HS256', typ: 'JWT' };
  const now = options.nowSeconds ?? Math.floor(Date.now() / 1000);
  const claims = {
    sub: userId,
    email: user.email,
    accountId,
    iat: now,
    nbf: now,
    exp: now + SESSION_TTL_SECONDS,
    iss: SESSION_ISSUER,
    aud: SESSION_AUDIENCE,
    jti: options.sessionId ?? crypto.randomUUID(),
  };
  const key = await crypto.subtle.importKey(
    'raw',
    utf8(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  return signJwt(header, claims, key, { name: 'HMAC' });
}

export async function verifySessionToken(token, secret, nowSeconds = Math.floor(Date.now() / 1000)) {
  if (typeof token !== 'string') return null;
  try {
    requireSecret(secret, 'auth');
  } catch (_) {
    return null;
  }
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const [encodedHeader, encodedClaims, encodedSignature] = parts;
  try {
    const header = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(decodeBase64(encodedHeader)));
    if (header?.alg !== 'HS256' || header?.typ !== 'JWT') return null;
    const key = await crypto.subtle.importKey(
      'raw',
      utf8(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify'],
    );
    const signingInput = `${encodedHeader}.${encodedClaims}`;
    const signature = decodeBase64(encodedSignature);
    const valid = await crypto.subtle.verify(
      { name: 'HMAC' },
      key,
      signature,
      utf8(signingInput),
    );
    if (!valid) return null;
    const claims = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(decodeBase64(encodedClaims)));
    if (claims.iss !== SESSION_ISSUER || claims.aud !== SESSION_AUDIENCE ||
        !validAccountId(claims.sub) || !validAccountId(claims.accountId) ||
        !validAccountId(claims.jti) || !validEmail(claims.email) ||
        !Number.isSafeInteger(claims.iat) || !Number.isSafeInteger(claims.nbf) ||
        !Number.isSafeInteger(claims.exp) || claims.iat > nowSeconds + 60 ||
        claims.nbf > nowSeconds + 60 || claims.exp <= nowSeconds ||
        claims.exp <= claims.iat || claims.exp - claims.iat > SESSION_TTL_SECONDS) {
      return null;
    }
    return claims;
  } catch (_) {
    return null;
  }
}

export class D1PurchaseRepository {
  constructor(db) {
    this.db = db;
  }

  async applyPurchase(purchase, { userId, allowStoreAccountRebind = false } = {}) {
    const storeAccountId = purchase.storeAccountId ?? purchase.accountId;
    const existing = await this.db.prepare(
      'SELECT account_id, store_account_id, product_id FROM purchase_records WHERE store = ? AND store_key = ?',
    ).bind(purchase.store, purchase.storeKey).first();
    if (existing && (existing.account_id !== purchase.accountId ||
        existing.store_account_id !== storeAccountId || existing.product_id !== purchase.productId) &&
        !(allowStoreAccountRebind && existing.store_account_id === storeAccountId &&
          existing.product_id === purchase.productId)) {
      throw new PurchaseError(409, 'purchase_replayed');
    }
    const existingTransaction = await this.db.prepare(
      'SELECT account_id, store_key, store_account_id, product_id FROM purchase_records WHERE store = ? AND transaction_id = ?',
    ).bind(purchase.store, purchase.transactionId).first();
    if (existingTransaction && (existingTransaction.account_id !== purchase.accountId ||
        existingTransaction.store_account_id !== storeAccountId || existingTransaction.product_id !== purchase.productId) &&
        !(allowStoreAccountRebind && existingTransaction.store_account_id === storeAccountId &&
          existingTransaction.product_id === purchase.productId && existingTransaction.store_key === purchase.storeKey)) {
      throw new PurchaseError(409, 'purchase_replayed');
    }
    if (userId) {
      const existingLink = await this.findStoreAccountLink(purchase.store, storeAccountId);
      if (existingLink && existingLink.user_id !== userId) {
        throw new PurchaseError(409, 'store_account_already_linked');
      }
      const existingUser = await this.findUserByAccountId(storeAccountId);
      if (existingUser && existingUser.user_id !== userId) {
        throw new PurchaseError(409, 'store_account_already_linked');
      }
    }
    const now = Date.now();
    const previousAccountId = existing?.account_id ?? existingTransaction?.account_id ?? null;
    try {
      const statements = [];
      if (userId) {
        statements.push(this.db.prepare(`
          INSERT INTO store_account_links (store, store_account_id, user_id, account_id, created_at)
          VALUES (?, ?, ?, ?, ?)
          ON CONFLICT(store, store_account_id) DO UPDATE SET account_id = excluded.account_id
          WHERE store_account_links.user_id = excluded.user_id
        `).bind(purchase.store, storeAccountId, userId, purchase.accountId, now));
      }
      const purchaseStatement = this.db.prepare(`
        INSERT INTO purchase_records
          (store, store_key, transaction_id, original_transaction_id, account_id,
           store_account_id, product_id, entitlement_id, state, purchased_at,
           revoked_at, created_at, updated_at)
        SELECT ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        WHERE ? IS NULL OR EXISTS (
          SELECT 1 FROM store_account_links
          WHERE store = ? AND store_account_id = ? AND user_id = ?
        )
        ON CONFLICT(store, store_key) DO UPDATE SET
          account_id = excluded.account_id,
          state = excluded.state,
          purchased_at = excluded.purchased_at,
          revoked_at = excluded.revoked_at,
          updated_at = excluded.updated_at
        WHERE purchase_records.store_account_id = excluded.store_account_id
          AND purchase_records.product_id = excluded.product_id
          AND (purchase_records.account_id = excluded.account_id OR ? = 1)
      `).bind(purchase.store, purchase.storeKey, purchase.transactionId,
        purchase.originalTransactionId, purchase.accountId, storeAccountId, purchase.productId,
        purchase.entitlementId, purchase.state, purchase.purchasedAt, purchase.revokedAt, now, now,
        userId ?? null, purchase.store, storeAccountId, userId ?? '', Number(allowStoreAccountRebind));
      const purchaseStatementIndex = statements.length;
      statements.push(purchaseStatement);
      statements.push(this.db.prepare(`
        INSERT INTO entitlements (account_id, entitlement_id, status, updated_at)
        VALUES (?, ?, CASE WHEN EXISTS (
          SELECT 1 FROM purchase_records
          WHERE account_id = ? AND entitlement_id = ? AND state = 'active'
        ) THEN 'active' ELSE 'revoked' END, ?)
        ON CONFLICT(account_id, entitlement_id) DO UPDATE SET
          status = excluded.status,
          updated_at = excluded.updated_at
      `).bind(purchase.accountId, purchase.entitlementId, purchase.accountId,
        purchase.entitlementId, now));
      if (previousAccountId && previousAccountId !== purchase.accountId) {
        statements.push(this.db.prepare(`
          INSERT INTO entitlements (account_id, entitlement_id, status, updated_at)
          VALUES (?, ?, CASE WHEN EXISTS (
            SELECT 1 FROM purchase_records
            WHERE account_id = ? AND entitlement_id = ? AND state = 'active'
          ) THEN 'active' ELSE 'revoked' END, ?)
          ON CONFLICT(account_id, entitlement_id) DO UPDATE SET
            status = excluded.status, updated_at = excluded.updated_at
        `).bind(previousAccountId, purchase.entitlementId, previousAccountId,
          purchase.entitlementId, now));
      }
      const results = await this.db.batch(statements);
      if (userId && Number(results[purchaseStatementIndex]?.meta?.changes ?? 0) === 0) {
        throw new PurchaseError(409, 'store_account_already_linked');
      }
    } catch (error) {
      if (error instanceof PurchaseError) throw error;
      // D1's unique constraints decide a simultaneous first claim. Only treat
      // the losing request as an idempotent replay when the committed owner
      // and product match this verified purchase.
      const committed = await this.db.prepare(
        'SELECT account_id, store_account_id, product_id FROM purchase_records WHERE store = ? AND transaction_id = ?',
      ).bind(purchase.store, purchase.transactionId).first();
      if (!committed) throw error;
      if (committed.store_account_id !== storeAccountId || committed.product_id !== purchase.productId ||
          committed.account_id !== purchase.accountId) {
        throw new PurchaseError(409, 'purchase_replayed');
      }
      const entitlement = await this.getEntitlement(purchase.accountId, purchase.entitlementId);
      return { idempotent: true, entitlement };
    }
    const entitlement = await this.getEntitlement(purchase.accountId, purchase.entitlementId);
    return { idempotent: Boolean(existing || existingTransaction), entitlement };
  }

  async getEntitlement(accountId, productId) {
    return this.db.prepare(
      'SELECT status, updated_at FROM entitlements WHERE account_id = ? AND entitlement_id = ?',
    ).bind(accountId, productId).first();
  }

  async findGooglePurchaseOwner(purchaseTokenHash) {
    return this.db.prepare(`
      SELECT account_id, store_account_id, product_id, entitlement_id, state
      FROM purchase_records
      WHERE store = 'google' AND store_key = ?
    `).bind(purchaseTokenHash).first();
  }

  async findStoreAccountLink(store, storeAccountId) {
    return this.db.prepare(`
      SELECT store, store_account_id, user_id, account_id
      FROM store_account_links WHERE store = ? AND store_account_id = ?
    `).bind(store, storeAccountId).first();
  }

  async saveSession({ sessionId, userId, email, accountId, expiresAt }) {
    await this.db.prepare(`
      INSERT INTO auth_sessions
        (session_id, user_id, email, account_id, created_at, expires_at, revoked_at)
      VALUES (?, ?, ?, ?, ?, ?, NULL)
    `).bind(sessionId, userId, email.toLowerCase(), accountId, Date.now(), expiresAt).run();
  }

  async findSession(sessionId) {
    return this.db.prepare(`
      SELECT session_id, user_id, email, account_id, created_at, expires_at, revoked_at
      FROM auth_sessions WHERE session_id = ?
    `).bind(sessionId).first();
  }

  async revokeSession(sessionId, now = Date.now()) {
    await this.db.prepare(`
      UPDATE auth_sessions SET revoked_at = ?
      WHERE session_id = ? AND revoked_at IS NULL
    `).bind(now, sessionId).run();
  }

  async deleteAccount(accountId) {
    const id = accountId.toLowerCase();
    const user = await this.findUserByAccountId(id);
    await this.db.batch([
      this.db.prepare('DELETE FROM entitlements WHERE account_id = ?').bind(id),
      this.db.prepare('DELETE FROM purchase_records WHERE account_id = ?').bind(id),
      this.db.prepare('DELETE FROM users WHERE account_id = ?').bind(id),
      this.db.prepare('UPDATE auth_sessions SET revoked_at = ? WHERE account_id = ? AND revoked_at IS NULL')
        .bind(Date.now(), id),
      ...(user ? [this.db.prepare('DELETE FROM auth_otps WHERE email = ?').bind(user.email)] : []),
      ...(user ? [this.db.prepare('DELETE FROM store_account_links WHERE user_id = ?').bind(user.user_id)] : []),
    ]);
    return { deleted: true, accountId: id };
  }

  async saveOtp(email, codeHash, salt, expiresAt) {
    const now = Date.now();
    await this.db.prepare(`
      INSERT INTO auth_otps (email, code_hash, salt, attempts, expires_at, created_at)
      VALUES (?, ?, ?, 0, ?, ?)
      ON CONFLICT(email) DO UPDATE SET
        code_hash = excluded.code_hash,
        salt = excluded.salt,
        attempts = 0,
        expires_at = excluded.expires_at,
        created_at = excluded.created_at
    `).bind(email.toLowerCase(), codeHash, salt, expiresAt, now).run();
  }

  async getOtp(email) {
    return this.db.prepare(
      'SELECT email, code_hash, salt, attempts, expires_at, created_at FROM auth_otps WHERE email = ?',
    ).bind(email.toLowerCase()).first();
  }

  async incrementOtpAttempts(email) {
    await this.db.prepare(
      'UPDATE auth_otps SET attempts = attempts + 1 WHERE email = ? AND attempts < 5 AND expires_at > ?',
    ).bind(email.toLowerCase(), Date.now()).run();
  }

  async consumeOtp(email, codeHash, now = Date.now()) {
    return this.db.prepare(`
      DELETE FROM auth_otps
      WHERE email = ? AND code_hash = ? AND attempts < 5 AND expires_at > ?
      RETURNING email
    `).bind(email.toLowerCase(), codeHash, now).first();
  }

  async consumeRateLimit(rateKey, maxRequests, windowMs, now = Date.now()) {
    const windowStart = Math.floor(now / windowMs) * windowMs;
    const result = await this.db.prepare(`
      INSERT INTO auth_rate_limits (rate_key, window_start, request_count, expires_at)
      VALUES (?, ?, 1, ?)
      ON CONFLICT(rate_key) DO UPDATE SET
        request_count = CASE
          WHEN auth_rate_limits.window_start = excluded.window_start
          THEN auth_rate_limits.request_count + 1 ELSE 1 END,
        window_start = excluded.window_start,
        expires_at = excluded.expires_at
      RETURNING request_count
    `).bind(rateKey, windowStart, windowStart + windowMs).first();
    return Number(result?.request_count ?? maxRequests + 1) <= maxRequests;
  }

  async cleanupExpiredRateLimits(now = Date.now()) {
    await this.db.prepare('DELETE FROM auth_rate_limits WHERE expires_at < ?').bind(now).run();
  }

  async deleteOtp(email) {
    await this.db.prepare('DELETE FROM auth_otps WHERE email = ?').bind(email.toLowerCase()).run();
  }

  async findUserByEmail(email) {
    return this.db.prepare(
      'SELECT user_id, email, account_id, created_at, updated_at FROM users WHERE email = ?',
    ).bind(email.toLowerCase()).first();
  }

  async findUserByAccountId(accountId) {
    return this.db.prepare(
      'SELECT user_id, email, account_id, created_at, updated_at FROM users WHERE account_id = ?',
    ).bind(accountId.toLowerCase()).first();
  }

  async findUserById(userId) {
    return this.db.prepare(
      'SELECT user_id, email, account_id, created_at, updated_at FROM users WHERE user_id = ?',
    ).bind(userId).first();
  }

  async createUserIfAbsent(email) {
    const normalizedEmail = email.toLowerCase();
    const now = Date.now();
    await this.db.prepare(`
      INSERT INTO users (user_id, email, account_id, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(email) DO NOTHING
    `).bind(crypto.randomUUID(), normalizedEmail, crypto.randomUUID(), now, now).run();
    return this.findUserByEmail(normalizedEmail);
  }

  async upsertUser(email, accountId) {
    return (await this.findUserByEmail(email)) ?? this.createUserIfAbsent(email);
  }
}

function configFromEnv(env) {
  return Object.fromEntries([
    'APPLE_BUNDLE_ID', 'APPLE_UNLOCK_PRODUCT_ID', 'APPLE_ENVIRONMENT',
    'APPLE_ISSUER_ID', 'APPLE_KEY_ID', 'APPLE_PRIVATE_KEY', 'APPLE_APP_ID',
    'APPLE_ROOT_CERTIFICATES', 'GOOGLE_PACKAGE_NAME', 'GOOGLE_UNLOCK_PRODUCT_ID',
    'GOOGLE_SERVICE_ACCOUNT_EMAIL', 'GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY',
    'GOOGLE_ALLOW_TEST_PURCHASES',
  ].map((key) => [key, env[key]]));
}

export async function requireSession(request, env, repository, now = Date.now()) {
  requireSecret(env?.SESSION_SECRET, 'auth');
  const match = (request.headers.get('authorization') ?? '').match(/^Bearer\s+([^\s]+)$/i);
  if (!match || match[1].length > 4096) throw new PurchaseError(401, 'unauthorized');
  const claims = await verifySessionToken(match[1], env.SESSION_SECRET, Math.floor(now / 1000));
  if (!claims) throw new PurchaseError(401, 'invalid_session');
  const [session, user] = await Promise.all([
    repository.findSession(claims.jti),
    repository.findUserById(claims.sub),
  ]);
  if (!session || session.revoked_at != null || session.expires_at <= now ||
      Math.abs(session.expires_at - claims.exp * 1000) > 1000 ||
      session.user_id !== claims.sub || session.email !== claims.email ||
      session.account_id !== claims.accountId || !user ||
      user.email !== claims.email || user.account_id !== claims.accountId) {
    throw new PurchaseError(401, 'invalid_session');
  }
  return claims;
}

const SECURITY_HEADERS = {
  'content-security-policy': "default-src 'self' 'unsafe-inline'; img-src 'self' data:;",
  'x-content-type-options': 'nosniff',
  'x-frame-options': 'DENY',
  'strict-transport-security': 'max-age=31536000; includeSubDomains',
  'referrer-policy': 'strict-origin-when-cross-origin',
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, DELETE, OPTIONS',
  'access-control-allow-headers': 'content-type, authorization',
};

function htmlResponse(html, status = 200) {
  return new Response(html, {
    status,
    headers: {
      ...SECURITY_HEADERS,
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'public, max-age=3600',
    },
  });
}

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...SECURITY_HEADERS,
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  });
}

function renderPrivacyPolicyHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Privacy Policy — CrossScan Moto | Puphr LLC</title>
  <style>
    :root { --bg: #090c10; --panel: #161b22; --border: #30363d; --text: #e6edf3; --muted: #8b949e; --lime: #bceb58; }
    body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; margin: 0; padding: 40px 20px; }
    .container { max-width: 820px; margin: 0 auto; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 6px; background: rgba(188, 235, 88, 0.12); color: var(--lime); border: 1px solid rgba(188, 235, 88, 0.3); font-size: 13px; font-weight: 600; margin-bottom: 12px; }
    h1 { color: #fff; margin: 4px 0 8px 0; font-size: 28px; }
    h2 { color: #fff; border-bottom: 1px solid var(--border); padding-bottom: 8px; margin-top: 36px; font-size: 20px; }
    .company { color: var(--muted); font-size: 14px; margin-bottom: 24px; }
    .card { background: var(--panel); border: 1px solid var(--border); border-radius: 8px; padding: 20px; margin: 20px 0; }
    a { color: var(--lime); text-decoration: none; }
    a:hover { text-decoration: underline; }
    .footer { margin-top: 50px; padding-top: 24px; border-top: 1px solid var(--border); font-size: 13px; color: var(--muted); }
  </style>
</head>
<body>
  <div class="container">
    <div class="badge">Official Puphr LLC Policy</div>
    <h1>Privacy Policy for CrossScan Moto</h1>
    <div class="company">Published by Puphr LLC • Effective Date: October 31, 2026</div>

    <div class="card">
      <strong>Core Privacy Guarantee:</strong> CrossScan Moto operates with a privacy-by-design architecture. Your vehicle diagnostics, live sensor telemetry, trouble codes, and VIN numbers stay strictly on your device. Puphr LLC does not collect, transmit, store, or sell vehicle diagnostic data or location telemetry.
    </div>

    <h2>1. Information We Do Not Collect</h2>
    <p>CrossScan Moto connects directly to your motorcycle's Electronic Control Units (ECUs) via standard hardware adapters (OBDLink, UniCarScan, vLinker, or ELM327) using local Bluetooth or Wi-Fi. All diagnostic commands, real-time telemetry, adaptation resets, fault code scans, and coding parameters are processed entirely on your local device.</p>
    <ul>
      <li>We do not record, transmit, or log vehicle VINs or serial numbers.</li>
      <li>We do not collect live vehicle sensor telemetry (RPM, speed, temperatures, pressures).</li>
      <li>We do not access or track GPS location data.</li>
      <li>We do not share, monetize, or sell diagnostic histories to third parties or data brokers.</li>
    </ul>

    <h2>2. Store Purchases & Account Data</h2>
    <p>CrossScan Moto generates a random account UUID and stores it securely on your device. If you link an email using a one-time verification code, the server associates that verified email with its canonical account UUID so you can recover purchases on another device.</p>
    <p>When you complete a purchase, Apple App Store Server API (JWS) or Google Play Billing API receipts are verified by our Cloudflare Worker backend. We store:</p>
    <ul>
      <li>Your account UUID and, if linked, your verified email address and an expiring session record.</li>
      <li>Store transaction identifiers, purchase state, and store-account binding identifiers for entitlement and replay checks. Google purchase tokens are stored as hashes.</li>
      <li>Active entitlement status (e.g. <code>premium_unlock</code>).</li>
    </ul>

    <h2>3. Cloudflare Infrastructure & Data Security</h2>
    <p>Our verification backend is hosted on Cloudflare Workers with Cloudflare D1 encrypted database storage. All network requests strictly enforce TLS 1.3 encryption, HTTP Strict Transport Security (HSTS), and Content Security Policies. Server logs are minimized and purged routinely.</p>

    <h2>4. Account & Data Deletion Rights</h2>
    <p>You have the absolute right to delete all server-stored identifiers, purchase records, and entitlements at any time:</p>
    <ul>
      <li><strong>In-App:</strong> Open CrossScan Moto &gt; tap <em>Preferences</em> &gt; select <em>Delete Account &amp; Data</em>.</li>
      <li><strong>Authenticated deletion:</strong> Sign in in CrossScan Moto and choose <em>Preferences &gt; Delete Account &amp; Data</em>. The server deletes account, purchase, entitlement, and session records for that account.</li>
      <li><strong>Help:</strong> If you cannot sign in, contact <a href="mailto:privacy@puphr.com">privacy@puphr.com</a> for account recovery and deletion assistance.</li>
    </ul>
    <p>Upon request, your records are immediately and permanently erased from our Cloudflare D1 database.</p>

    <h2>5. Compliance with Global Regulations</h2>
    <p>Puphr LLC complies with the General Data Protection Regulation (GDPR), California Consumer Privacy Act (CCPA/CPRA), and Apple App Store / Google Play developer guidelines regarding data minimization and user deletion rights.</p>

    <h2>6. Contact Information</h2>
    <p>If you have any questions regarding this Privacy Policy or Puphr LLC data practices, please contact:</p>
    <p>
      <strong>Puphr LLC</strong><br>
      Privacy &amp; Security Team<br>
      Email: <a href="mailto:privacy@puphr.com">privacy@puphr.com</a><br>
      Support: <a href="mailto:support@puphr.com">support@puphr.com</a>
    </p>

    <div class="footer">
      &copy; 2026 Puphr LLC. All rights reserved. CrossScan Moto is an independent software product developed by Puphr LLC.
    </div>
  </div>
</body>
</html>`;
}

function renderTermsHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Terms of Service — CrossScan Moto | Puphr LLC</title>
  <style>
    :root { --bg: #090c10; --panel: #161b22; --border: #30363d; --text: #e6edf3; --muted: #8b949e; --lime: #bceb58; --danger: #f85149; }
    body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; margin: 0; padding: 40px 20px; }
    .container { max-width: 820px; margin: 0 auto; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 6px; background: rgba(188, 235, 88, 0.12); color: var(--lime); border: 1px solid rgba(188, 235, 88, 0.3); font-size: 13px; font-weight: 600; margin-bottom: 12px; }
    h1 { color: #fff; margin: 4px 0 8px 0; font-size: 28px; }
    h2 { color: #fff; border-bottom: 1px solid var(--border); padding-bottom: 8px; margin-top: 36px; font-size: 20px; }
    .company { color: var(--muted); font-size: 14px; margin-bottom: 24px; }
    .card { background: var(--panel); border: 1px solid var(--border); border-radius: 8px; padding: 20px; margin: 20px 0; }
    .warning-card { background: rgba(248, 81, 73, 0.08); border: 1px solid rgba(248, 81, 73, 0.35); border-radius: 8px; padding: 20px; margin: 20px 0; }
    .warning-card strong { color: var(--danger); }
    a { color: var(--lime); text-decoration: none; }
    a:hover { text-decoration: underline; }
    .footer { margin-top: 50px; padding-top: 24px; border-top: 1px solid var(--border); font-size: 13px; color: var(--muted); }
  </style>
</head>
<body>
  <div class="container">
    <div class="badge">Puphr LLC Legal Terms</div>
    <h1>Terms of Service for CrossScan Moto</h1>
    <div class="company">Published by Puphr LLC • Effective Date: October 31, 2026</div>

    <div class="warning-card">
      <strong>CRITICAL WORKSHOP SAFETY NOTICE:</strong> CrossScan Moto interacts with low-level vehicle Electronic Control Units (ECUs), bi-directional actuators, and service adaptations. You must only conduct diagnostics and service routines while the motorcycle is parked stationary on a secure stand with the engine off when required. NEVER attempt to operate the diagnostic application while riding.
    </div>

    <h2>1. Scope of Agreement</h2>
    <p>These Terms of Service govern your use of the CrossScan Moto application and associated backend services developed by Puphr LLC ("Puphr", "we", "us"). By installing or using CrossScan Moto, you agree to these terms.</p>

    <h2>2. Workshop Operating Rules & Safety Interlocks</h2>
    <p>CrossScan Moto provides functions that actuate physical motorcycle components (such as fuel pump relays, radiator cooling fans, exhaust flap actuators, and ABS hydraulic valves). By using these functions, you certify that:</p>
    <ul>
      <li>The motorcycle is securely placed on a sturdy center stand, paddock stand, or workshop lift.</li>
      <li>All wheels are stationary and clear of obstructions.</li>
      <li>The engine is switched off when performing actuator tests or coding adaptations unless explicitly instructed by an OEM workshop manual procedure.</li>
      <li>Diagnostics are conducted in a well-ventilated workshop space with appropriate fire and electrical safety precautions.</li>
    </ul>

    <h2>3. Disclaimer of Warranties & Limitation of Liability</h2>
    <p>CrossScan Moto is provided "AS IS" and "AS AVAILABLE" without warranty of any kind, express or implied. Puphr LLC does not warrant that diagnostic functions will be error-free or uninterrupted.</p>
    <p>To the maximum extent permitted by applicable law, Puphr LLC shall not be liable for any direct, indirect, incidental, punitive, or consequential damages resulting from vehicle modification, ECU coding, cleared adaptations, mechanical failures, or voided vehicle warranties.</p>

    <h2>4. In-App Purchases</h2>
    <p>Optional premium feature unlocks are one-time non-consumable digital purchases billed through Apple App Store or Google Play. Store policies govern all transactions, billing, and refunds.</p>

    <h2>5. Contact Information</h2>
    <p>For support or legal inquiries, contact <a href="mailto:support@puphr.com">support@puphr.com</a>.</p>

    <div class="footer">
      &copy; 2026 Puphr LLC. All rights reserved. BMW Motorrad is a registered trademark of Bayerische Motoren Werke AG. Puphr LLC is an independent software development entity.
    </div>
  </div>
</body>
</html>`;
}

function renderDeleteAccountPortalHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Delete Account & Data — CrossScan Moto | Puphr LLC</title>
  <style>
    :root { --bg: #090c10; --panel: #161b22; --border: #30363d; --text: #e6edf3; --muted: #8b949e; --lime: #bceb58; --danger: #f85149; }
    body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; margin: 0; padding: 40px 20px; }
    .container { max-width: 680px; margin: 0 auto; }
    h1 { color: #fff; margin: 4px 0 12px 0; font-size: 26px; }
    .card { background: var(--panel); border: 1px solid var(--border); border-radius: 8px; padding: 24px; margin: 24px 0; }
    a { color: var(--lime); text-decoration: none; }
    label { display:block; margin:12px 0 6px; }
    input { width:100%; box-sizing:border-box; padding:12px; border:1px solid var(--border); border-radius:6px; background:#0d1117; color:#fff; }
    button { margin-top:14px; padding:12px 18px; border:0; border-radius:6px; background:var(--danger); color:#fff; font-weight:600; cursor:pointer; }
    button:disabled { opacity:.55; cursor:wait; }
    #status { min-height:1.5em; color:var(--muted); }
    .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid var(--border); font-size: 13px; color: var(--muted); }
  </style>
</head>
<body>
  <div class="container">
    <h1>Delete Account &amp; Stored Records</h1>
    <p>Verify the email linked to your CrossScan Moto account. Deletion uses an expiring authenticated session; an account UUID alone cannot erase records.</p>
    <div class="card">
      <label for="email">Account email</label>
      <input id="email" type="email" autocomplete="email" maxlength="254" required>
      <div id="codeRow" hidden>
        <label for="code">Six-digit verification code</label>
        <input id="code" inputmode="numeric" autocomplete="one-time-code" maxlength="6">
      </div>
      <button id="action" type="button">Send verification code</button>
      <p id="status" role="status" aria-live="polite"></p>
    </div>
    <p>If you cannot access the linked email, contact <a href="mailto:privacy@puphr.com">privacy@puphr.com</a> for help.</p>
    <div class="footer">
      &copy; 2026 Puphr LLC. All rights reserved.
    </div>
  </div>
  <script>
    (() => {
      let sessionToken = null;
      let verifiedEmail = null;
      let codeSent = false;
      const emailInput = document.getElementById('email');
      const codeInput = document.getElementById('code');
      const codeRow = document.getElementById('codeRow');
      const action = document.getElementById('action');
      const status = document.getElementById('status');

      async function request(path, options = {}) {
        const headers = { 'content-type': 'application/json', ...(options.headers || {}) };
        return fetch(path, { ...options, headers, cache: 'no-store' });
      }

      action.addEventListener('click', async () => {
        action.disabled = true;
        try {
          if (!codeSent) {
            const email = emailInput.value.trim().toLowerCase();
            const response = await request('/v1/auth/otp/request', {
              method: 'POST', body: JSON.stringify({ email }),
            });
            const data = await response.json();
            if (!response.ok) throw new Error(data.error || 'otp_request_failed');
            verifiedEmail = email;
            codeSent = true;
            codeRow.hidden = false;
            action.textContent = 'Verify and delete account';
            status.textContent = 'Enter the code sent to your email.';
            return;
          }

          const verify = await request('/v1/auth/otp/verify', {
            method: 'POST', body: JSON.stringify({ email: verifiedEmail, code: codeInput.value.trim() }),
          });
          const session = await verify.json();
          if (!verify.ok || typeof session.sessionToken !== 'string' || !session.sessionToken) {
            throw new Error(session.error || 'verification_failed');
          }
          sessionToken = session.sessionToken;
          const deletion = await request('/v1/account', {
            method: 'DELETE',
            headers: { authorization: 'Bearer ' + sessionToken },
          });
          const deleted = await deletion.json();
          sessionToken = null;
          if (!deletion.ok || deleted.deleted !== true) {
            throw new Error(deleted.error || 'delete_failed');
          }
          status.textContent = 'Account, purchase records, sessions, and entitlements were deleted.';
          action.hidden = true;
          emailInput.disabled = true;
          codeInput.disabled = true;
        } catch (error) {
          sessionToken = null;
          status.textContent = 'Unable to complete the request. Check the details and try again.';
        } finally {
          action.disabled = false;
        }
      });
    })();
  </script>
</body>
</html>`;
}

function renderDeleteConfirmationHtml(accountId) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Account Deleted — CrossScan Moto | Puphr LLC</title>
  <style>
    :root { --bg: #090c10; --panel: #161b22; --border: #30363d; --text: #e6edf3; --muted: #8b949e; --lime: #bceb58; }
    body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; margin: 0; padding: 40px 20px; text-align: center; }
    .container { max-width: 600px; margin: 40px auto; }
    .card { background: var(--panel); border: 1px solid var(--border); border-radius: 8px; padding: 32px; text-align: left; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 6px; background: rgba(188, 235, 88, 0.12); color: var(--lime); font-size: 14px; font-weight: 600; margin-bottom: 12px; }
    h1 { color: #fff; font-size: 24px; margin-top: 0; }
    code { background: #0d1117; padding: 4px 8px; border-radius: 4px; font-family: monospace; color: var(--lime); word-break: break-all; }
  </style>
</head>
<body>
  <div class="container">
    <div class="card">
      <div class="badge">Deletion Completed</div>
      <h1>Account &amp; Entitlement Records Purged</h1>
      <p>The account records associated with UUID <code>${accountId}</code> have been permanently deleted from Puphr LLC's Cloudflare D1 database.</p>
      <p>All stored purchase hashes and entitlement tokens have been erased. No further vehicle or personal records remain.</p>
      <p><a href="/" style="color: var(--lime);">Return to Service Home</a></p>
    </div>
  </div>
</body>
</html>`;
}

function errorResponse(error) {
  if (error instanceof PurchaseError) {
    return jsonResponse({ error: error.code }, error.status);
  }
  return jsonResponse({ error: 'internal_error' }, 500);
}

async function readJson(request) {
  const contentLength = Number(request.headers.get('content-length') ?? 0);
  if (contentLength > MAX_BODY_BYTES) throw new PurchaseError(413, 'request_too_large');
  const mediaType = request.headers.get('content-type')?.split(';', 1)[0].trim().toLowerCase();
  if (mediaType !== 'application/json') {
    throw new PurchaseError(415, 'json_required');
  }
  if (!request.body) throw new PurchaseError(400, 'invalid_json');
  const reader = request.body.getReader();
  const chunks = [];
  let length = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    length += value.byteLength;
    if (length > MAX_BODY_BYTES) {
      await reader.cancel();
      throw new PurchaseError(413, 'request_too_large');
    }
    chunks.push(value);
  }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
  try {
    return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
  } catch (_) {
    throw new PurchaseError(400, 'invalid_json');
  }
}

function defaultDependencies(fetchImpl = fetch, sendEmailImpl = null) {
  return {
    verifySignedTransaction: verifyAppleSignedTransaction,
    lookupAppleTransaction: (transactionId, config) => lookupAppleTransaction(transactionId, config, fetchImpl),
    lookupGooglePurchase: (token, config) => lookupGooglePurchase(token, config, fetchImpl),
    acknowledgeGooglePurchase: (token, config) => acknowledgeGooglePurchase(token, config, fetchImpl),
    hashAccountId: hashHex,
    hashPurchaseToken: hashHex,
    sendEmail: sendEmailImpl,
  };
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: SECURITY_HEADERS,
      });
    }
    const url = new URL(request.url);
    if (request.method === 'GET' && (url.pathname === '/' || url.pathname === '/health')) {
      return jsonResponse({
        status: 'ok',
        service: 'CrossScan Moto Payment & Verification API',
        company: 'Puphr LLC',
        appId: 'com.puphr.crossscanmoto',
        version: '2.0.0',
      });
    }
    if (request.method === 'GET' && (url.pathname === '/privacy' || url.pathname === '/privacy-policy')) {
      return htmlResponse(renderPrivacyPolicyHtml());
    }
    if (request.method === 'GET' && (url.pathname === '/terms' || url.pathname === '/terms-of-service')) {
      return htmlResponse(renderTermsHtml());
    }
    if (request.method === 'GET' && url.pathname === '/delete-account') {
      return htmlResponse(renderDeleteAccountPortalHtml());
    }
    if (request.method === 'GET' && url.pathname === '/v1/config') {
      const metadataPrice = Number(env.PRICE_METADATA_USD);
      return jsonResponse({ oneTime: true, price: {
        amount: Number.isFinite(metadataPrice) && metadataPrice > 0 ? metadataPrice : 24.99,
        currency: 'USD',
      } });
    }
    try {
      const config = configFromEnv(env);
      const repository = env.DB ? new D1PurchaseRepository(env.DB) : null;
      const dependencies = defaultDependencies();

      if (request.method === 'DELETE' && url.pathname === '/v1/account') {
        if (!repository) throw new PurchaseError(503, 'database_not_configured');
        const session = await requireSession(request, env, repository);
        const result = await repository.deleteAccount(session.accountId);
        return jsonResponse({ deleted: true, accountId: result.accountId });
      }

      if (request.method === 'POST' && url.pathname === '/v1/auth/logout') {
        if (!repository) throw new PurchaseError(503, 'database_not_configured');
        const session = await requireSession(request, env, repository);
        await repository.revokeSession(session.jti);
        return jsonResponse({ ok: true });
      }

      // Email OTP Request (POST /v1/auth/otp/request)
      if (request.method === 'POST' && url.pathname === '/v1/auth/otp/request') {
        if (!repository) throw new PurchaseError(503, 'database_not_configured');
        requireSecret(env.SESSION_SECRET, 'auth');
        const otpPepper = env.OTP_PEPPER ?? env.SESSION_SECRET;
        requireSecret(otpPepper, 'otp');
        if (!env.EMAIL || typeof env.EMAIL.send !== 'function') {
          throw new PurchaseError(503, 'email_delivery_not_configured');
        }
        const body = await readJson(request);
        const email = body?.email?.toString().trim().toLowerCase();
        if (!validEmail(email)) throw new PurchaseError(400, 'invalid_email');
        const now = Date.now();
        await repository.cleanupExpiredRateLimits(now);
        const emailRateKey = `email:${await hashOtpCode(email, 'rate-limit', otpPepper)}`;
        const sourceIp = request.headers.get('CF-Connecting-IP') ?? 'unknown';
        const ipRateKey = `ip:${await hashOtpCode(sourceIp, 'rate-limit', otpPepper)}`;
        const emailAllowed = await repository.consumeRateLimit(emailRateKey, 1, 60_000, now);
        const ipAllowed = await repository.consumeRateLimit(ipRateKey, 20, 60 * 60_000, now);
        if (!emailAllowed || !ipAllowed) {
          return jsonResponse({ error: 'rate_limited', retryAfter: emailAllowed ? 3600 : 60 }, 429);
        }

        const randomBytes = new Uint32Array(1);
        const range = Math.floor(0x1_0000_0000 / 900_000) * 900_000;
        do { crypto.getRandomValues(randomBytes); } while (randomBytes[0] >= range);
        const code = (100000 + (randomBytes[0] % 900_000)).toString();

        const saltBytes = new Uint8Array(16);
        crypto.getRandomValues(saltBytes);
        const salt = [...saltBytes].map((b) => b.toString(16).padStart(2, '0')).join('');
        const codeHash = await hashOtpCode(code, salt, otpPepper);
        const expiresAt = now + 10 * 60 * 1000;

        await repository.saveOtp(email, codeHash, salt, expiresAt);
        try {
          await sendOtpEmail(email, code, env, dependencies.sendEmail);
        } catch (error) {
          await repository.deleteOtp(email);
          throw error;
        }

        return jsonResponse({
          ok: true,
          email,
          expiresIn: 600,
        });
      }

      // Email OTP Verification (POST /v1/auth/otp/verify)
      if (request.method === 'POST' && url.pathname === '/v1/auth/otp/verify') {
        if (!repository) throw new PurchaseError(503, 'database_not_configured');
        requireSecret(env.SESSION_SECRET, 'auth');
        const otpPepper = env.OTP_PEPPER ?? env.SESSION_SECRET;
        requireSecret(otpPepper, 'otp');
        const body = await readJson(request);
        const email = body?.email?.toString().trim().toLowerCase();
        const code = body?.code?.toString().trim();
        if (!validEmail(email)) throw new PurchaseError(400, 'invalid_email');
        if (!code || !/^\d{6}$/.test(code)) throw new PurchaseError(400, 'invalid_code');

        const otpRecord = await repository.getOtp(email);
        const now = Date.now();
        if (!otpRecord || now > otpRecord.expires_at) {
          throw new PurchaseError(400, 'code_expired_or_invalid');
        }
        if (otpRecord.attempts >= 5) {
          throw new PurchaseError(429, 'too_many_attempts');
        }

        const expectedHash = await hashOtpCode(code, otpRecord.salt, otpPepper);
        if (!constantTimeEqual(expectedHash, otpRecord.code_hash)) {
          await repository.incrementOtpAttempts(email);
          throw new PurchaseError(400, 'code_expired_or_invalid');
        }
        const consumed = await repository.consumeOtp(email, expectedHash, now);
        if (!consumed) throw new PurchaseError(400, 'code_expired_or_invalid');

        const user = await repository.findUserByEmail(email) ?? await repository.createUserIfAbsent(email);
        if (!user) throw new PurchaseError(503, 'account_creation_failed');
        const sessionId = crypto.randomUUID();
        const expiresAt = now + SESSION_TTL_SECONDS * 1000;
        const sessionToken = await createSessionToken({
          userId: user.user_id,
          email,
          accountId: user.account_id,
        }, env.SESSION_SECRET, { sessionId, nowSeconds: Math.floor(now / 1000) });
        await repository.saveSession({
          sessionId,
          userId: user.user_id,
          email,
          accountId: user.account_id,
          expiresAt,
        });

        const entitlement = await repository.getEntitlement(user.account_id, ENTITLEMENT_ID);
        const access = effectiveAccountAccess(user.email, entitlement);

        return jsonResponse({
          ok: true,
          sessionToken,
          email,
          accountId: user.account_id,
          ...access,
        });
      }

      // User Session Lookup (GET /v1/auth/session)
      if (request.method === 'GET' && url.pathname === '/v1/auth/session') {
        if (!repository) throw new PurchaseError(503, 'database_not_configured');
        const claims = await requireSession(request, env, repository);
        const entitlement = await repository.getEntitlement(claims.accountId, ENTITLEMENT_ID);
        return jsonResponse({
          ok: true,
          email: claims.email,
          accountId: claims.accountId,
          ...effectiveAccountAccess(claims.email, entitlement),
        });
      }

      if (request.method === 'POST' && url.pathname === '/v1/purchases/apple') {
        if (!repository) throw new PurchaseError(503, 'database_not_configured');
        const session = await requireSession(request, env, repository);
        const body = await readJson(request);
        const purchase = await verifyApplePurchase(body, config, dependencies, {
          accountId: session.accountId,
          storeAccountId: session.accountId,
        });
        const result = await repository.applyPurchase(purchase, { userId: session.sub });
        if (purchase.state === 'active' && result.entitlement?.status !== 'active') {
          throw new PurchaseError(409, 'purchase_replayed');
        }
        const unlocked = result.entitlement?.status === 'active';
        return jsonResponse({
          valid: purchase.state === 'active',
          entitlement: unlocked,
          idempotent: result.idempotent,
          productId: purchase.productId,
        }, unlocked ? 200 : 409);
      }
      if (request.method === 'POST' && url.pathname === '/v1/purchases/google') {
        if (!repository) throw new PurchaseError(503, 'database_not_configured');
        const session = await requireSession(request, env, repository);
        const body = await readJson(request);
        const purchase = await verifyGooglePurchase(body, config, dependencies, {
          accountId: session.accountId,
          storeAccountId: session.accountId,
        });
        const result = await repository.applyPurchase(purchase, { userId: session.sub });
        if (purchase.state === 'active' && result.entitlement?.status !== 'active') {
          throw new PurchaseError(409, 'purchase_replayed');
        }
        const unlocked = result.entitlement?.status === 'active';
        return jsonResponse({
          valid: purchase.state === 'active',
          entitlement: unlocked,
          idempotent: result.idempotent,
          productId: purchase.productId,
        }, unlocked ? 200 : 409);
      }
      if (request.method === 'POST' && url.pathname === '/v1/purchases/google/restore') {
        if (!repository) throw new PurchaseError(503, 'database_not_configured');
        const session = await requireSession(request, env, repository);
        requireConfig(config, [
          'GOOGLE_PACKAGE_NAME', 'GOOGLE_UNLOCK_PRODUCT_ID',
          'GOOGLE_SERVICE_ACCOUNT_EMAIL', 'GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY',
        ]);
        const body = await readJson(request);
        if (!requiredString(body?.purchaseToken, 4_000)) {
          throw new PurchaseError(400, 'invalid_google_purchase_token');
        }
        const tokenHash = await hashHex(body.purchaseToken);
        const owner = await repository.findGooglePurchaseOwner(tokenHash);
        if (!owner || owner.product_id !== config.GOOGLE_UNLOCK_PRODUCT_ID ||
            !validAccountId(owner.store_account_id)) {
          // No account identifier is returned for unknown or never-verified tokens.
          throw new PurchaseError(409, 'recovery_unavailable');
        }
        const purchase = await verifyGooglePurchase({
          purchaseToken: body.purchaseToken,
        }, config, dependencies, {
          accountId: session.accountId,
          storeAccountId: owner.store_account_id,
        });
        if (purchase.storeKey !== tokenHash) {
          throw new PurchaseError(422, 'purchase_token_mismatch');
        }
        const result = await repository.applyPurchase(purchase, {
          userId: session.sub,
          allowStoreAccountRebind: true,
        });
        const unlocked = result.entitlement?.status === 'active';
        if (!unlocked) {
          return jsonResponse({ valid: false, entitlement: false }, 409);
        }
        // Only an existing, server-verified Google purchase token can recover
        // the original UUID. Never accept an account ID supplied by the caller.
        return jsonResponse({
          valid: purchase.state === 'active',
          entitlement: true,
          idempotent: result.idempotent,
          productId: purchase.productId,
          accountId: session.accountId,
        });
      }
      if (request.method === 'POST' && url.pathname === '/v1/purchases/apple/restore') {
        if (!repository) throw new PurchaseError(503, 'database_not_configured');
        const session = await requireSession(request, env, repository);
        const body = await readJson(request);
        const purchase = await verifyApplePurchase(body, config, dependencies, {
          accountId: session.accountId,
          allowStoreAccountRecovery: true,
        });
        const result = await repository.applyPurchase(purchase, {
          userId: session.sub,
          allowStoreAccountRebind: true,
        });
        const unlocked = result.entitlement?.status === 'active';
        if (!unlocked) return jsonResponse({ valid: false, entitlement: false }, 409);
        return jsonResponse({
          valid: purchase.state === 'active', entitlement: true,
          idempotent: result.idempotent, productId: purchase.productId,
          accountId: session.accountId,
        });
      }
      if (request.method === 'GET' && url.pathname === '/v1/entitlements') {
        if (!repository) throw new PurchaseError(503, 'database_not_configured');
        const session = await requireSession(request, env, repository);
        const entitlement = await repository.getEntitlement(session.accountId, ENTITLEMENT_ID);
        return jsonResponse({ ...effectiveAccountAccess(session.email, entitlement), verificationConfigured: purchaseVerificationConfiguration(env) });
      }
      const entitlementMatch = request.method === 'GET' && url.pathname.match(/^\/v1\/entitlements\/([^/]+)$/);
      if (entitlementMatch) {
        if (!repository) throw new PurchaseError(503, 'database_not_configured');
        const session = await requireSession(request, env, repository);
        const accountId = decodeURIComponent(entitlementMatch[1]).toLowerCase();
        if (!validAccountId(accountId)) throw new PurchaseError(400, 'invalid_account_id');
        if (accountId !== session.accountId) throw new PurchaseError(403, 'account_mismatch');
        const entitlement = await repository.getEntitlement(session.accountId, ENTITLEMENT_ID);
        return jsonResponse({ ...effectiveAccountAccess(session.email, entitlement), verificationConfigured: purchaseVerificationConfiguration(env) });
      }
      return jsonResponse({ error: 'not_found' }, 404);
    } catch (error) {
      return errorResponse(error);
    }
  },
};
