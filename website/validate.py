#!/usr/bin/env python3
"""Checks the built site in website/public/ before it's deployed.

    python3 website/validate.py

Fails on: a title over 60 or a description over 160 characters, a missing
canonical, invalid JSON-LD, a broken internal link or image, an <img>
without width/height/alt, an internal link with .html (Cloudflare Pages
308-redirects those), a sitemap that doesn't match the indexable pages, a
noindex page in the sitemap, or private files (build scripts, notes) in the
public folder.
"""
from __future__ import annotations

import html
import json
import re
import sys
from pathlib import Path

SITE = Path(__file__).resolve().parent
OUT = SITE / "public"
DOMAIN = "https://travary.app"
errors: list[str] = []
warnings: list[str] = []


def resolve(path: str) -> Path | None:
    """The file Cloudflare Pages would serve for a URL path."""
    path = path.split("#")[0].split("?")[0]
    if not path.startswith("/"):
        return None
    rel = path.lstrip("/")
    for cand in ([OUT / rel] if "." in Path(rel).name else []) + [OUT / (rel + ".html"), OUT / rel / "index.html"]:
        if cand.is_file():
            return cand
    if rel == "":
        return OUT / "index.html"
    return None


pages = sorted(OUT.rglob("*.html"))
if not pages:
    sys.exit("public/ is empty: run python3 website/build.py first")

for leak in ("build.py", "validate.py", "serve.py", "README.md", "STRATEGY.md", "content", "templates", "tool",
             "wrangler.toml", "schema.sql", "functions", "research"):
    if (OUT / leak).exists():
        errors.append(f"private file in public/: {leak}")

indexable: set[str] = set()
for page in pages:
    rel = page.relative_to(OUT).as_posix()
    text = page.read_text(encoding="utf-8")
    m = re.search(r"<title>(.*?)</title>", text, re.S)
    title = html.unescape(m.group(1).strip()) if m else ""
    if not title:
        errors.append(f"{rel}: no <title>")
    elif len(title) > 60:
        errors.append(f"{rel}: title {len(title)} chars > 60: {title!r}")
    m = re.search(r'<meta name="description" content="(.*?)"', text, re.S)
    desc = html.unescape(m.group(1)) if m else ""
    if not desc:
        errors.append(f"{rel}: no meta description")
    elif len(desc) > 160:
        errors.append(f"{rel}: description {len(desc)} chars > 160")
    elif len(desc) < 70:
        warnings.append(f"{rel}: description only {len(desc)} chars")
    canon = re.search(r'<link rel="canonical" href="([^"]+)"', text)
    if not canon:
        errors.append(f"{rel}: no canonical")
    elif ".html" in canon.group(1):
        errors.append(f"{rel}: canonical has .html: {canon.group(1)}")
    if len(re.findall(r"<h1[\s>]", text)) != 1:
        errors.append(f"{rel}: expected exactly one <h1>")
    noindex = 'content="noindex' in text
    if not noindex and canon:
        indexable.add(canon.group(1))
    for i, block in enumerate(re.findall(r'<script type="application/ld\+json">(.*?)</script>', text, re.S)):
        try:
            json.loads(block)
        except json.JSONDecodeError as e:
            errors.append(f"{rel}: JSON-LD block {i + 1} invalid: {e}")
    for attr, url in re.findall(r'(href|src|data-film)="([^"]+)"', text):
        if url.startswith(("http://", "https://", "mailto:", "tel:", "data:", "#")):
            if url.startswith(DOMAIN) and ".html" in url:
                errors.append(f"{rel}: absolute internal link with .html: {url}")
            continue
        if url.endswith(".html") or ".html#" in url:
            errors.append(f"{rel}: internal link with .html (use the clean URL): {url}")
        if resolve(url) is None:
            errors.append(f"{rel}: broken {attr} {url}")
    for img in re.findall(r"<img\b[^>]*>", text):
        for need in ("width=", "height=", "alt="):
            if need not in img:
                errors.append(f"{rel}: <img> missing {need[:-1]}: {img[:100]}")
    for m in re.finditer(r'srcset="([^"]+)"', text):
        for part in m.group(1).split(","):
            u = part.strip().split(" ")[0]
            if resolve(u) is None:
                errors.append(f"{rel}: broken srcset {u}")

sitemap = (OUT / "sitemap.xml").read_text(encoding="utf-8")
locs = set(re.findall(r"<loc>(.*?)</loc>", sitemap))
for url in indexable - locs:
    errors.append(f"sitemap: missing {url}")
for url in locs - indexable:
    errors.append(f"sitemap: lists {url}, which is missing or noindex")
robots = (OUT / "robots.txt").read_text(encoding="utf-8")
if f"Sitemap: {DOMAIN}/sitemap.xml" not in robots:
    errors.append("robots.txt doesn't point at the sitemap")
if not (OUT / "404.html").exists():
    errors.append("no 404.html (Cloudflare Pages would serve the home page for every unknown URL)")

big = [(f.stat().st_size, f) for f in OUT.rglob("*") if f.is_file() and f.stat().st_size > 25 * 1024 * 1024]
for size, f in big:
    errors.append(f"{f.relative_to(OUT)} is {size / 1e6:.1f} MB (Cloudflare Pages' limit is 25 MB a file)")

print(f"checked {len(pages)} pages, {len(locs)} sitemap URLs")
for w in warnings:
    print("WARN:", w)
if errors:
    for e in errors:
        print("ERROR:", e)
    sys.exit(1)
print("all checks passed ✓")
