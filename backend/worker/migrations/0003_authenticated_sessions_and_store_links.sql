ALTER TABLE purchase_records ADD COLUMN store_account_id TEXT;
UPDATE purchase_records SET store_account_id = account_id WHERE store_account_id IS NULL;

CREATE INDEX IF NOT EXISTS purchase_records_store_account
  ON purchase_records (store, store_account_id, state);

CREATE UNIQUE INDEX IF NOT EXISTS users_account_id_unique
  ON users (account_id);

CREATE TABLE IF NOT EXISTS auth_sessions (
  session_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  email TEXT NOT NULL,
  account_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  revoked_at INTEGER
);

CREATE INDEX IF NOT EXISTS auth_sessions_user ON auth_sessions (user_id, expires_at);

CREATE TABLE IF NOT EXISTS store_account_links (
  store TEXT NOT NULL CHECK (store IN ('apple', 'google')),
  store_account_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  account_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (store, store_account_id)
);

CREATE INDEX IF NOT EXISTS store_account_links_user ON store_account_links (user_id);

CREATE TABLE IF NOT EXISTS auth_rate_limits (
  rate_key TEXT PRIMARY KEY,
  window_start INTEGER NOT NULL,
  request_count INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
);
