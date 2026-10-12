#!/usr/bin/env python3
"""The travary.app waiting list, read from Cloudflare D1 (database
"travary-waitlist"). Uses wrangler's saved login; nothing here is public.

    python3 website/tool/waitlist.py                  # counts by phone and by week
    python3 website/tool/waitlist.py export [file]    # CSV (default: waitlist-YYYY-MM-DD.csv)
    python3 website/tool/waitlist.py remove a@b.com   # someone asked to be removed
    python3 website/tool/waitlist.py notified         # mark everyone emailed at launch

Add --local to any command to use the local copy from `wrangler pages dev`.
"""
from __future__ import annotations

import csv
import json
import os
import subprocess
import sys
from datetime import date
from pathlib import Path

SITE = Path(__file__).resolve().parent.parent
ACCOUNT = "1b63e91f9618e2482f550906703a747f"


def query(sql: str, params: list[str] | None = None, local: bool = False) -> list[dict]:
    if params:  # wrangler has no bound parameters on the command line: quote safely
        for p in params:
            sql = sql.replace("?", "'" + p.replace("'", "''") + "'", 1)
    cmd = ["npx", "--yes", "wrangler@latest", "d1", "execute", "travary-waitlist",
           "--local" if local else "--remote", "--json", "--command", sql]
    out = subprocess.run(cmd, cwd=SITE, capture_output=True, text=True,
                         env={**os.environ, "CLOUDFLARE_ACCOUNT_ID": ACCOUNT})
    if out.returncode:
        sys.exit(out.stderr or out.stdout)
    results = json.loads(out.stdout)
    return results[-1].get("results", []) if results else []


def main() -> None:
    args = [a for a in sys.argv[1:] if a != "--local"]
    local = "--local" in sys.argv
    cmd = args[0] if args else "summary"
    if cmd == "summary":
        total = query("SELECT COUNT(*) AS n FROM waitlist", local=local)[0]["n"]
        print(f"{total} on the waiting list")
        for row in query("SELECT CASE platform WHEN '' THEN 'not said' ELSE platform END AS phone, "
                         "COUNT(*) AS n FROM waitlist GROUP BY platform ORDER BY n DESC", local=local):
            print(f"  {row['phone']:<10} {row['n']}")
        print("by week:")
        for row in query("SELECT strftime('%Y-W%W', created_at) AS week, COUNT(*) AS n FROM waitlist "
                         "GROUP BY week ORDER BY week", local=local):
            print(f"  {row['week']}  {row['n']}")
        print("top pages:")
        for row in query("SELECT source, COUNT(*) AS n FROM waitlist GROUP BY source ORDER BY n DESC LIMIT 10",
                         local=local):
            print(f"  {row['n']:>4}  {row['source'] or '(unknown)'}")
    elif cmd == "export":
        rows = query("SELECT email, platform, source, created_at, notified_at FROM waitlist ORDER BY created_at",
                     local=local)
        path = Path(args[1] if len(args) > 1 else f"waitlist-{date.today().isoformat()}.csv")
        with path.open("w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=["email", "platform", "source", "created_at", "notified_at"])
            writer.writeheader()
            writer.writerows(rows)
        print(f"wrote {len(rows)} rows to {path} (keep it private, and delete it when you're done)")
    elif cmd == "remove" and len(args) > 1:
        email = args[1].strip().lower()
        query("DELETE FROM waitlist WHERE email = ?", [email], local=local)
        left = query("SELECT COUNT(*) AS n FROM waitlist WHERE email = ?", [email], local=local)[0]["n"]
        print("removed" if left == 0 else "still there?")
    elif cmd == "notified":
        query("UPDATE waitlist SET notified_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now') WHERE notified_at IS NULL",
              local=local)
        print("marked everyone not yet notified as notified")
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
