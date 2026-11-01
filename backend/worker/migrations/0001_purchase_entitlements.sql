CREATE TABLE IF NOT EXISTS purchase_records (
  store TEXT NOT NULL CHECK (store IN ('apple', 'google')),
  store_key TEXT NOT NULL,
  transaction_id TEXT NOT NULL,
  original_transaction_id TEXT,
  account_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  entitlement_id TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('active', 'revoked')),
  purchased_at INTEGER NOT NULL,
  revoked_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (store, store_key),
  UNIQUE (store, transaction_id)
);

CREATE INDEX IF NOT EXISTS purchase_records_account_entitlement
  ON purchase_records (account_id, entitlement_id, state);

CREATE TABLE IF NOT EXISTS entitlements (
  account_id TEXT NOT NULL,
  entitlement_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'revoked')),
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (account_id, entitlement_id)
);
