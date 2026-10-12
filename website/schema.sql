-- The travary.app waiting list (Cloudflare D1 database "travary-waitlist").
-- Apply with:
--   cd website && npx wrangler d1 execute travary-waitlist --remote --file schema.sql
-- Safe to re-run.

-- One row per email. Never readable from the web: only functions/api/waitlist.js
-- writes it, and only you read it (dashboard, or tool/waitlist.py).
CREATE TABLE IF NOT EXISTS waitlist (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  email      TEXT NOT NULL UNIQUE COLLATE NOCASE,
  platform   TEXT NOT NULL DEFAULT '' CHECK (platform IN ('', 'iphone', 'android')),
  source     TEXT NOT NULL DEFAULT '',            -- the page they joined from
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
  notified_at TEXT                                 -- set once the launch email has gone out
);

-- Sign-up attempts, for a per-visitor limit. Holds a salted hash of the IP,
-- never the IP itself, and rows older than a day are deleted on every sign-up.
CREATE TABLE IF NOT EXISTS attempts (
  ip_hash    TEXT NOT NULL,
  at         INTEGER NOT NULL                      -- unix seconds
);
CREATE INDEX IF NOT EXISTS attempts_by_hash ON attempts (ip_hash, at);
