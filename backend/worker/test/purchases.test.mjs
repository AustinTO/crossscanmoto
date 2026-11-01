import test from 'node:test';
import assert from 'node:assert/strict';
import {
  D1PurchaseRepository,
  purchaseVerificationConfiguration,
  PurchaseError,
  acknowledgeGooglePurchase,
  createSessionToken,
  lookupAppleTransaction,
  lookupGooglePurchase,
  verifyAppleSignedTransaction,
  verifyApplePurchase,
  verifyGooglePurchase,
  verifySessionToken,
} from '../src/index.mjs';
import worker from '../src/index.mjs';

const ACCOUNT = '59341044-17c8-47a3-8db9-5a9549956d9f';
const USER_ID = '40cb47bc-c218-4a43-a177-e17226589aa1';
const SESSION_SECRET = 'test-session-secret-abcdefghijklmnopqrstuvwxyz-0123456789';
const OTP_PEPPER = 'test-otp-pepper-secret-abcdefghijklmnopqrstuvwxyz-0123456789';
const APPLE_CONFIG = {
  APPLE_BUNDLE_ID: 'app.bundle.configured',
  APPLE_UNLOCK_PRODUCT_ID: 'product.configured.ios',
  APPLE_ENVIRONMENT: 'Sandbox',
  APPLE_ISSUER_ID: 'issuer-configured',
  APPLE_KEY_ID: 'key-configured',
  APPLE_PRIVATE_KEY: 'private-key-configured',
  APPLE_ROOT_CERTIFICATES: '["base64-root-certificate-configured"]',
};
const GOOGLE_CONFIG = {
  GOOGLE_PACKAGE_NAME: 'app.package.configured',
  GOOGLE_UNLOCK_PRODUCT_ID: 'product.configured.android',
  GOOGLE_SERVICE_ACCOUNT_EMAIL: 'service-account@example.invalid',
  GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY: 'private-key-configured',
};

function appleTransaction(overrides = {}) {
  return {
    bundleId: APPLE_CONFIG.APPLE_BUNDLE_ID,
    productId: APPLE_CONFIG.APPLE_UNLOCK_PRODUCT_ID,
    type: 'Non-Consumable',
    environment: APPLE_CONFIG.APPLE_ENVIRONMENT,
    transactionId: 'apple-transaction-1',
    originalTransactionId: 'apple-original-1',
    appAccountToken: ACCOUNT,
    purchaseDate: 1_800_000_000_000,
    ...overrides,
  };
}

function googlePurchase(overrides = {}) {
  return {
    productLineItem: [{ productId: GOOGLE_CONFIG.GOOGLE_UNLOCK_PRODUCT_ID }],
    purchaseStateContext: { purchaseState: 'PURCHASED' },
    purchaseCompletionTime: '2026-10-31T10:00:00Z',
    acknowledgementState: 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED',
    obfuscatedExternalAccountId: 'account-hash-expected',
    orderId: 'google-order-1',
    ...overrides,
  };
}

async function privateKeyPem(algorithm, extractAlgorithm = 'pkcs8') {
  const pair = await crypto.subtle.generateKey(algorithm, true, ['sign', 'verify']);
  const der = new Uint8Array(await crypto.subtle.exportKey(extractAlgorithm, pair.privateKey));
  const base64 = Buffer.from(der).toString('base64');
  const body = base64.match(/.{1,64}/g).join('\n');
  return `-----BEGIN PRIVATE KEY-----\n${body}\n-----END PRIVATE KEY-----`;
}

function decodeJwtPayload(token) {
  return JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString('utf8'));
}

test('Apple server lookup uses signed API credentials and the configured environment', async () => {
  const config = {
    ...APPLE_CONFIG,
    APPLE_PRIVATE_KEY: await privateKeyPem({ name: 'ECDSA', namedCurve: 'P-256' }),
  };
  let calledUrl;
  let claims;
  const result = await lookupAppleTransaction('transaction/1', config, async (url, options) => {
    calledUrl = String(url);
    const bearer = options.headers.authorization.slice('Bearer '.length);
    assert.equal(bearer.split('.').length, 3);
    assert.equal(Buffer.from(bearer.split('.')[2], 'base64url').length, 64);
    claims = decodeJwtPayload(bearer);
    return Response.json({ signedTransactionInfo: 'server-signed-transaction' });
  });
  assert.equal(calledUrl, 'https://api.storekit-sandbox.apple.com/inApps/v1/transactions/transaction%2F1');
  assert.equal(claims.iss, config.APPLE_ISSUER_ID);
  assert.equal(claims.aud, 'appstoreconnect-v1');
  assert.equal(claims.bid, config.APPLE_BUNDLE_ID);
  assert.equal(result.signedTransactionInfo, 'server-signed-transaction');
});

test('Google Developer API uses service-account OAuth and the configured package', async () => {
  const config = {
    ...GOOGLE_CONFIG,
    GOOGLE_SERVICE_ACCOUNT_EMAIL: 'service-account-test@example.invalid',
    GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY: await privateKeyPem({
      name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256',
    }),
  };
  const urls = [];
  let assertionClaims;
  const mockFetch = async (url, options) => {
    urls.push(String(url));
    if (String(url) === 'https://oauth2.googleapis.com/token') {
      const form = new URLSearchParams(options.body);
      const assertion = form.get('assertion');
      assertionClaims = decodeJwtPayload(assertion);
      return Response.json({ access_token: 'short-lived-test-token', expires_in: 3600 });
    }
    assert.equal(options.headers.authorization, 'Bearer short-lived-test-token');
    if (String(url).endsWith(':acknowledge')) return new Response(null, { status: 200 });
    return Response.json(googlePurchase());
  };

  const response = await lookupGooglePurchase('purchase/token', config, mockFetch);
  await acknowledgeGooglePurchase('purchase/token', config, mockFetch);
  assert.equal(assertionClaims.iss, config.GOOGLE_SERVICE_ACCOUNT_EMAIL);
  assert.equal(assertionClaims.scope, 'https://www.googleapis.com/auth/androidpublisher');
  assert.equal(urls[1], 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/app.package.configured/purchases/productsv2/tokens/purchase%2Ftoken');
  assert.ok(urls.some((url) => url.endsWith('/purchases/products/product.configured.android/tokens/purchase%2Ftoken:acknowledge')));
  assert.equal(response.purchaseStateContext.purchaseState, 'PURCHASED');
});

function fakeD1() {
  const records = new Map();
  const transactions = new Map();
  const entitlements = new Map();
  const users = new Map();
  const otps = new Map();
  const sessions = new Map();
  const storeLinks = new Map();
  const rateLimits = new Map();
  const key = (a, b) => `${a}:${b}`;

  return {
    records,
    entitlements,
    users,
    otps,
    sessions,
    storeLinks,
    prepare(sql) {
      return {
        sql,
        args: [],
        bind(...args) { this.args = args; return this; },
        async run() {
          if (sql.includes('INSERT INTO auth_otps')) {
            const [email, codeHash, salt, expiresAt, now] = this.args;
            otps.set(email, {
              email, code_hash: codeHash, salt, attempts: 0, expires_at: expiresAt, created_at: now,
            });
            return { success: true };
          }
          if (sql.includes('INSERT INTO auth_sessions')) {
            const [sessionId, userId, email, accountId, createdAt, expiresAt] = this.args;
            sessions.set(sessionId, {
              session_id: sessionId, user_id: userId, email, account_id: accountId,
              created_at: createdAt, expires_at: expiresAt, revoked_at: null,
            });
            return { success: true };
          }
          if (sql.includes('UPDATE auth_sessions SET revoked_at')) {
            const [revokedAt, sessionId] = this.args;
            const session = sessions.get(sessionId);
            if (session) session.revoked_at = revokedAt;
            return { success: true };
          }
          if (sql.includes('UPDATE auth_otps SET attempts = attempts + 1')) {
            const [email, now] = this.args;
            const existing = otps.get(email);
            if (existing && existing.attempts < 5 && existing.expires_at > now) existing.attempts += 1;
            return { success: true };
          }
          if (sql.includes('DELETE FROM auth_otps')) {
            const [email] = this.args;
            otps.delete(email);
            return { success: true };
          }
          if (sql.includes('DELETE FROM auth_rate_limits')) {
            const [expiredAt] = this.args;
            for (const [rateKey, item] of rateLimits) {
              if (item.expires_at < expiredAt) rateLimits.delete(rateKey);
            }
            return { success: true };
          }
          if (sql.includes('INSERT INTO users')) {
            const [userId, email, accountId, createdAt, updatedAt] = this.args;
            const existing = users.get(email);
            if (!existing) users.set(email, {
              user_id: userId, email, account_id: accountId,
              created_at: createdAt, updated_at: updatedAt,
            });
            return { success: true };
          }
          throw new Error(`Unexpected run query in fake D1: ${sql}`);
        },
        async first() {
          if (sql.includes('FROM purchase_records') && sql.includes('store_key = ?')) {
            return records.get(key(this.args[0], this.args[1])) ?? null;
          }
          if (sql.includes('FROM purchase_records') && sql.includes('transaction_id = ?')) {
            return transactions.get(key(this.args[0], this.args[1])) ?? null;
          }
          if (sql.includes('FROM entitlements')) {
            return entitlements.get(key(this.args[0], this.args[1])) ?? null;
          }
          if (sql.includes('FROM auth_sessions')) {
            return sessions.get(this.args[0]) ?? null;
          }
          if (sql.includes('FROM auth_otps')) {
            if (sql.includes('RETURNING email')) {
              const [email, codeHash, now] = this.args;
              const existing = otps.get(email);
              if (!existing || existing.code_hash !== codeHash || existing.attempts >= 5 || existing.expires_at <= now) return null;
              otps.delete(email);
              return { email };
            }
            return otps.get(this.args[0]) ?? null;
          }
          if (sql.includes('FROM auth_rate_limits') || sql.includes('RETURNING request_count')) {
            const [rateKey, windowStart, expiresAt] = this.args;
            const previous = rateLimits.get(rateKey);
            const requestCount = previous?.window_start === windowStart ? previous.request_count + 1 : 1;
            rateLimits.set(rateKey, { window_start: windowStart, request_count: requestCount, expires_at: expiresAt });
            return { request_count: requestCount };
          }
          if (sql.includes('FROM users')) {
            if (sql.includes('user_id = ?')) {
              return [...users.values()].find((user) => user.user_id === this.args[0]) ?? null;
            }
            if (sql.includes('account_id = ?')) {
              return [...users.values()].find((user) => user.account_id === this.args[0]) ?? null;
            }
            return users.get(this.args[0]) ?? null;
          }
          if (sql.includes('FROM store_account_links')) {
            return storeLinks.get(key(this.args[0], this.args[1])) ?? null;
          }
          throw new Error(`Unexpected query in fake D1: ${sql}`);
        },
      };
    },
    async batch(statements) {
      const results = [];
      for (const statement of statements) {
        if (statement.sql.includes('INSERT INTO store_account_links')) {
          const [store, storeAccountId, userId, accountId, createdAt] = statement.args;
          const linkKey = key(store, storeAccountId);
          const previous = storeLinks.get(linkKey);
          if (!previous || previous.user_id === userId) {
            storeLinks.set(linkKey, { store, store_account_id: storeAccountId,
              user_id: userId, account_id: accountId, created_at: createdAt });
            results.push({ meta: { changes: 1 } });
          } else {
            results.push({ meta: { changes: 0 } });
          }
          continue;
        }
        if (statement.sql.includes('INSERT INTO purchase_records')) {
          const [store, storeKey, transactionId, originalTransactionId, accountId,
            storeAccountId, productId, entitlementId, state, purchasedAt, revokedAt,
            createdAt, updatedAt, userId, linkStore, linkStoreAccountId, linkUserId,
            allowRebind] = statement.args;
          const recordKey = key(store, storeKey);
          const byTransaction = transactions.get(key(store, transactionId));
          if (byTransaction && (byTransaction.account_id !== accountId || byTransaction.product_id !== productId) && !allowRebind) {
            throw new Error('unique transaction constraint');
          }
          const linked = userId == null || storeLinks.get(key(linkStore, linkStoreAccountId))?.user_id === linkUserId;
          const old = records.get(recordKey);
          if (linked && (!old || ((old.account_id === accountId || allowRebind) &&
              old.store_account_id === storeAccountId && old.product_id === productId))) {
            const record = { store, store_key: storeKey, transaction_id: transactionId,
              original_transaction_id: originalTransactionId, account_id: accountId,
              store_account_id: storeAccountId,
              product_id: productId, entitlement_id: entitlementId, state,
              purchased_at: purchasedAt, revoked_at: revokedAt,
              created_at: old?.created_at ?? createdAt, updated_at: updatedAt };
            records.set(recordKey, record);
            transactions.set(key(store, transactionId), record);
            results.push({ meta: { changes: 1 } });
          } else {
            results.push({ meta: { changes: 0 } });
          }
          continue;
        }
        if (statement.sql.includes('INSERT INTO entitlements')) {
          const [accountId, entitlementId, predicateAccount, predicateEntitlement, updatedAt] = statement.args;
          const active = [...records.values()].some((record) =>
            record.account_id === predicateAccount && record.entitlement_id === predicateEntitlement && record.state === 'active');
          entitlements.set(key(accountId, entitlementId), {
            status: active ? 'active' : 'revoked', updated_at: updatedAt,
          });
          results.push({ meta: { changes: 1 } });
          continue;
        }
        if (statement.sql.includes('DELETE FROM entitlements')) {
          const [id] = statement.args;
          for (const k of entitlements.keys()) {
            if (k.startsWith(`${id}:`)) entitlements.delete(k);
          }
          results.push({ meta: { changes: 1 } });
          continue;
        }
        if (statement.sql.includes('DELETE FROM purchase_records')) {
          const [id] = statement.args;
          for (const [k, v] of records.entries()) {
            if (v.account_id === id) {
              records.delete(k);
              transactions.delete(key(v.store, v.transaction_id));
            }
          }
          results.push({ meta: { changes: 1 } });
          continue;
        }
        if (statement.sql.includes('DELETE FROM users')) {
          const [id] = statement.args;
          for (const [email, user] of users.entries()) {
            if (user.account_id === id) {
              users.delete(email);
            }
          }
          results.push({ meta: { changes: 1 } });
          continue;
        }
        if (statement.sql.includes('UPDATE auth_sessions')) {
          const [revokedAt, accountId] = statement.args;
          for (const session of sessions.values()) {
            if (session.account_id === accountId) session.revoked_at = revokedAt;
          }
          results.push({ meta: { changes: 1 } });
          continue;
        }
        if (statement.sql.includes('DELETE FROM store_account_links')) {
          const [userId] = statement.args;
          for (const [linkKey, link] of storeLinks) {
            if (link.user_id === userId) storeLinks.delete(linkKey);
          }
          results.push({ meta: { changes: 1 } });
          continue;
        }
        if (statement.sql.includes('DELETE FROM auth_otps')) {
          const [email] = statement.args;
          otps.delete(email);
          results.push({ meta: { changes: 1 } });
          continue;
        }
        throw new Error(`Unexpected statement in fake D1: ${statement.sql}`);
      }
      return results;
    },
  };
}

async function createTestUserAndSession(db, email, accountId = ACCOUNT) {
  const user = {
    user_id: USER_ID,
    email,
    account_id: accountId,
    created_at: Date.now(),
    updated_at: Date.now(),
  };
  db.users.set(email, user);
  const sessionId = crypto.randomUUID();
  const expiresAt = Date.now() + 7 * 24 * 60 * 60 * 1000;
  const token = await createSessionToken(user, SESSION_SECRET, {
    sessionId,
    nowSeconds: Math.floor(Date.now() / 1000),
  });
  await new D1PurchaseRepository(db).saveSession({
    sessionId,
    userId: user.user_id,
    email,
    accountId,
    expiresAt,
  });
  return { user, sessionId, token };
}

test('session JWT rejects missing configuration, malformed algorithm, missing claims, and expiry', async () => {
  const user = { userId: USER_ID, email: 'jwt@example.com', accountId: ACCOUNT };
  await assert.rejects(createSessionToken(user), (error) =>
    error instanceof PurchaseError && error.code === 'auth_not_configured');

  const now = Math.floor(Date.now() / 1000);
  const validToken = await createSessionToken(user, SESSION_SECRET, { nowSeconds: now });
  assert.equal((await verifySessionToken(validToken, SESSION_SECRET, now))?.accountId, ACCOUNT);
  assert.equal(await verifySessionToken(validToken, 'wrong-session-secret-abcdefghijklmnopqrstuvwxyz', now), null);

  const commonClaims = {
    sub: USER_ID, email: user.email, accountId: ACCOUNT,
    iat: now, nbf: now, exp: now + 3600,
    iss: 'https://api.puphr.com', aud: 'com.puphr.crossscanmoto',
    jti: 'e0b5cc67-1153-4e2c-a8f3-2d3db5775112',
  };
  assert.equal(await verifySessionToken(await signTestJwt({ ...commonClaims, exp: undefined }), SESSION_SECRET, now), null);
  assert.equal(await verifySessionToken(await signTestJwt({ ...commonClaims, aud: 'other-app' }), SESSION_SECRET, now), null);
  assert.equal(await verifySessionToken(await signTestJwt(commonClaims, { alg: 'none', typ: 'JWT' }), SESSION_SECRET, now), null);
  const expired = await createSessionToken(user, SESSION_SECRET, { nowSeconds: now - 8 * 24 * 60 * 60 });
  assert.equal(await verifySessionToken(expired, SESSION_SECRET, now), null);
});

test('auth guards entitlement, purchase, and delete routes against body UUID takeover', async () => {
  const db = fakeD1();
  const { token } = await createTestUserAndSession(db, 'owner@example.com');
  const victimAccount = '1c2bcd2c-48cf-41f5-b3c8-66939cc33333';
  db.users.set('victim@example.com', {
    user_id: 'f05f0e9f-ab1e-47b5-bc10-98e4cfbaeb63',
    email: 'victim@example.com', account_id: victimAccount,
    created_at: Date.now(), updated_at: Date.now(),
  });
  const env = { DB: db, SESSION_SECRET };

  const publicEntitlement = await worker.fetch(new Request(
    `https://api.puphr.com/v1/entitlements/${victimAccount}`,
  ), env);
  assert.equal(publicEntitlement.status, 401);

  const crossAccountEntitlement = await worker.fetch(new Request(
    `https://api.puphr.com/v1/entitlements/${victimAccount}`,
    { headers: { authorization: `Bearer ${token}` } },
  ), env);
  assert.equal(crossAccountEntitlement.status, 403);

  const spoofedPurchase = await worker.fetch(new Request('https://api.puphr.com/v1/purchases/apple', {
    method: 'POST',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify({
      accountId: victimAccount, transactionId: 'transaction-id', signedTransactionInfo: 'not-a-jws',
    }),
  }), env);
  assert.equal(spoofedPurchase.status, 503);
  assert.equal((await spoofedPurchase.json()).error, 'store_not_configured');

  const uuidOnlyDelete = await worker.fetch(new Request('https://api.puphr.com/v1/account/delete', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ accountId: victimAccount }),
  }), env);
  assert.equal(uuidOnlyDelete.status, 404);
  assert.ok(db.users.has('victim@example.com'));
});

async function signTestJwt(payload, header = { alg: 'HS256', typ: 'JWT' }, secret = SESSION_SECRET) {
  const encode = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
  const input = `${encode(header)}.${encode(payload)}`;
  const key = await crypto.subtle.importKey(
    'raw', new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
  );
  const signature = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(input));
  return `${input}.${Buffer.from(signature).toString('base64url')}`;
}

test('Apple requires a trusted device JWS and matching authoritative App Store transaction', async () => {
  const claims = appleTransaction();
  let lookups = 0;
  const purchase = await verifyApplePurchase({
    accountId: ACCOUNT, transactionId: claims.transactionId,
    signedTransactionInfo: 'signed-device-jws',
  }, APPLE_CONFIG, {
    verifySignedTransaction: async (jws) => {
      assert.ok(jws === 'signed-device-jws' || jws === 'signed-server-jws');
      return claims;
    },
    lookupAppleTransaction: async () => { lookups++; return { signedTransactionInfo: 'signed-server-jws' }; },
  });
  assert.equal(lookups, 1);
  assert.equal(purchase.state, 'active');
  assert.equal(purchase.entitlementId, 'premium_unlock');
});

test('Apple signature verifier rejects malformed signed data fail-closed', async () => {
  await assert.rejects(verifyAppleSignedTransaction('header.payload.signature', {
    ...APPLE_CONFIG,
    APPLE_ROOT_CERTIFICATES: JSON.stringify(['A'.repeat(256)]),
  }), (error) => error instanceof PurchaseError && error.code === 'invalid_apple_signature');
});

test('Apple rejects the wrong bundle ID before querying the App Store', async () => {
  let lookups = 0;
  await assert.rejects(verifyApplePurchase({
    accountId: ACCOUNT, transactionId: 'apple-transaction-1', signedTransactionInfo: 'signed',
  }, APPLE_CONFIG, {
    verifySignedTransaction: async () => appleTransaction({ bundleId: 'another.bundle' }),
    lookupAppleTransaction: async () => { lookups++; throw new Error('must not query'); },
  }), (error) => error instanceof PurchaseError && error.code === 'wrong_app');
  assert.equal(lookups, 0);
});

test('Apple rejects a transaction signed for another account and rejects revoked transactions', async () => {
  await assert.rejects(verifyApplePurchase({
    accountId: ACCOUNT, transactionId: 'apple-transaction-1', signedTransactionInfo: 'signed',
  }, APPLE_CONFIG, {
    verifySignedTransaction: async () => appleTransaction({ appAccountToken: '1c2bcd2c-48cf-41f5-b3c8-66939cc33333' }),
    lookupAppleTransaction: async () => { throw new Error('must not query'); },
  }), (error) => error instanceof PurchaseError && error.code === 'account_mismatch');

  const revoked = await verifyApplePurchase({
    accountId: ACCOUNT, transactionId: 'apple-transaction-1', signedTransactionInfo: 'signed',
  }, APPLE_CONFIG, {
    verifySignedTransaction: async () => appleTransaction({ revocationDate: 1_800_000_100_000 }),
    lookupAppleTransaction: async () => ({ signedTransactionInfo: 'signed-server-jws' }),
  });
  assert.equal(revoked.state, 'revoked');
  assert.ok(revoked.revokedAt);
});

test('Google pending purchases do not acknowledge or grant access', async () => {
  let acknowledgements = 0;
  await assert.rejects(verifyGooglePurchase({ accountId: ACCOUNT, purchaseToken: 'token' }, GOOGLE_CONFIG, {
    lookupGooglePurchase: async () => googlePurchase({
      purchaseStateContext: { purchaseState: 'PENDING' }, purchaseCompletionTime: undefined,
    }),
    acknowledgeGooglePurchase: async () => { acknowledgements++; },
    hashAccountId: async () => 'account-hash-expected',
    hashPurchaseToken: async () => 'token-hash',
  }), (error) => error instanceof PurchaseError && error.code === 'purchase_pending');
  assert.equal(acknowledgements, 0);
});

test('Google purchase requires expected product and obfuscated account binding', async () => {
  await assert.rejects(verifyGooglePurchase({ accountId: ACCOUNT, purchaseToken: 'token' }, GOOGLE_CONFIG, {
    lookupGooglePurchase: async () => googlePurchase({
      productLineItem: [{ productId: 'other.product' }],
    }),
    acknowledgeGooglePurchase: async () => {},
    hashAccountId: async () => 'account-hash-expected',
    hashPurchaseToken: async () => 'token-hash',
  }), (error) => error instanceof PurchaseError && error.code === 'wrong_product');

  await assert.rejects(verifyGooglePurchase({ accountId: ACCOUNT, purchaseToken: 'token' }, GOOGLE_CONFIG, {
    lookupGooglePurchase: async () => googlePurchase({ obfuscatedExternalAccountId: undefined }),
    acknowledgeGooglePurchase: async () => {},
    hashAccountId: async () => 'account-hash-expected',
    hashPurchaseToken: async () => 'token-hash',
  }), (error) => error instanceof PurchaseError && error.code === 'account_mismatch');
});

test('Google acknowledgement happens only for completed purchases', async () => {
  let acknowledgements = 0;
  const purchase = await verifyGooglePurchase({ accountId: ACCOUNT, purchaseToken: 'token' }, GOOGLE_CONFIG, {
    lookupGooglePurchase: async () => googlePurchase({
      acknowledgementState: 'ACKNOWLEDGEMENT_STATE_PENDING',
    }),
    acknowledgeGooglePurchase: async () => { acknowledgements++; },
    hashAccountId: async () => 'account-hash-expected',
    hashPurchaseToken: async () => 'token-hash',
  });
  assert.equal(acknowledgements, 1);
  assert.equal(purchase.state, 'active');
});

test('D1 purchase persistence is idempotent and prevents transaction replay across accounts', async () => {
  const repository = new D1PurchaseRepository(fakeD1());
  const purchase = {
    store: 'apple', storeKey: 'transaction-1', transactionId: 'transaction-1',
    originalTransactionId: 'original-1', accountId: ACCOUNT,
    productId: APPLE_CONFIG.APPLE_UNLOCK_PRODUCT_ID, entitlementId: 'premium_unlock',
    state: 'active', purchasedAt: Date.now(), revokedAt: null,
  };
  assert.equal((await repository.applyPurchase(purchase)).idempotent, false);
  assert.equal((await repository.applyPurchase(purchase)).idempotent, true);
  assert.equal((await repository.getEntitlement(ACCOUNT, 'premium_unlock')).status, 'active');

  await assert.rejects(repository.applyPurchase({
    ...purchase, accountId: '1c2bcd2c-48cf-41f5-b3c8-66939cc33333',
  }), (error) => error instanceof PurchaseError && error.code === 'purchase_replayed');
});

test('a verified revocation updates the persisted entitlement to revoked', async () => {
  const repository = new D1PurchaseRepository(fakeD1());
  const base = {
    store: 'google', storeKey: 'token-hash', transactionId: 'order-1',
    originalTransactionId: null, accountId: ACCOUNT,
    productId: GOOGLE_CONFIG.GOOGLE_UNLOCK_PRODUCT_ID, entitlementId: 'premium_unlock',
    purchasedAt: Date.now(), revokedAt: null,
  };
  await repository.applyPurchase({ ...base, state: 'active' });
  await repository.applyPurchase({ ...base, state: 'revoked', revokedAt: Date.now() });
  assert.equal((await repository.getEntitlement(ACCOUNT, 'premium_unlock')).status, 'revoked');
});

test('D1 account deletion permanently purges entitlements and purchase records', async () => {
  const repository = new D1PurchaseRepository(fakeD1());
  const purchase = {
    store: 'apple', storeKey: 'transaction-1', transactionId: 'transaction-1',
    originalTransactionId: 'original-1', accountId: ACCOUNT,
    productId: APPLE_CONFIG.APPLE_UNLOCK_PRODUCT_ID, entitlementId: 'premium_unlock',
    state: 'active', purchasedAt: Date.now(), revokedAt: null,
  };
  await repository.applyPurchase(purchase);
  assert.equal((await repository.getEntitlement(ACCOUNT, 'premium_unlock'))?.status, 'active');

  const deleteResult = await repository.deleteAccount(ACCOUNT);
  assert.equal(deleteResult.deleted, true);
  assert.equal(deleteResult.accountId, ACCOUNT.toLowerCase());
  assert.equal(await repository.getEntitlement(ACCOUNT, 'premium_unlock'), null);
});

test('Worker endpoints serve Privacy Policy and Terms with security headers and Puphr LLC attribution', async () => {
  const privacyRes = await worker.fetch(new Request('https://api.puphr.com/privacy'), {});
  assert.equal(privacyRes.status, 200);
  assert.equal(privacyRes.headers.get('x-content-type-options'), 'nosniff');
  assert.equal(privacyRes.headers.get('x-frame-options'), 'DENY');
  const privacyHtml = await privacyRes.text();
  assert.ok(privacyHtml.includes('Puphr LLC'));
  assert.ok(privacyHtml.includes('CrossScan Moto'));
  assert.ok(privacyHtml.includes('privacy@puphr.com'));

  const termsRes = await worker.fetch(new Request('https://api.puphr.com/terms'), {});
  assert.equal(termsRes.status, 200);
  const termsHtml = await termsRes.text();
  assert.ok(termsHtml.includes('Puphr LLC'));
  assert.ok(termsHtml.includes('CrossScan Moto'));

  const deletePortalRes = await worker.fetch(new Request('https://api.puphr.com/delete-account'), {});
  assert.equal(deletePortalRes.status, 200);
  const deleteHtml = await deletePortalRes.text();
  assert.ok(deleteHtml.includes('Delete Account'));
  assert.ok(deleteHtml.includes('/v1/auth/otp/verify'));
  assert.ok(deleteHtml.includes("authorization: 'Bearer ' + sessionToken"));
  assert.ok(!deleteHtml.includes('name="accountId"'));

  const healthRes = await worker.fetch(new Request('https://api.puphr.com/health'), {});
  assert.equal(healthRes.status, 200);
  const healthJson = await healthRes.json();
  assert.equal(healthJson.company, 'Puphr LLC');
  assert.equal(healthJson.appId, 'com.puphr.crossscanmoto');
});

test('Worker account deletion requires the owning authenticated session and revokes it', async () => {
  const db = fakeD1();
  const repository = new D1PurchaseRepository(db);
  const { token } = await createTestUserAndSession(db, 'owner@example.com');
  await repository.applyPurchase({
    store: 'apple', storeKey: 'tx-del-1', transactionId: 'tx-del-1',
    originalTransactionId: 'orig-del-1', accountId: ACCOUNT,
    storeAccountId: ACCOUNT,
    productId: APPLE_CONFIG.APPLE_UNLOCK_PRODUCT_ID, entitlementId: 'premium_unlock',
    state: 'active', purchasedAt: Date.now(), revokedAt: null,
  }, { userId: USER_ID });
  assert.equal((await repository.getEntitlement(ACCOUNT, 'premium_unlock'))?.status, 'active');

  const unauthenticated = await worker.fetch(
    new Request('https://api.puphr.com/v1/account', { method: 'DELETE' }),
    { DB: db, SESSION_SECRET },
  );
  assert.equal(unauthenticated.status, 401);

  const guessedId = await worker.fetch(
    new Request(`https://api.puphr.com/v1/account/${ACCOUNT}`, { method: 'DELETE' }),
    { DB: db, SESSION_SECRET },
  );
  assert.equal(guessedId.status, 404);
  assert.equal((await repository.getEntitlement(ACCOUNT, 'premium_unlock'))?.status, 'active');

  const deleteReq = new Request('https://api.puphr.com/v1/account', {
    method: 'DELETE', headers: { authorization: `Bearer ${token}` },
  });
  const deleteRes = await worker.fetch(deleteReq, { DB: db, SESSION_SECRET });
  assert.equal(deleteRes.status, 200);
  const deleteJson = await deleteRes.json();
  assert.equal(deleteJson.deleted, true);
  assert.equal(await repository.getEntitlement(ACCOUNT, 'premium_unlock'), null);

  const revokedSession = await worker.fetch(new Request('https://api.puphr.com/v1/auth/session', {
    headers: { authorization: `Bearer ${token}` },
  }), { DB: db, SESSION_SECRET });
  assert.equal(revokedSession.status, 401);
});

test('Worker OTP request dispatches 6-digit verification code email with auth.trusthentic.com origin', async () => {
  const db = fakeD1();
  let sentEmail = null;
  let sentCode = null;

  const mockEnv = {
    DB: db,
    SESSION_SECRET,
    OTP_PEPPER,
    EMAIL_FROM_ADDRESS: 'noreply@auth.trusthentic.com',
    EMAIL_FROM_NAME: 'CrossScan Moto',
    EMAIL: {
      send: async (msg) => {
        sentEmail = msg.to;
        sentCode = msg.raw;
      },
    },
  };

  const req = new Request('https://api.puphr.com/v1/auth/otp/request', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email: 'rider@example.com', accountId: ACCOUNT }),
  });

  const res = await worker.fetch(req, mockEnv);
  assert.equal(res.status, 200);
  const data = await res.json();
  assert.equal(data.ok, true);
  assert.equal(data.email, 'rider@example.com');
  assert.equal(data.expiresIn, 600);

  assert.equal(sentEmail, 'rider@example.com');
  assert.ok(sentCode.includes('noreply@auth.trusthentic.com'));
  assert.ok(sentCode.includes('CrossScan Moto'));

  // Rate limiting check: second immediate request should return 429
  const req2 = new Request('https://api.puphr.com/v1/auth/otp/request', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email: 'rider@example.com' }),
  });
  const res2 = await worker.fetch(req2, mockEnv);
  assert.equal(res2.status, 429);
  const rateLimitData = await res2.json();
  assert.equal(rateLimitData.error, 'rate_limited');
});

test('Worker OTP verification validates code, handles retries, and issues session token with entitlement', async () => {
  const db = fakeD1();
  const repository = new D1PurchaseRepository(db);
  db.users.set('mechanic@bmw-workshop.com', {
    user_id: USER_ID,
    email: 'mechanic@bmw-workshop.com',
    account_id: ACCOUNT,
    created_at: Date.now(),
    updated_at: Date.now(),
  });
  // Pre-populate entitlement on the account
  await repository.applyPurchase({
    store: 'apple', storeKey: 'tx-otp-1', transactionId: 'tx-otp-1',
    originalTransactionId: 'orig-otp-1', accountId: ACCOUNT,
    productId: APPLE_CONFIG.APPLE_UNLOCK_PRODUCT_ID, entitlementId: 'premium_unlock',
    state: 'active', purchasedAt: Date.now(), revokedAt: null,
  });

  let dispatchedCode = null;
  const mockEnv = {
    DB: db,
    EMAIL_FROM_ADDRESS: 'noreply@auth.trusthentic.com',
    SESSION_SECRET,
    OTP_PEPPER,
    EMAIL: {
      send: async (msg) => {
        const match = msg.raw.match(/login code is:\s+(\d{6})/i) || msg.raw.match(/<div class="code">(\d{6})<\/div>/i);
        if (match) dispatchedCode = match[1];
      },
    },
  };

  // Request OTP
  const reqOtp = new Request('https://api.puphr.com/v1/auth/otp/request', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email: 'mechanic@bmw-workshop.com', accountId: ACCOUNT }),
  });
  const resOtp = await worker.fetch(reqOtp, mockEnv);
  assert.equal(resOtp.status, 200);
  assert.ok(dispatchedCode && /^\d{6}$/.test(dispatchedCode));

  // Verify with WRONG code
  const reqWrong = new Request('https://api.puphr.com/v1/auth/otp/verify', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email: 'mechanic@bmw-workshop.com', code: '000000' }),
  });
  const resWrong = await worker.fetch(reqWrong, mockEnv);
  assert.equal(resWrong.status, 400);

  // Verify with CORRECT code
  const reqCorrect = new Request('https://api.puphr.com/v1/auth/otp/verify', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      email: 'mechanic@bmw-workshop.com',
      code: dispatchedCode,
      accountId: '1c2bcd2c-48cf-41f5-b3c8-66939cc33333',
    }),
  });
  const resCorrect = await worker.fetch(reqCorrect, mockEnv);
  assert.equal(resCorrect.status, 200);
  const verifyData = await resCorrect.json();
  assert.equal(verifyData.ok, true);
  assert.equal(verifyData.email, 'mechanic@bmw-workshop.com');
  assert.equal(verifyData.accountId, ACCOUNT.toLowerCase());
  assert.equal(verifyData.unlocked, true);
  assert.ok(verifyData.sessionToken);

  // Validate session endpoint GET /v1/auth/session
  const reqSession = new Request('https://api.puphr.com/v1/auth/session', {
    method: 'GET',
    headers: { authorization: `Bearer ${verifyData.sessionToken}` },
  });
  const resSession = await worker.fetch(reqSession, mockEnv);
  assert.equal(resSession.status, 200);
  const sessionData = await resSession.json();
  assert.equal(sessionData.email, 'mechanic@bmw-workshop.com');
  assert.equal(sessionData.unlocked, true);
});

test('new OTP account ignores a caller-supplied UUID and creates a server canonical identity', async () => {
  const db = fakeD1();
  let dispatchedCode = null;
  const mockEnv = {
    DB: db,
    SESSION_SECRET,
    OTP_PEPPER,
    EMAIL: {
      send: async (message) => {
        const match = message.raw.match(/login code is:\s+(\d{6})/i) ||
          message.raw.match(/<div class="code">(\d{6})<\/div>/i);
        if (match) dispatchedCode = match[1];
      },
    },
  };
  const email = 'new-user@example.com';
  const forgedAccount = '1c2bcd2c-48cf-41f5-b3c8-66939cc33333';
  const requestOtp = await worker.fetch(new Request('https://api.puphr.com/v1/auth/otp/request', {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, accountId: forgedAccount }),
  }), mockEnv);
  assert.equal(requestOtp.status, 200);
  const verifyOtp = await worker.fetch(new Request('https://api.puphr.com/v1/auth/otp/verify', {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, code: dispatchedCode, accountId: forgedAccount }),
  }), mockEnv);
  assert.equal(verifyOtp.status, 200);
  const session = await verifyOtp.json();
  assert.notEqual(session.accountId, forgedAccount);
  assert.match(session.accountId, /^[0-9a-f-]{36}$/i);
  assert.equal(db.users.get(email).account_id, session.accountId);
});

test('OTP and login fail closed when the server session secret or email binding is missing', async () => {
  const db = fakeD1();
  let sends = 0;
  const otpRequest = await worker.fetch(new Request('https://api.puphr.com/v1/auth/otp/request', {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email: 'secret-test@example.com' }),
  }), { DB: db, OTP_PEPPER, EMAIL: { send: async () => { sends++; } } });
  assert.equal(otpRequest.status, 503);
  assert.equal(sends, 0);
  assert.equal(db.otps.size, 0);

  const loginRequest = await worker.fetch(new Request('https://api.puphr.com/v1/auth/otp/request', {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email: 'secret-test@example.com' }),
  }), { DB: db, SESSION_SECRET, OTP_PEPPER });
  assert.equal(loginRequest.status, 503);
  assert.equal((await loginRequest.json()).error, 'email_delivery_not_configured');
  assert.equal(db.otps.size, 0);
});

test('session records revoke bearer access immediately on logout', async () => {
  const db = fakeD1();
  const { token } = await createTestUserAndSession(db, 'logout@example.com');
  const env = { DB: db, SESSION_SECRET };
  const before = await worker.fetch(new Request('https://api.puphr.com/v1/auth/session', {
    headers: { authorization: `Bearer ${token}` },
  }), env);
  assert.equal(before.status, 200);

  const logout = await worker.fetch(new Request('https://api.puphr.com/v1/auth/logout', {
    method: 'POST', headers: { authorization: `Bearer ${token}` },
  }), env);
  assert.equal(logout.status, 200);
  const after = await worker.fetch(new Request('https://api.puphr.com/v1/auth/session', {
    headers: { authorization: `Bearer ${token}` },
  }), env);
  assert.equal(after.status, 401);
});

test('checkout configuration stays false while store verification secrets are absent', () => {
  assert.deepEqual(purchaseVerificationConfiguration({ DB: {} }), { apple: false, google: false });
  assert.equal(purchaseVerificationConfiguration({ DB: {}, ...APPLE_CONFIG }).apple, true);
  assert.equal(purchaseVerificationConfiguration({ DB: {}, ...APPLE_CONFIG, APPLE_PRIVATE_KEY: '' }).apple, false);
});
