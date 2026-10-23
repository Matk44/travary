#!/usr/bin/env python3
"""Builds travary.app into website/public/ (the only folder that is deployed).

    python3 website/build.py          # build
    python3 website/validate.py       # check links, schema, sizes, sitemap
    python3 website/serve.py          # preview at http://localhost:8787

Pages:
  templates/*.html          the home page, hubs and tools (hand-written)
  content/guides/*.html     articles: a header, the body, then FAQs
  content/itineraries/*.html  day-by-day itineraries (same format)

Art comes straight from the app (assets/, art_packs/sources/,
build/marketing_screens/) and is resized into .cache/img once, so a rebuild
only re-encodes what changed. See README.md for the content format and the
shortcodes ([[postcard|country_jp|alt]] etc.).
"""
from __future__ import annotations

import hashlib
import html
import json
import re
import shutil
import sys
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SITE = Path(__file__).resolve().parent
REPO = SITE.parent
# The app bundles its art as WebP; the PNG masters it was made from live
# here (the same path without assets/), the best source for the site.
ART_MASTERS = REPO / "art_masters" / "bundled" / "art"
OUT = SITE / "public"
CACHE = SITE / ".cache"

# ------------------------------------------------------------------ settings
DOMAIN = "https://travary.app"
BRAND = "Travary"
TAGLINE = "Holiday organiser"

# Flip STORE_LIVE at launch and fill in the App Store ID: every page then
# shows real store badges and the iOS Smart App Banner.
STORE_LIVE = False
IOS_APP_ID = ""  # e.g. "6760000000"
IOS_URL = f"https://apps.apple.com/app/id{IOS_APP_ID}" if IOS_APP_ID else ""
PLAY_URL = ("https://play.google.com/store/apps/details?id=com.travary.app"
            "&referrer=utm_source%3Dtravary_website%26utm_medium%3Dweb")

# Support, the privacy policy, the terms and deleting your data live here
# (content/legal/): the app (TravaryLinks), the store listings and Google's
# OAuth branding link to them. They were on GitHub Pages until 15 Oct 2026.
SUPPORT_SITE = "/support"
PRIVACY_URL = "/privacy"
TERMS_URL = "/terms"
DELETE_URL = "/delete-account"
# Who makes Travary: the developer named on Google Play, and the OAuth
# consent screen's owner (dreamprayer.dev@gmail.com).
PUBLISHER = "Dream Prayer Developer"
SUPPORT_EMAIL = "dreamprayer.dev@gmail.com"

# Family invite links (travary.app/join/ABC234) open the app: iOS checks
# /.well-known/apple-app-site-association, Android /.well-known/assetlinks.json.
# Android also needs the SHA-256 of every key that signs a build people
# install: add the Play App Signing key's (Play Console → Test and release →
# App integrity) and the upload key's before launch; the debug key's is here.
APPLE_APP_ID = "V3D53JGDGD.com.travary.app"
ANDROID_PACKAGE = "com.travary.app"
ANDROID_CERT_SHA256 = [
    # debug (~/.android/debug.keystore on the build Mac)
    "0A:36:06:E4:42:3F:37:85:1C:5F:D9:34:EF:86:F3:F9:B8:B8:A3:55:25:52:71:C7:F5:ED:6E:D0:42:4A:16:E3",
    # upload key (~/travary-upload-keystore.jks)
    "60:93:96:C1:D2:6E:CF:E6:B2:65:54:01:56:D9:6B:78:76:8D:8D:A3:60:CC:33:72:D5:9A:AE:E9:88:81:D2:67",
    # Play App Signing (the key Google signs store installs with; also in Firebase)
    "12:1C:4E:43:D4:0B:F7:0C:63:F1:EB:C3:18:1F:4E:C3:BD:50:06:5A:CB:01:24:8B:3B:98:A5:A5:94:CC:3D:ED",
]

# The Firebase project's Web API key (public, like the app's own keys): the
# one in the account emails' links. /auth/action only ever sends codes
# to travary-444 with it, so a forged link can't post a new password elsewhere.
FIREBASE_WEB_API_KEY = "AIzaSyCZu-S8_-xldAz-t4N-8j0-26nz6ZYVBHE"

# Launch prices (USD), as lib/domain/pricing.dart. Stores show local prices.
PRICE_HOLIDAY_PASS = "$14.99"
PRICE_ANNUAL = "$34.99"
FREE_IMPORTS = 2  # Pricing.freeSmartImports

# Google Search Console HTML-tag verification (keep once set).
GOOGLE_SITE_VERIFICATION = "BNFiwdJQsQhtfB-wy4vX7FkKSjhbBQf8b-ICFFr4dos"
# dreamprayer.dev@gmail.com's own Search Console verification: it owns the
# Firebase/Google Cloud project, and Google's OAuth branding check needs a
# project owner to own the domain. Never remove either tag.
GOOGLE_SITE_VERIFICATION_PROJECT = "gd5CFX6leMbMOK_J_Jh99LmivB9aux2Y7YQsW3Zjj60"
BING_SITE_VERIFICATION = ""

TODAY = date.today().isoformat()

# --------------------------------------------------------------- the places
# Every destination with a postcard (art_packs/sources/<pack>/common/), its
# display name, and the onboarding stage that suits it.
PLACES = {
    "city_jp_kyoto": ("Kyoto", "city_jp_kyoto"),
    "city_fr_paris": ("Paris", "city_fr_paris"),
    "city_us_orlando": ("Orlando", "city_us_orlando"),
    "region_gb_lake_district": ("Lake District", "country_gb"),
    "region_id_bali": ("Bali", "country_id"),
    "country_jp": ("Japan", "country_jp"),
    "country_fr": ("France", "country_fr"),
    "country_it": ("Italy", "country_it"),
    "country_es": ("Spain", "country_es"),
    "country_gr": ("Greece", "country_gr"),
    "country_pt": ("Portugal", "country_pt"),
    "country_gb": ("United Kingdom", "country_gb"),
    "country_us": ("United States", "country_us"),
    "country_au": ("Australia", "country_au"),
    "country_nz": ("New Zealand", "country_nz"),
    "country_th": ("Thailand", "country_th"),
    "country_id": ("Indonesia", "country_id"),
    "country_sg": ("Singapore", "city_sg_singapore"),
    "country_ae": ("United Arab Emirates", "country_ae"),
    "country_tr": ("Türkiye", "country_tr"),
    "country_mx": ("Mexico", "country_mx"),
    "country_ca": ("Canada", "country_ca"),
    "country_ch": ("Switzerland", "country_ch"),
    "country_de": ("Germany", "country_de"),
    "country_nl": ("Netherlands", "country_nl"),
    "country_kr": ("South Korea", "country_kr"),
    "country_cn": ("China", "country_cn"),
    "country_in": ("India", "country_in"),
    "country_br": ("Brazil", "country_br"),
    "country_za": ("South Africa", "country_za"),
}

# Travi's films used on the site (assets/onboarding/travi/films/).
FILMS = ["hello-idle", "proud-idle", "reading-idle", "tag-idle", "folio-full-idle",
         "roll-in", "world", "folio-up", "got-it", "envelope", "card-out", "later"]

EPHEMERA = {  # assets/art/common/<name>.png → width
    "countdown_luggage_tag": 420, "tag": 360, "boarding_pass": 900, "room_card": 900,
    "travel_ticket": 900, "featured_reservation": 900, "note_paper": 1000,
    "reservation_card_blank": 1000, "ongoing_tag": 1000, "documents_postmark": 320,
    "documents_stamp_01": 380, "documents_stamp_02": 380, "documents_stamp_03": 380,
    "add_passport": 420, "add_snap": 420, "trip_postcard_anywhere": 960,
    "documents_ticket_01": 1000,
}


# ================================================================== assets
@dataclass
class Img:
    url: str
    width: int
    height: int


IMAGES: dict[str, Img] = {}


def _encode(src: Path, dest_rel: str, width: int | None = None, quality: int = 80,
            crop: tuple[float, float] | None = None) -> Img:
    """Resize src to `width` as WebP at public/img/<dest_rel>, cached by source mtime."""
    cached = CACHE / "img" / dest_rel
    stamp = f"{src.stat().st_mtime_ns}-{width}-{quality}-{crop}"
    meta = cached.with_suffix(cached.suffix + ".meta")
    if not (cached.exists() and meta.exists() and meta.read_text().split("|")[0] == stamp):
        cached.parent.mkdir(parents=True, exist_ok=True)
        im = Image.open(src)
        im.load()
        im = im.convert("RGBA") if im.mode in ("RGBA", "LA", "P") else im.convert("RGB")
        if crop:
            top, bottom = crop
            im = im.crop((0, int(im.height * top), im.width, int(im.height * bottom)))
        if width and im.width > width:
            im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
        im.save(cached, "WEBP", quality=quality, method=6)
        meta.write_text(f"{stamp}|{im.width}|{im.height}")
    _, w, h = meta.read_text().split("|")
    dest = OUT / "img" / dest_rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(cached, dest)
    return Img(f"/img/{dest_rel}", int(w), int(h))


def _copy(src: Path, dest_rel: str) -> Img:
    dest = OUT / "img" / dest_rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)
    with Image.open(src) as im:
        return Img(f"/img/{dest_rel}", im.width, im.height)


def build_assets() -> None:
    packs = REPO / "art_packs" / "sources"
    for pack in PLACES:
        common = packs / pack / "common"
        IMAGES[f"postcard:{pack}"] = _encode(common / "trip_postcard.webp", f"postcard/{pack}.webp", 960, 80)
        IMAGES[f"postcard-sm:{pack}"] = _encode(common / "trip_postcard.webp", f"postcard/{pack}-480.webp", 480, 78)
        IMAGES[f"countdown:{pack}"] = _encode(common / "countdown_postcard.webp", f"countdown/{pack}.webp", 560, 72)
        for name, w in (("featured_ticket", 900), ("room_card", 900), ("reservation_card", 1000),
                        ("documents_destination_stamp", 380)):
            f = common / f"{name}.webp"
            if f.exists():
                IMAGES[f"{name}:{pack}"] = _encode(f, f"{name.replace('_', '-')}/{pack}.webp", w, 80)
    common = REPO / "assets" / "art" / "common"
    masters = ART_MASTERS / "common"
    IMAGES["postcard:anywhere"] = _encode(masters / "trip_postcard_anywhere.png", "postcard/anywhere.webp", 960, 80)
    IMAGES["postcard-sm:anywhere"] = _encode(masters / "trip_postcard_anywhere.png", "postcard/anywhere-480.webp", 480, 78)
    IMAGES["countdown:anywhere"] = _encode(common / "countdown_postcard_anywhere.webp", "countdown/anywhere.webp", 560, 72)
    for name, w in EPHEMERA.items():
        IMAGES[f"ephemera:{name}"] = _encode(masters / f"{name}.png", f"ephemera/{name}.webp", w, 82)
    IMAGES["linen"] = _encode(masters / "linen.png", "ephemera/linen.webp", 512, 70)
    for f in sorted((ART_MASTERS / "icons").glob("*.png")):
        IMAGES[f"icon:{f.stem}"] = _encode(f, f"icon/{f.stem}.webp", 112, 85)
    for f in sorted((REPO / "assets" / "onboarding" / "stages").glob("*.webp")):
        # The stage down to a little below the floor line, where Travi stands.
        IMAGES[f"stage:{f.stem}"] = _encode(f, f"stage/{f.stem}.webp", 600, 78, crop=(0.08, 0.84))
    for f in sorted((REPO / "assets" / "onboarding" / "travi" / "stills").glob("*.webp")):
        IMAGES[f"travi:{f.stem}"] = _copy(f, f"travi/{f.stem}.webp")
    for name in FILMS:
        IMAGES[f"film:{name}"] = _copy(REPO / "assets" / "onboarding" / "travi" / "films" / f"{name}.webp",
                                       f"travi/film/{name}.webp")
    screens = REPO / "build" / "marketing_screens"
    if not screens.exists():
        sys.exit("build/marketing_screens/ is missing: run tool/visual_qa.sh, then\n"
                 "  TRAVARY_VISUAL_QA=1 flutter test website/tool/marketing_screens_test.dart")
    for f in sorted(screens.glob("*.png")):
        IMAGES[f"screen:{f.stem}"] = _encode(f, f"screen/{f.stem}.webp", 600, 86)
    build_brand()


def build_brand() -> None:
    icon = Image.open(REPO / "assets" / "branding" / "travary_app_icon_master.png").convert("RGB")
    brand = OUT / "img" / "brand"
    brand.mkdir(parents=True, exist_ok=True)

    def rounded(size: int) -> Image.Image:
        im = icon.resize((size, size), Image.LANCZOS).convert("RGBA")
        mask = Image.new("L", (size * 4, size * 4), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, size * 4 - 1, size * 4 - 1), radius=size * 4 * 0.225, fill=255)
        im.putalpha(mask.resize((size, size), Image.LANCZOS))
        return im

    rounded(32).save(brand / "favicon-32.png")
    rounded(96).save(brand / "logo-96.png")
    rounded(192).save(brand / "icon-192.png")
    rounded(512).save(brand / "icon-512.png")
    icon.resize((180, 180), Image.LANCZOS).save(OUT / "apple-touch-icon.png")
    rounded(48).save(OUT / "favicon.ico", sizes=[(16, 16), (32, 32), (48, 48)])
    IMAGES["brand:logo"] = Img("/img/brand/logo-96.png", 96, 96)


# --------------------------------------------------------------- og images
FONT_DIR = REPO / "build" / "visual_qa" / "fonts"


def _font(prefix: str, size: int) -> ImageFont.FreeTypeFont:
    for f in sorted(FONT_DIR.glob(prefix + "*.ttf")):
        return ImageFont.truetype(str(f), size)
    return ImageFont.load_default(size)


def og_image(slug: str, title: str, art_key: str, kicker: str) -> str:
    """A 1200×630 share card: linen, the page's postcard, its title, Travi."""
    dest = OUT / "img" / "og" / f"{slug}.jpg"
    dest.parent.mkdir(parents=True, exist_ok=True)
    key = hashlib.sha1(f"{title}|{art_key}|{kicker}|v3".encode()).hexdigest()[:12]
    cached = CACHE / "og" / f"{slug}-{key}.jpg"
    if not cached.exists():
        cached.parent.mkdir(parents=True, exist_ok=True)
        linen = Image.open(ART_MASTERS / "common" / "linen.png").convert("RGB").resize((630, 630))
        canvas = Image.new("RGB", (1200, 630))
        for x in range(0, 1200, 630):
            canvas.paste(linen, (x, 0))
        draw = ImageDraw.Draw(canvas)
        src = _art_source(art_key)
        card = Image.open(src).convert("RGBA")
        card.thumbnail((560, 420), Image.LANCZOS)
        card = card.rotate(-3, expand=True, resample=Image.BICUBIC)
        shadow = Image.new("RGBA", card.size, (16, 43, 70, 0))
        shadow.putalpha(card.getchannel("A").point(lambda a: int(a * 0.25)))
        canvas.paste(shadow, (612, 120), shadow)
        canvas.paste(card, (600, 104), card)
        travi = Image.open(REPO / "assets" / "onboarding" / "travi" / "stills" / "wave.webp").convert("RGBA")
        travi.thumbnail((300, 240), Image.LANCZOS)
        canvas.paste(travi, (930, 400), travi)
        navy = (16, 43, 70)
        draw.text((72, 74), kicker.upper(), font=_font("Inter_700", 22), fill=(184, 81, 50))
        words, lines, line = title.split(), [], ""
        font = _font("SourceSerif4_700", 60)
        for w in words:
            trial = (line + " " + w).strip()
            if draw.textlength(trial, font=font) > 500 and line:
                lines.append(line)
                line = w
            else:
                line = trial
        lines.append(line)
        if len(lines) > 5:
            font = _font("SourceSerif4_700", 48)
        y = 122
        for ln in lines[:6]:
            draw.text((72, y), ln, font=font, fill=navy)
            y += font.size + 12
        logo = Image.open(REPO / "assets" / "branding" / "travary_app_icon_master.png").convert("RGB").resize((56, 56))
        mask = Image.new("L", (56, 56), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, 55, 55), radius=13, fill=255)
        canvas.paste(logo, (72, 520), mask)
        draw.text((142, 530), "Travary", font=_font("SourceSerif4_700", 34), fill=navy)
        draw.text((292, 540), "travary.app", font=_font("Inter_500", 22), fill=(86, 97, 122))
        canvas.save(cached, "JPEG", quality=84, optimize=True)
    shutil.copy2(cached, dest)
    return f"/img/og/{slug}.jpg"


def _art_source(art_key: str) -> Path:
    kind, _, ident = art_key.partition(":")
    packs = REPO / "art_packs" / "sources"
    if kind in ("postcard", "countdown") and ident == "anywhere":
        if kind == "postcard":
            return ART_MASTERS / "common" / "trip_postcard_anywhere.png"
        return REPO / "assets" / "art" / "common" / "countdown_postcard_anywhere.webp"
    if kind == "postcard":
        return packs / ident / "common" / "trip_postcard.webp"
    if kind == "countdown":
        return packs / ident / "common" / "countdown_postcard.webp"
    if kind == "ephemera":
        return ART_MASTERS / "common" / f"{ident}.png"
    if kind == "screen":
        return REPO / "build" / "marketing_screens" / f"{ident}.png"
    return REPO / "art_packs" / "sources" / "country_jp" / "common" / "trip_postcard.webp"


# ================================================================ helpers
def esc(s: str) -> str:
    return html.escape(s, quote=True)


def strip_tags(s: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", s))).strip()


def human_date(iso: str) -> str:
    y, m, d = (int(x) for x in iso.split("-"))
    months = ["January", "February", "March", "April", "May", "June", "July", "August",
              "September", "October", "November", "December"]
    return f"{d} {months[m - 1]} {y}"


def asset_version(path: Path) -> str:
    return hashlib.sha1(path.read_bytes()).hexdigest()[:10]


def img_tag(key: str, alt: str, cls: str = "", *, sizes: str = "", eager: bool = False,
            srcset_key: str | None = None, extra: str = "") -> str:
    im = IMAGES[key]
    attrs = [f'src="{im.url}"', f'width="{im.width}"', f'height="{im.height}"', f'alt="{esc(alt)}"']
    if srcset_key and srcset_key in IMAGES:
        sm = IMAGES[srcset_key]
        attrs.append(f'srcset="{sm.url} {sm.width}w, {im.url} {im.width}w"')
        attrs.append(f'sizes="{sizes or "(max-width: 700px) 92vw, 480px"}"')
    if cls:
        attrs.append(f'class="{cls}"')
    attrs.append('decoding="async"')
    attrs.append('fetchpriority="high"' if eager else 'loading="lazy"')
    if extra:
        attrs.append(extra)
    return f"<img {' '.join(attrs)}>"


def film_tag(film: str, still: str, alt: str, cls: str = "", eager: bool = False) -> str:
    """Travi's still first; site.js swaps in the film once it's on screen."""
    f = IMAGES[f"film:{film}"]
    return img_tag(f"travi:{still}", alt, f"travi {cls}".strip(), eager=eager,
                   extra=f'data-film="{f.url}"')


def store_badges(where: str = "") -> str:
    apple = ('<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.53 4.08zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/></svg>')
    play = ('<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M3.6 1.8c-.4.2-.6.6-.6 1.1v18.2c0 .5.2.9.6 1.1l10.1-10.2L3.6 1.8zm12 8.1L6.9 1.2l10.6 6.1-1.9 2.6zm3.4 1.2l-2.6-1.5-2.1 2.4 2.1 2.4 2.7-1.5c.8-.5.8-1.4-.1-1.8zM6.9 22.8l8.7-8.7 1.9 2.6-10.6 6.1z"/></svg>')
    if STORE_LIVE:
        ios = (f'<a class="badge" href="{esc(IOS_URL)}" rel="noopener" data-track="store_ios_{where}">{apple}'
               f'<span><small>Download on the</small>App Store</span></a>')
        android = (f'<a class="badge" href="{esc(PLAY_URL)}" rel="noopener" data-track="store_play_{where}">{play}'
                   f'<span><small>Get it on</small>Google Play</span></a>')
        return f'<div class="badges">{ios}{android}</div>'
    # Before launch, every badge opens the waiting list (/early-access without JS).
    return ('<div class="badges soon">'
            f'<a class="btn coral wl-cta" href="/early-access" data-waitlist="{where}">Join the waiting list</a>'
            f'<a class="badge is-soon" href="/early-access" data-waitlist="{where}">{apple}<span><small>Coming soon to the</small>App Store</span></a>'
            f'<a class="badge is-soon" href="/early-access" data-waitlist="{where}">{play}<span><small>Coming soon to</small>Google Play</span></a>'
            '</div>')


def waitlist_form(ident: str, path: str) -> str:
    """The waiting-list form: posts to functions/api/waitlist.js (JSON from
    site.js, or a plain form post without JavaScript)."""
    return f'''<form class="wl-form" action="/api/waitlist" method="post" novalidate>
  <input type="hidden" name="source" value="{esc(path)}">
  <input type="hidden" name="t" value="">
  <div class="wl-hp" aria-hidden="true"><label>Company <input name="company" tabindex="-1" autocomplete="off"></label></div>
  <label class="wl-label" for="wl-email-{ident}">Your email</label>
  <input class="wl-email" id="wl-email-{ident}" type="email" name="email" required maxlength="254" autocomplete="email" inputmode="email" placeholder="you@example.com">
  <fieldset class="wl-platform"><legend class="wl-label">Your phone</legend>
    <label><input type="radio" name="platform" value="iphone"><span>iPhone</span></label>
    <label><input type="radio" name="platform" value="android"><span>Android</span></label>
  </fieldset>
  <button class="btn coral wl-submit" type="submit">Join the waiting list</button>
  <p class="wl-error" role="alert" hidden></p>
  <p class="wl-fine">We'll email you when Travary is out, with the link for your phone. That's all we use your address for, and we never share it. Want it removed? Email <a href="mailto:{SUPPORT_EMAIL}?subject=Remove%20me%20from%20the%20Travary%20waiting%20list">{SUPPORT_EMAIL}</a>.</p>
</form>'''


def waitlist_done() -> str:
    return f'''<div class="wl-done" hidden>
  <p class="eyebrow">You're on the list</p>
  <h2 class="wl-title">See you on launch day.</h2>
  <p>We'll email <b class="wl-done-email">you</b> the day Travary arrives on the App Store and Google Play.</p>
  <p class="wl-next"><a href="/holiday-countdown">Start a countdown while you wait →</a></p>
  <button class="wl-again" type="button">Add another email</button>
</div>'''


def waitlist_inline(page: "Page | None", heading: str, lede: str = "") -> str:
    """The waiting-list form on the page itself (app pages): the highest-intent
    visitors join here without opening anything."""
    if STORE_LIVE:
        return store_badges("inline")
    lede = lede or "Travary is nearly packed. Leave your email and we'll send you the download link the day it lands on the App Store and Google Play."
    return f'''<div class="wl-card paper wl-inline" id="join">
  <div class="wl-start">
    <p class="eyebrow">Early access</p>
    <h2 class="wl-title appbox-title">{esc(heading)}</h2>
    <p class="wl-lede">{esc(lede)}</p>
    {waitlist_form("inline", page.path if page else "/")}
  </div>
  {waitlist_done()}
</div>'''


def waitlist_dialog(page: "Page") -> str:
    if STORE_LIVE:
        return ""
    return f'''<dialog class="wl-dialog" id="waitlist" aria-labelledby="wl-dialog-title">
  <button class="wl-close" type="button" aria-label="Close">×</button>
  <div class="wl-art" style="background-image:url({IMAGES["stage:anywhere"].url})">
    <div class="wl-floor" aria-hidden="true"></div>
    {film_tag("envelope", "envelope", "Travi, the Travary suitcase, holding an invitation", "wl-travi").replace("<img ", f'<img data-done="{IMAGES["film:proud-idle"].url}" ', 1)}
  </div>
  <div class="wl-body">
    <div class="wl-start">
      <p class="eyebrow">Early access</p>
      <h2 class="wl-title" id="wl-dialog-title">Be first on board.</h2>
      <p class="wl-lede">Travary is nearly packed. Leave your email and we'll send you the download link the day it lands on the App Store and Google Play.</p>
      {waitlist_form("dialog", page.path)}
    </div>
    {waitlist_done()}
  </div>
</dialog>'''


# =============================================================== the pages
@dataclass
class Page:
    path: str                 # URL path, "/" or "/guides/foo"
    title: str
    meta: str
    h1: str = ""
    kind: str = "page"        # home | guide | itinerary | tool | hub | 404
    section: str = ""
    crumb: str = ""
    art: str = ""             # image key for the hero/og
    art_alt: str = ""
    card: str = ""            # app pages: one line for the home page's "Made for" grid
    icon: str = ""
    travi: str = "present"
    published: str = "2026-10-10"
    updated: str = "2026-10-10"
    answer: str = ""
    body: str = ""
    faqs: list[tuple[str, str]] = field(default_factory=list)
    related: list[str] = field(default_factory=list)
    order: int = 100
    noindex: bool = False
    schema: list[dict] = field(default_factory=list)
    og: str = ""
    keywords: str = ""
    minutes: int = 0
    extra_head: str = ""
    scripts: list[str] = field(default_factory=list)

    @property
    def url(self) -> str:
        return DOMAIN + self.path

    @property
    def file(self) -> Path:
        if self.path == "/":
            return OUT / "index.html"
        if self.path.endswith("/"):
            return OUT / self.path.strip("/") / "index.html"
        return OUT / (self.path.strip("/") + ".html")


SECTIONS = {
    "Planning": "Plan the holiday",
    "Flights": "Flights and the day you fly",
    "Documents": "Passports and documents",
    "Apps": "Apps and tools",
    "Itineraries": "Itineraries",
    "App": "The itinerary app",
    "Compare": "Compare apps",
}


def parse_content(path: Path, prefix: str, kind: str) -> Page:
    """A content file: `key: value` lines, `---`, the body HTML, `---faq---`, Q:/A: pairs."""
    text = path.read_text(encoding="utf-8")
    head, _, rest = text.partition("\n---\n")
    body, _, faq = rest.partition("\n---faq---\n")
    meta: dict[str, str] = {}
    for line in head.strip().splitlines():
        if line.strip() and not line.startswith("#"):
            k, _, v = line.partition(":")
            meta[k.strip()] = v.strip()
    faqs, q = [], None
    for line in faq.strip().splitlines():
        if line.startswith("Q:"):
            q = line[2:].strip()
        elif line.startswith("A:") and q:
            faqs.append((q, line[2:].strip()))
            q = None
        elif line.strip() and faqs and q is None:
            faqs[-1] = (faqs[-1][0], faqs[-1][1] + " " + line.strip())
    slug = path.stem
    words = len(strip_tags(body).split()) + len(strip_tags(meta.get("answer", "")).split())
    return Page(
        path=f"{prefix}{slug}", title=meta["title"], meta=meta["meta"], h1=meta.get("h1", meta["title"]),
        kind=kind, section=meta.get("section", "Planning"), crumb=meta.get("crumb", meta.get("h1", "")),
        art=meta.get("art", "postcard:anywhere"), art_alt=meta.get("art_alt", ""), travi=meta.get("travi", "present"),
        card=meta.get("card", ""), icon=meta.get("icon", ""),
        published=meta.get("published", "2026-10-10"), updated=meta.get("updated", "2026-10-10"),
        answer=meta.get("answer", ""), body=body.strip(), faqs=faqs,
        related=[r.strip() for r in meta.get("related", "").split(",") if r.strip()],
        order=int(meta.get("order", "100")), keywords=meta.get("keywords", ""),
        minutes=max(2, round(words / 230)),
    )


# ------------------------------------------------------------ shortcodes
def shortcodes(s: str, page: Page | None = None) -> str:
    def repl(m: re.Match) -> str:
        parts = [p.strip() for p in m.group(1).split("|")]
        name, args = parts[0], parts[1:]
        a = lambda i, d="": args[i] if len(args) > i and args[i] else d  # noqa: E731
        if name == "postcard":
            return img_tag(f"postcard:{a(0)}", a(1), a(2, "postcard"), srcset_key=f"postcard-sm:{a(0)}",
                           sizes=a(3, "(max-width: 700px) 92vw, 640px"))
        if name == "countdown":
            return img_tag(f"countdown:{a(0)}", a(1), a(2, "postcard"))
        if name in ("featured_ticket", "room_card", "reservation_card", "documents_destination_stamp"):
            return img_tag(f"{name}:{a(0)}", a(1), a(2, name.replace("_", "-")))
        if name == "stage":
            return img_tag(f"stage:{a(0)}", a(1), a(2, "stage"))
        if name == "travi":
            return img_tag(f"travi:{a(0)}", a(1, "Travi, the Travary suitcase"), f"travi {a(2)}".strip())
        if name == "film":
            return film_tag(a(0), a(1), a(2, "Travi, the Travary suitcase"), a(3))
        if name == "icon":
            return img_tag(f"icon:{a(0)}", a(1), f"icon {a(2)}".strip())
        if name == "ephemera":
            return img_tag(f"ephemera:{a(0)}", a(1), a(2))
        if name == "screen":
            return phone(a(0), a(1), a(2))
        if name == "badges":
            return store_badges(a(0, "inline"))
        if name == "waitlist":
            return waitlist_inline(page, a(0, "Be first on board."), a(1))
        if name == "appbox":
            return appbox(a(0), a(1, "proud"), a(2))
        if name == "updated":
            return human_date(page.updated) if page else ""
        if name == "imports":
            return str(FREE_IMPORTS)
        if name == "price_pass":
            return PRICE_HOLIDAY_PASS
        if name == "price_annual":
            return PRICE_ANNUAL
        raise ValueError(f"unknown shortcode [[{m.group(1)}]]")
    return re.sub(r"\[\[([^\]]+)\]\]", repl, s)


def phone(screen: str, alt: str, cls: str = "", eager: bool = False) -> str:
    return (f'<figure class="phone {cls}">'
            f'<div class="phone-glass">{img_tag("screen:" + screen, alt, eager=eager)}</div></figure>')


def appbox(text: str, pose: str = "proud", heading: str = "") -> str:
    heading = heading or "Travary does this part for you"
    return (f'<aside class="appbox reveal">'
            f'<div class="appbox-art">{img_tag("travi:" + pose, "Travi, the Travary suitcase, holding up a ticket")}</div>'
            f'<div class="appbox-copy"><p class="eyebrow">The Travary app</p><h2 class="appbox-title">{esc(heading)}</h2>'
            f'<p>{text}</p>{store_badges("appbox")}</div></aside>')


# --------------------------------------------------------------- the frame
NAV = [("/#how", "How it works"), ("/guides/", "Guides"), ("/itineraries/", "Itineraries"),
       ("/holiday-countdown", "Countdown"), ("/itinerary-template", "Template")]


def header(page: Page) -> str:
    links = "".join(
        f'<a href="{href}"{" aria-current=\"page\"" if page.path == href else ""}>{label}</a>'
        for href, label in NAV)
    return f'''<header class="site-header">
  <div class="wrap header-row">
    <a class="brand" href="/" aria-label="Travary home">{img_tag("brand:logo", "", "brand-logo", eager=True)}<span>Travary</span></a>
    <nav class="site-nav" aria-label="Main">{links}</nav>
    <a class="nav-cta" href="{"/early-access" if not STORE_LIVE else "/#download"}" data-waitlist="nav">Get the app</a>
    <button class="nav-toggle" type="button" aria-expanded="false" aria-controls="mobile-nav"><span></span><span></span><span class="sr">Menu</span></button>
  </div>
  <nav id="mobile-nav" class="mobile-nav" aria-label="Main" hidden>{links}<a href="{"/early-access" if not STORE_LIVE else "/#download"}" data-waitlist="menu">Get the app</a></nav>
</header>'''


def footer() -> str:
    guide_links = "".join(f'<li><a href="{p.path}">{esc(p.crumb or p.h1)}</a></li>'
                          for p in sorted(GUIDES, key=lambda p: p.order)[:8])
    trip_links = "".join(f'<li><a href="{p.path}">{esc(p.crumb or p.h1)}</a></li>' for p in ITINERARIES)
    return f'''<footer class="site-footer">
  <div class="perf" aria-hidden="true"></div>
  <div class="wrap footer-grid">
    <div class="footer-brand">
      <a class="brand" href="/">{img_tag("brand:logo", "", "brand-logo")}<span>Travary</span></a>
      <p>Add your bookings. Travary sorts them into days and opens each morning on what you need right now, with tickets one tap away.</p>
      {store_badges("footer")}
    </div>
    <div><h2>Plan</h2><ul>{guide_links}<li><a href="/guides/">All guides</a></li></ul></div>
    <div><h2>Itineraries</h2><ul>{trip_links}<li><a href="/itineraries/">All itineraries</a></li></ul>
      <h2>Free tools</h2><ul><li><a href="/holiday-countdown">Holiday countdown</a></li><li><a href="/itinerary-template">Itinerary template</a></li></ul></div>
    <div><h2>Travary for</h2><ul>{"".join(f'<li><a href="{p.path}">{esc(p.crumb)}</a></li>' for p in APP_PAGES if p.card)}</ul>
      <h2>Travary</h2><ul>
      <li><a href="/guides/how-travary-works">How Travary works</a></li>
      {"".join(f'<li><a href="{p.path}">{esc(p.crumb)}</a></li>' for p in APP_PAGES if not p.card)}
      <li><a href="{SUPPORT_SITE}">Help and support</a></li>
      <li><a href="{PRIVACY_URL}">Privacy policy</a></li>
      <li><a href="{TERMS_URL}">Terms of use</a></li>
      <li><a href="{DELETE_URL}">Delete your data</a></li>
      <li><a href="mailto:{SUPPORT_EMAIL}">{SUPPORT_EMAIL}</a></li></ul></div>
  </div>
  <div class="wrap footnote"><p>© 2026 Travary, made by {PUBLISHER}. Travel guidance on this site is general information: always check entry rules with the official source for your passport. Apple and the Apple logo are trademarks of Apple Inc. Google Play is a trademark of Google LLC. Other names belong to their owners and are used only to describe them.</p></div>
</footer>'''


def layout(page: Page, main: str) -> str:
    css_v = asset_version(SITE / "static" / "css" / "site.css")
    js_v = asset_version(SITE / "static" / "js" / "site.js")
    og = page.og or og_image(page.path.strip("/").replace("/", "-") or "home", page.h1 or page.title,
                             page.art or "postcard:anywhere", SECTIONS.get(page.section, page.section) or TAGLINE)
    robots = '<meta name="robots" content="noindex, follow">' if page.noindex else \
        '<meta name="robots" content="index, follow, max-image-preview:large">'
    verify = ""
    for token in (GOOGLE_SITE_VERIFICATION, GOOGLE_SITE_VERIFICATION_PROJECT):
        if token:
            verify += f'<meta name="google-site-verification" content="{token}">\n'
    if BING_SITE_VERIFICATION:
        verify += f'<meta name="msvalidate.01" content="{BING_SITE_VERIFICATION}">\n'
    banner = f'<meta name="apple-itunes-app" content="app-id={IOS_APP_ID}">\n' if STORE_LIVE and IOS_APP_ID else ""
    schema = "\n".join(f'<script type="application/ld+json">{json.dumps(s, ensure_ascii=False)}</script>'
                       for s in page.schema)
    scripts = "".join(f'<script src="/js/{s}?v={asset_version(SITE / "static" / "js" / s)}" defer></script>'
                      for s in page.scripts)
    og_type = "article" if page.kind in ("guide", "itinerary") else "website"
    return f'''<!doctype html>
<html lang="en" class="no-js">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{esc(page.title)}</title>
<meta name="description" content="{esc(page.meta)}">
{robots}
<link rel="canonical" href="{page.url}">
{verify}{banner}<meta name="theme-color" content="#F3ECDF">
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" type="image/png" sizes="32x32" href="/img/brand/favicon-32.png">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<link rel="manifest" href="/site.webmanifest">
<meta property="og:site_name" content="Travary">
<meta property="og:type" content="{og_type}">
<meta property="og:title" content="{esc(page.h1 or page.title)}">
<meta property="og:description" content="{esc(page.meta)}">
<meta property="og:url" content="{page.url}">
<meta property="og:image" content="{DOMAIN}{og}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Source+Serif+4:ital,opsz,wght@0,8..60,400;0,8..60,500;0,8..60,600;0,8..60,700;1,8..60,400;1,8..60,600&family=Inter:wght@400;500;600;700&family=IBM+Plex+Mono:wght@500;600&display=swap">
<link rel="stylesheet" href="/css/site.css?v={css_v}">
{page.extra_head}{schema}
</head>
<body class="kind-{page.kind}">
<a class="skip" href="#main">Skip to content</a>
{header(page)}
<main id="main">
{main}
</main>
{footer()}
{waitlist_dialog(page)}
<script src="/js/site.js?v={js_v}" defer></script>{scripts}
</body>
</html>
'''


# ---------------------------------------------------------------- schema
ORG = {"@type": "Organization", "@id": f"{DOMAIN}/#org", "name": "Travary", "url": DOMAIN + "/",
       "logo": f"{DOMAIN}/img/brand/icon-512.png", "email": SUPPORT_EMAIL,
       "parentOrganization": {"@type": "Organization", "name": PUBLISHER}}


def crumbs_schema(items: list[tuple[str, str]]) -> dict:
    return {"@context": "https://schema.org", "@type": "BreadcrumbList", "itemListElement": [
        {"@type": "ListItem", "position": i + 1, "name": n, **({"item": DOMAIN + u} if u else {})}
        for i, (n, u) in enumerate(items)]}


def faq_schema(faqs: list[tuple[str, str]]) -> dict:
    return {"@context": "https://schema.org", "@type": "FAQPage", "mainEntity": [
        {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": strip_tags(a)}}
        for q, a in faqs]}


def article_schema(p: Page) -> dict:
    return {"@context": "https://schema.org", "@type": "Article", "headline": p.h1,
            "description": p.meta, "image": f"{DOMAIN}/img/og/{p.path.strip('/').replace('/', '-')}.jpg",
            "datePublished": p.published, "dateModified": p.updated,
            "author": {"@type": "Organization", "name": "Travary", "url": DOMAIN + "/"},
            "publisher": {"@type": "Organization", "name": "Travary",
                          "logo": {"@type": "ImageObject", "url": f"{DOMAIN}/img/brand/icon-512.png"}},
            "mainEntityOfPage": p.url,
            **({"about": {"@id": f"{DOMAIN}/#app"}} if p.kind == "app" else {})}


def faq_html(faqs: list[tuple[str, str]]) -> str:
    return "\n".join(f'<details><summary>{esc(q)}</summary><div><p>{a}</p></div></details>' for q, a in faqs)


# ------------------------------------------------------------- articles
def toc(body: str) -> tuple[str, str]:
    """Gives every <h2> an id and returns (body, the time-rail contents list)."""
    items = []

    def repl(m: re.Match) -> str:
        text = strip_tags(m.group(2))
        ident = m.group(1) or re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")[:60]
        items.append((ident, text))
        return f'<h2 id="{ident}">{m.group(2)}</h2>'

    body = re.sub(r'<h2(?: id="([^"]+)")?>(.*?)</h2>', repl, body, flags=re.S)
    if len(items) < 3:
        return body, ""
    rows = "".join(f'<li><a href="#{i}"><span class="dot"></span>{esc(t)}</a></li>' for i, t in items)
    return body, f'<nav class="toc" aria-label="On this page"><p class="eyebrow">On this page</p><ol>{rows}</ol></nav>'


def related_cards(pages: list[Page]) -> str:
    cards = []
    for p in pages:
        cards.append(
            f'<a class="stub" href="{p.path}"><span class="stub-art">'
            f'{img_tag(p.art.replace("postcard:", "postcard-sm:") if p.art.startswith("postcard:") else p.art, "")}'
            f'</span><span class="stub-copy"><span class="eyebrow">{esc(p.section)}</span>'
            f'<span class="stub-title">{esc(p.h1)}</span></span></a>')
    return "".join(cards)


def render_article(p: Page, by_slug: dict[str, Page]) -> str:
    body, toc_html = toc(shortcodes(p.body, p))
    hub = ("/itineraries/", "Itineraries") if p.kind == "itinerary" else ("/guides/", "Guides")
    related = [by_slug[s] for s in p.related if s in by_slug][:4]
    art_key = p.art if p.art in IMAGES else "postcard:anywhere"
    if art_key.startswith("screen:"):
        hero_art = phone(art_key.split(":", 1)[1], p.art_alt or f"Travary: {p.crumb or p.h1}", "tilt-r hero-phone", eager=True)
    else:
        hero_art = img_tag(art_key, f"{p.crumb or p.h1}: Travary postcard art", "hero-card", eager=True,
                           srcset_key=art_key.replace("postcard:", "postcard-sm:") if art_key.startswith("postcard:") else None,
                           sizes="(max-width: 900px) 80vw, 460px")
    trail = [("Travary", "/"), (p.crumb or p.h1, "")] if p.kind == "app" else \
        [("Travary", "/"), (hub[1], hub[0]), (p.crumb or p.h1, "")]
    p.schema = [article_schema(p), crumbs_schema(trail)]
    if p.faqs:
        p.schema.append(faq_schema(p.faqs))
    p.schema.extend(getattr(p, "extra_schema", []))
    faq_block = f'<section class="faq-block" aria-labelledby="faq"><h2 id="faq">Questions people ask</h2><div class="faq">{faq_html(p.faqs)}</div></section>' if p.faqs else ""
    rel_block = f'<section class="related" aria-label="Keep planning"><h2>Keep planning</h2><div class="stubs">{related_cards(related)}</div></section>' if related else ""
    updated = human_date(p.updated)
    return f'''<article class="article">
<header class="article-hero">
  <div class="wrap article-hero-grid">
    <div class="article-hero-copy">
      <p class="crumbs"><a href="/">Travary</a><span>›</span>{"" if p.kind == "app" else f'<a href="{hub[0]}">{hub[1]}</a><span>›</span>'}{esc(p.crumb or p.h1)}</p>
      <p class="tag-label">{esc(SECTIONS.get(p.section, p.section))}</p>
      <h1>{p.h1}</h1>
      {store_badges("app_hero") if p.kind == "app" else ""}
      <p class="byline">By the Travary team <span>·</span> Updated <time datetime="{p.updated}">{updated}</time> <span>·</span> {p.minutes} min read</p>
    </div>
    <div class="article-hero-art">{hero_art}{img_tag("travi:" + p.travi, "Travi, the Travary suitcase", "hero-travi")}</div>
  </div>
</header>
<div class="wrap article-grid">
  <aside class="article-side">{toc_html}</aside>
  <div class="prose">
    <div class="answer"><p class="eyebrow">{"In short" if p.kind == "app" else "The short answer"}</p><p>{p.answer}</p></div>
    {body}
    {faq_block}
  </div>
</div>
{rel_block}
</article>
{cta_band()}'''


# Support and the policies: (slug, title, h1, meta, date, what the date is).
# Bodies in content/legal/<slug>.html; change the date when the text changes.
LEGAL = [
    ("support", "Travary Support: Help With the Holiday Organiser", "How can we help?",
     "Help with Travary: adding bookings, Smart Import, sharing a trip, travel documents, the Annual Pass and the Holiday Pass, and your account.",
     "2026-10-23", "Updated"),
    ("privacy", "Privacy Policy | Travary", "Privacy Policy",
     "How Travary handles your trips, bookings and account: what's stored, who processes it, and how to delete it. Passports never leave your phone.",
     "2026-10-23", "Effective"),
    ("terms", "Terms of Use | Travary", "Terms of Use",
     "The terms for using Travary, the holiday organiser app, including the Annual Pass and the Holiday Pass.",
     "2026-10-23", "Effective"),
    ("delete-account", "Delete Your Travary Account and Data", "Delete your Travary data",
     "How to delete your Travary account and data: in the app, as a guest, or by email, and what is deleted and kept.",
     "2026-10-23", "Updated"),
]


def legal_page(p: Page, body: str, dated: str = "Effective") -> str:
    """A policy page: its heading, the date it took effect, and the text with a contents rail."""
    body, toc_html = toc(body)
    p.schema = [crumbs_schema([("Travary", "/"), (p.h1, "")])]
    return f'''<article class="article legal">
<header class="article-hero">
  <div class="wrap">
    <div class="article-hero-copy">
      <p class="crumbs"><a href="/">Travary</a><span>›</span>{esc(p.h1)}</p>
      <h1>{esc(p.h1)}</h1>
      <p class="byline">{dated} <time datetime="{p.updated}">{human_date(p.updated)}</time> <span>·</span> Travary is made by {PUBLISHER}</p>
    </div>
  </div>
</header>
<div class="wrap article-grid">
  <aside class="article-side">{toc_html}</aside>
  <div class="prose">
    {body}
  </div>
</div>
</article>'''


def cta_band() -> str:
    return f'''<section class="cta-band" id="get-travary" aria-labelledby="cta-title">
  <div class="wrap cta-grid">
    <div class="cta-art">{film_tag("hello-idle", "hello", "Travi, the Travary suitcase, waving hello")}</div>
    <div class="cta-copy">
      <p class="eyebrow">Your holiday, sorted into days</p>
      <h2 id="cta-title">Add your bookings. Travary does the rest.</h2>
      <p>Flights, stays, tickets and tables go in once. Each morning opens on what you need right now, with tickets one tap away, even offline.</p>
      {store_badges("band")}
    </div>
  </div>
</section>'''


# ------------------------------------------------------------- the build
GUIDES: list[Page] = []
ITINERARIES: list[Page] = []
APP_PAGES: list[Page] = []   # content/apps: "itinerary app for …" landings and comparisons, at /<slug>


def load_content() -> None:
    GUIDES.extend(parse_content(f, "/guides/", "guide") for f in sorted((SITE / "content" / "guides").glob("*.html")))
    ITINERARIES.extend(parse_content(f, "/itineraries/", "itinerary")
                       for f in sorted((SITE / "content" / "itineraries").glob("*.html")))
    ITINERARIES.sort(key=lambda p: p.order)
    for p in ITINERARIES:
        p.section = "Itineraries"
    APP_PAGES.extend(parse_content(f, "/", "app") for f in sorted((SITE / "content" / "apps").glob("*.html")))
    APP_PAGES.sort(key=lambda p: p.order)


def render_template(name: str, page: Page, **values: str) -> str:
    text = (SITE / "templates" / name).read_text(encoding="utf-8")
    for k, v in values.items():
        text = text.replace("{{" + k + "}}", v)
    leftover = re.findall(r"\{\{\w+\}\}", text)
    if leftover:
        raise ValueError(f"{name}: unfilled {leftover}")
    return shortcodes(text, page)


def guide_cards(pages: list[Page], cls: str = "") -> str:
    out = []
    for p in pages:
        art = p.art.replace("postcard:", "postcard-sm:") if p.art.startswith("postcard:") else p.art
        out.append(f'''<a class="guide-card {cls} reveal" href="{p.path}">
  <span class="guide-card-art">{img_tag(art if art in IMAGES else "postcard-sm:anywhere", "")}</span>
  <span class="guide-card-copy"><span class="eyebrow">{esc(SECTIONS.get(p.section, p.section))}</span>
  <span class="guide-card-title">{esc(p.h1)}</span><span class="guide-card-meta">{esc(p.meta)}</span></span>
</a>''')
    return "\n".join(out)


def postcard_wall() -> str:
    def card(i: int, pack: str, name: str, copy: bool) -> str:
        hidden = ' tabindex="-1" aria-hidden="true"' if copy else ""
        return (f'<a class="wall-card" href="/holiday-countdown?p={pack}"{hidden} style="--tilt:{[-3, 2, -1, 3, -2, 1][i % 6]}deg">'
                f'{img_tag("postcard-sm:" + pack, "" if copy else f"Count down to {name} on its Travary postcard")}'
                f'<span class="wall-name">{esc(name)}</span></a>')
    items = list(PLACES.items())
    half = len(items) // 2
    def row(part: list) -> str:
        real = "".join(card(i, pack, name, False) for i, (pack, (name, _)) in part)
        copy = "".join(card(i, pack, name, True) for i, (pack, (name, _)) in part)
        return f'<div class="wall-track">{real}{copy}</div>'
    return (f'<div class="wall" aria-label="Postcards from the app: pick one to start a countdown">'
            f'{row(list(enumerate(items))[:half])}{row(list(enumerate(items))[half:])}</div>')


def home_faq_html(faqs: list[tuple[str, str, str]]) -> str:
    """Home FAQs: every answer ends with a link to the page that covers it
    (hub and spoke); the schema gets the answer alone."""
    return "\n".join(
        f'<details><summary>{esc(q)}</summary><div><p>{a} <a class="learn" href="{link}">Learn more →</a></p></div></details>'
        for q, a, link in faqs)


def made_for() -> str:
    cards = []
    for p in APP_PAGES:
        if not p.card:
            continue
        cards.append(f'''<a class="use-card reveal" href="{p.path}">
  {img_tag("icon:" + (p.icon or "calendar"), "", "icon")}
  <span class="use-title">{esc(p.crumb)}</span>
  <span class="use-copy">{esc(p.card)}</span>
  <span class="use-more">See how →</span>
</a>''')
    return "".join(cards)


def screens_rail() -> str:
    shots = [("today_orlando", "Today", "The day's plan on a time rail, the next ticket ready to show."),
             ("countdown", "Between trips", "A countdown on a postcard from where you're going next."),
             ("trips", "Trips", "Every trip on its own postcard, formed from your bookings."),
             ("today_lakes", "Day 2", "A boat trip next, and tonight's key card after it."),
             ("documents", "Documents", "Every ticket and booking in one place, offline.")]
    return "".join(
        f'<figure class="shot reveal">{phone(name, f"Travary {label} screen: {caption}")}'
        f'<figcaption><b>{esc(label)}</b>{esc(caption)}</figcaption></figure>'
        for name, label, caption in shots)


def hero_stages() -> str:
    picks = [("city_jp_kyoto", "Kyoto"), ("city_fr_paris", "Paris"), ("city_us_orlando", "Orlando"),
             ("city_au_sydney", "Sydney"), ("city_gb_london", "London"), ("city_pt_lisbon", "Lisbon"),
             ("city_us_new_york", "New York"), ("city_it_rome", "Rome")]
    data = [{"id": s, "name": n, "src": IMAGES[f"stage:{s}"].url} for s, n in picks]
    chips = "".join(f'<button type="button" class="chip{" is-on" if i == 0 else ""}" data-stage="{i}">{n}</button>'
                    for i, (_, n) in enumerate(picks))
    first = IMAGES[f"stage:{picks[0][0]}"]
    return f'''<div class="stage-window" data-stages='{esc(json.dumps(data))}'>
  <div class="stage-plate is-current" style="background-image:url({first.url})"></div>
  <div class="stage-floor" aria-hidden="true"></div>
  {film_tag("hello-idle", "hello", "Travi, the Travary suitcase, waving hello", "stage-travi", eager=True)}
  <span class="stage-place" aria-live="polite">{picks[0][1]}</span>
</div>
<div class="chips" role="group" aria-label="Pick a destination">{chips}</div>'''


def build_pages() -> list[Page]:
    by_slug = {p.path.rsplit("/", 1)[1]: p for p in GUIDES + ITINERARIES + APP_PAGES}
    pages: list[Page] = []

    # ------------------------------------------------------------ guides
    for p in GUIDES + ITINERARIES + APP_PAGES:
        pages.append(p)
        p.extra_schema = []  # type: ignore[attr-defined]
        main = render_article(p, by_slug)
        write(p, main)

    # -------------------------------------------------------------- hubs
    hub_faqs: list[tuple[str, str]] = []
    groups = ""
    for sec in ("Planning", "Flights", "Documents", "Apps"):
        items = sorted([g for g in GUIDES if g.section == sec], key=lambda g: g.order)
        if items:
            groups += f'<section class="hub-group"><h2>{esc(SECTIONS[sec])}</h2><div class="guide-grid">{guide_cards(items)}</div></section>'
    hub = Page(path="/guides/", title="Holiday Planning Guides | Travary",
               meta="Plain, practical guides to planning a holiday: itineraries, checklists, flight times, passports, boarding passes and the apps that keep it all together.",
               h1="Holiday planning guides", kind="hub", section="Guides", crumb="Guides", art="postcard:anywhere")
    hub.schema = [crumbs_schema([("Travary", "/"), ("Guides", "")]),
                  {"@context": "https://schema.org", "@type": "CollectionPage", "name": hub.h1, "url": hub.url,
                   "description": hub.meta, "isPartOf": {"@type": "WebSite", "name": "Travary", "url": DOMAIN + "/"}}]
    write(hub, f'''<header class="hub-hero"><div class="wrap">
  <p class="crumbs"><a href="/">Travary</a><span>›</span>Guides</p>
  <p class="tag-label">The planning desk</p><h1>Holiday planning guides</h1>
  <p class="lede">How to build an itinerary, what to sort before you go, how to read a flight time, which passport rules matter and which apps help. Written plainly, checked against official sources, and short enough to read on the train.</p>
</div>{img_tag("travi:folioOpen", "Travi holding an open travel folio", "hub-travi")}</header>
<div class="wrap hub">{groups}</div>{cta_band()}''')
    pages.append(hub)

    ihub = Page(path="/itineraries/", title="Holiday Itineraries, Day by Day | Travary",
                meta="Day-by-day holiday itineraries paced for real people: Orlando with kids, the Lake District, Paris with kids and two weeks in Japan.",
                h1="Itineraries, day by day", kind="hub", section="Itineraries", crumb="Itineraries",
                art="postcard:country_jp")
    ihub.schema = [crumbs_schema([("Travary", "/"), ("Itineraries", "")]),
                   {"@context": "https://schema.org", "@type": "CollectionPage", "name": ihub.h1, "url": ihub.url,
                    "description": ihub.meta}]
    write(ihub, f'''<header class="hub-hero"><div class="wrap">
  <p class="crumbs"><a href="/">Travary</a><span>›</span>Itineraries</p>
  <p class="tag-label">Sample holidays</p><h1>Itineraries, day by day</h1>
  <p class="lede">Each one is laid out the way Travary lays out a trip: a day at a time, with the timed things in order and room left to breathe. Use them as they are, or as a starting point for your own.</p>
</div>{img_tag("travi:present", "Travi presenting a holiday", "hub-travi")}</header>
<div class="wrap hub"><div class="guide-grid wide">{guide_cards(ITINERARIES, "is-trip")}</div></div>{cta_band()}''')
    pages.append(ihub)

    # -------------------------------------------------------------- tools
    for tpl, path, title, meta, h1, art, faqs_src, script in TOOLS:
        t = Page(path=path, title=title, meta=meta, h1=h1, kind="tool", section="Free tools", crumb=h1, art=art)
        t.scripts = [script]
        main, faqs = tool_page(tpl, t)
        t.schema = [crumbs_schema([("Travary", "/"), (h1, "")]),
                    {"@context": "https://schema.org", "@type": "WebApplication", "name": h1, "url": t.url,
                     "applicationCategory": "TravelApplication", "operatingSystem": "Any",
                     "description": meta, "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
                     "publisher": {"@type": "Organization", "name": "Travary", "url": DOMAIN + "/"}}]
        if faqs:
            t.schema.append(faq_schema(faqs))
        write(t, main)
        pages.append(t)

    # --------------------------------------------------------------- home
    home = Page(path="/", title="Travary: Itinerary App & Holiday Planner",
                meta="Travary is an itinerary app for iPhone and Android. Add your bookings and it sorts them into days, counts down to the trip and keeps tickets offline.",
                h1="Your holiday, sorted into days.", kind="home", section="Holiday organiser",
                art="screen:countdown")
    home.og = og_image("home", "Your holiday, sorted into days.", "countdown:city_jp_kyoto", "Travary · Holiday organiser")
    home_faqs = [(q, a) for q, a, _ in HOME_FAQS]
    featured = [by_slug[s] for s in ("how-to-make-a-travel-itinerary", "things-to-do-before-going-on-holiday",
                                     "are-flight-times-local", "passport-six-month-rule", "best-itinerary-apps",
                                     "family-holiday-checklist") if s in by_slug]
    main = render_template("home.html", home,
                           stages=hero_stages(), wall=postcard_wall(), guides=guide_cards(featured),
                           trips=guide_cards(ITINERARIES, "is-trip"), faq=home_faq_html(HOME_FAQS),
                           madefor=made_for(), screens=screens_rail(),
                           badges=store_badges("hero"), badges_end=store_badges("download"),
                           price_pass=PRICE_HOLIDAY_PASS, price_annual=PRICE_ANNUAL,
                           imports=str(FREE_IMPORTS))
    home.schema = [
        {"@context": "https://schema.org", **ORG},
        {"@context": "https://schema.org", "@type": "WebSite", "name": "Travary", "url": DOMAIN + "/",
         "publisher": {"@id": f"{DOMAIN}/#org"}},
        {"@context": "https://schema.org", "@type": "MobileApplication", "@id": f"{DOMAIN}/#app", "name": "Travary",
         "alternateName": "Itinerary App - Travary", "operatingSystem": "iOS, Android",
         "applicationCategory": "TravelApplication", "url": DOMAIN + "/",
         "description": home.meta, "image": f"{DOMAIN}/img/brand/icon-512.png",
         "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
         "publisher": {"@id": f"{DOMAIN}/#org"}},
        faq_schema(home_faqs),
    ]
    write(home, main)
    pages.append(home)

    # ------------------------------------------------------- early access
    if not STORE_LIVE:
        ea = Page(path="/early-access", title="Get Early Access to Travary",
                  meta="Join the Travary waiting list and get the download link the day the holiday organiser arrives on the App Store and Google Play.",
                  h1="Be first on board.", kind="early", noindex=True, art="postcard:anywhere")
        write(ea, f'''<section class="early">
  <div class="wrap early-grid">
    <div class="early-copy">
      <p class="tag-label">Early access</p>
      <h1>Be first on board.</h1>
      <p class="lede">Travary is nearly packed. Leave your email and we'll send you the download link the day it lands on the App Store and Google Play.</p>
      <div class="wl-card paper">
        <div class="wl-start">{waitlist_form("page", "/early-access")}</div>
        {waitlist_done()}
      </div>
      <div class="early-keep">
        <h2>What we keep, and why</h2>
        <ul>
          <li><strong>Your email,</strong> to tell you when Travary is out.</li>
          <li><strong>Your phone, if you pick one,</strong> so the email has the right store link.</li>
          <li><strong>The page you joined from,</strong> so we know which guides help.</li>
          <li><strong>A scrambled form of your IP address, for a day,</strong> to stop bulk sign-ups. It can't be turned back into the address.</li>
        </ul>
        <p>It's kept privately, never shared or sold, and deleted once we've emailed you that Travary is out, or sooner whenever you ask: email <a href="mailto:{SUPPORT_EMAIL}?subject=Remove%20me%20from%20the%20Travary%20waiting%20list">{SUPPORT_EMAIL}</a>. Travary's full <a href="{PRIVACY_URL}">privacy policy</a> covers the app.</p>
      </div>
    </div>
    <div class="early-art">
      <div class="stage-window early-stage" style="background:var(--sky)">
        <div class="stage-plate is-current" style="background-image:url({IMAGES["stage:city_jp_kyoto"].url})"></div>
        <div class="stage-floor" aria-hidden="true"></div>
        {film_tag("envelope", "envelope", "Travi, the Travary suitcase, holding an invitation", "stage-travi", eager=True)}
      </div>
    </div>
  </div>
</section>''')
        joined = Page(path="/early-access/joined", title="You're on the Travary Waiting List",
                      meta="Thanks for joining the Travary waiting list. We'll email you the day the app arrives on the App Store and Google Play.",
                      h1="You're on the list.", kind="early", noindex=True, art="postcard:anywhere")
        write(joined, f'''<section class="lost wrap">
  {img_tag("travi:cheer", "Travi cheering", "lost-travi")}
  <p class="eyebrow">Early access</p>
  <h1>You're on the list.</h1>
  <p>We'll email you the day Travary arrives on the App Store and Google Play. Until then:</p>
  <p class="lost-links"><a class="btn" href="/holiday-countdown">Start a countdown</a><a class="btn ghost" href="/guides/">Read the guides</a><a class="btn ghost" href="/">Home</a></p>
</section>''')

    # -------------------------------------------------------------- invites
    # travary.app/join/ABC234 (rewritten here by _redirects): what someone
    # sees when they open a family invite without the app. With the app, the
    # link opens it straight onto joining.
    join = Page(path="/join", title="You're Invited to a Trip on Travary",
                meta="Someone has invited you to their trip on Travary: the plan and your tickets on your phone.",
                h1="You're invited.", kind="early", noindex=True, art="postcard:anywhere")
    write(join, f'''<section class="early">
  <div class="wrap early-grid">
    <div class="early-copy">
      <p class="tag-label">Family invite</p>
      <h1>You're invited.</h1>
      <p class="lede">Someone's sharing their holiday with you on Travary: the plan, each day as it comes, and your tickets on your phone, even offline.</p>
      <div class="wl-card paper join-card">
        <p class="eyebrow">Your invite code</p>
        <p class="join-code" id="join-code" aria-live="polite">Open the link from your invite</p>
        <ol class="join-steps">
          <li><strong>Get Travary</strong> on your phone.</li>
          <li><strong>Open your invite link again,</strong> and Travary opens on the trip. Or, while setting up, tap
            <em>Joining someone's holiday? Enter their code</em>.</li>
        </ol>
        {store_badges("join")}
      </div>
    </div>
    <div class="early-art">
      <div class="stage-window early-stage" style="background:var(--sky)">
        <div class="stage-plate is-current" style="background-image:url({IMAGES["stage:city_jp_kyoto"].url})"></div>
        <div class="stage-floor" aria-hidden="true"></div>
        {film_tag("envelope", "envelope", "Travi, the Travary suitcase, holding an invitation", "stage-travi", eager=True)}
      </div>
    </div>
  </div>
</section>
<script>
(function () {{
  var m = location.pathname.match(/^\\/join\\/([A-Za-z0-9]{{6}})\\/?$/);
  if (!m) return;
  var code = m[1].toUpperCase();
  var el = document.getElementById("join-code");
  el.textContent = code.slice(0, 3) + " " + code.slice(3);
  el.classList.add("is-code");
}})();
</script>''')

    # ---------------------------------------------------------- auth emails
    # Travary's account emails (confirm your email, choose a new password,
    # sent by functions/src/accountEmails.ts) link here (docs/EMAIL_SIGN_IN.md).
    # The page finishes the link with Firebase's Identity Toolkit API
    # (static/js/auth.js); the app notices by itself.
    action = Page(path="/auth/action", title="Your Travary Account",
                  meta="Confirm your email or choose a new password for your Travary account, from the link in the email we sent you.",
                  h1="Your Travary account", kind="early", noindex=True, art="postcard:anywhere",
                  scripts=["auth.js"])
    write(action, f'''<section class="early">
  <div class="wrap early-grid">
    <div class="early-copy">
      <p class="tag-label">Your account</p>
      <h1 id="auth-title">One moment…</h1>
      <div class="wl-card paper auth-card" id="auth" data-key="{FIREBASE_WEB_API_KEY}" aria-live="polite">
        <p class="auth-text" id="auth-text">Checking your link.</p>
        <noscript><p class="auth-text">This page needs JavaScript to finish the link from your email. Turn it on, then open the link again.</p></noscript>
        <form class="wl-form auth-form" id="auth-form" hidden novalidate>
          <input type="email" name="username" id="auth-email" autocomplete="username" hidden readonly>
          <label class="wl-label" for="auth-password">New password</label>
          <input class="wl-email" type="password" id="auth-password" name="password" autocomplete="new-password"
                 minlength="8" required>
          <label class="auth-show"><input type="checkbox" id="auth-show"> Show password</label>
          <p class="wl-fine">At least 8 characters.</p>
          <p class="wl-error" id="auth-error" hidden></p>
          <button class="btn coral wl-submit" type="submit" id="auth-save">Save new password</button>
        </form>
        <p class="wl-fine auth-help">Something not right? Email <a href="mailto:dreamprayer.dev@gmail.com?subject=Travary%20account">dreamprayer.dev@gmail.com</a>.</p>
      </div>
    </div>
    <div class="early-art">
      <div class="stage-window early-stage" style="background:var(--sky)">
        <div class="stage-plate is-current" style="background-image:url({IMAGES["stage:city_jp_kyoto"].url})"></div>
        <div class="stage-floor" aria-hidden="true"></div>
        {film_tag("envelope", "envelope", "Travi, the Travary suitcase, holding an envelope", "stage-travi", eager=True)}
      </div>
    </div>
  </div>
</section>''')

    # --------------------------------------------------------------- legal
    for slug, title, h1, meta, date, dated in LEGAL:
        page = Page(path=f"/{slug}", title=title, h1=h1, meta=meta, kind="legal",
                    art="postcard:anywhere", updated=date)
        write(page, legal_page(page, (SITE / "content" / "legal" / f"{slug}.html").read_text(encoding="utf-8"), dated))
        pages.append(page)

    # ---------------------------------------------------------------- 404
    lost = Page(path="/404", title="Page not found | Travary", meta="This page has wandered off. Try the guides, the itineraries or the holiday countdown.",
                h1="This page has wandered off", kind="404", noindex=True, art="postcard:anywhere")
    (OUT / "404.html").write_text(layout(lost, f'''<section class="lost wrap">
  {img_tag("travi:oops", "Travi looking puzzled", "lost-travi")}
  <h1>This page has wandered off.</h1>
  <p>It may have moved, or the link had a typo. These are a good place to pick up the trail:</p>
  <p class="lost-links"><a class="btn" href="/">Home</a><a class="btn ghost" href="/guides/">Guides</a><a class="btn ghost" href="/itineraries/">Itineraries</a><a class="btn ghost" href="/holiday-countdown">Holiday countdown</a></p>
</section>'''), encoding="utf-8")
    return pages


TOOLS = [
    ("countdown.html", "/holiday-countdown", "Holiday Countdown: How Many Days Until Your Trip?",
     "Count down to your holiday on a postcard from your destination. Pick the date and the place, see the days to go, and share the link with everyone coming.",
     "Holiday countdown", "countdown:city_jp_kyoto", "countdown_faqs", "countdown.js"),
    ("template.html", "/itinerary-template", "Free Holiday Itinerary Template (Printable)",
     "A free, printable holiday itinerary template: fill in each day online, then print it or save it as a PDF. Flights, stays, tickets and times, in order.",
     "Holiday itinerary template", "ephemera:note_paper", "template_faqs", "template.js"),
]


def tool_page(tpl: str, page: Page) -> tuple[str, list[tuple[str, str]]]:
    text = (SITE / "templates" / tpl).read_text(encoding="utf-8")
    # A tool template may carry its FAQs after ---faq---, like a guide.
    main, _, faq = text.partition("\n---faq---\n")
    faqs, q = [], None
    for line in faq.strip().splitlines():
        if line.startswith("Q:"):
            q = line[2:].strip()
        elif line.startswith("A:") and q:
            faqs.append((q, line[2:].strip()))
            q = None
    places = [{"id": k, "name": v[0], "src": IMAGES[f"countdown:{k}"].url} for k, v in PLACES.items()]
    places.append({"id": "anywhere", "name": "Somewhere lovely", "src": IMAGES["countdown:anywhere"].url})
    main = main.replace("{{places}}", esc(json.dumps(places)))
    main = main.replace("{{faq}}", faq_html(faqs))
    main = main.replace("{{band}}", cta_band())
    main = main.replace("{{options}}", "".join(f'<option value="{k}">{esc(v[0])}</option>'
                                               for k, v in sorted(PLACES.items(), key=lambda kv: kv[1][0]))
                        + '<option value="anywhere">Somewhere lovely</option>')
    return shortcodes(main, page), faqs


HOME_FAQS = [  # (question, answer, the page that covers it)
    ("What is Travary?",
     "Travary is an itinerary app for iPhone and Android. You add your bookings (flights, stays, tickets, restaurant tables, hire cars, notes) and it sorts them into days, forms the trip from their dates, counts down to it, and opens each morning on what you need right now.",
     "/guides/how-travary-works"),
    ("Do I have to create a trip first?",
     "No. Add a booking and Travary forms the trip from its dates. If you'd rather start with a name and dates, you can, and Travary then keeps that trip's bookings to its days.",
     "/guides/how-to-organise-travel-bookings"),
    ("Does Travary work offline?",
     "Yes. Your bookings and tickets live on your phone, so the day's plan and your tickets open with no signal, which is usually when you need them.",
     "/offline-itinerary-app"),
    ("Is Travary on Android as well as iPhone?",
     "Yes. Travary is built for both, so a family or group with a mix of phones can share one trip, and everyone sees the same days.",
     "/itinerary-app-for-families"),
    ("Can my family or friends see the plan too?",
     f"Yes, with a Holiday Pass ({PRICE_HOLIDAY_PASS} for one holiday) or the Annual Pass ({PRICE_ANNUAL} a year). Share a trip with up to six people, you included; everyone sees the same days, adds what they booked and carries their own tickets.",
     "/shared-itinerary-app"),
    ("Is Travary free?",
     f"Yes. Trips, bookings, Today, the countdown, your tickets and travel documents are free and never locked. A Holiday Pass or the Annual Pass adds family sharing, ticket backup and unlimited Smart Import. Prices are in US dollars; your store shows your local price.",
     "/#passes"),
    ("Where are my passport details stored?",
     "Only on your phone, behind its own Face ID, fingerprint or passcode. Travel documents are never uploaded, never shared with the family and never sent to Smart Import.",
     "/travel-document-organizer-app"),
    ("How is Travary different from TripIt or Wanderlog?",
     "TripIt turns forwarded emails into an itinerary and Wanderlog plans a trip on a map. Travary is built for the holiday itself: each day in order, a Today screen for the morning of, tickets offline, and family sharing on iPhone and Android.",
     "/travary-vs-tripit"),
    ("When can I download Travary?",
     "Travary is coming soon to the App Store and Google Play. Join the waiting list and we'll email you the download link the day it's out.",
     "/early-access"),
]


def write(page: Page, main: str) -> None:
    page.file.parent.mkdir(parents=True, exist_ok=True)
    page.file.write_text(layout(page, main), encoding="utf-8")


def write_meta(pages: list[Page]) -> None:
    urls = sorted((p for p in pages if not p.noindex), key=lambda p: (p.path != "/", p.path))
    sm = ['<?xml version="1.0" encoding="UTF-8"?>',
          '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
    for p in urls:
        sm.append(f"  <url><loc>{p.url}</loc><lastmod>{p.updated}</lastmod></url>")
    sm.append("</urlset>")
    (OUT / "sitemap.xml").write_text("\n".join(sm) + "\n", encoding="utf-8")
    (OUT / "robots.txt").write_text(f"User-agent: *\nAllow: /\n\nSitemap: {DOMAIN}/sitemap.xml\n", encoding="utf-8")
    (OUT / "site.webmanifest").write_text(json.dumps({
        "name": "Travary", "short_name": "Travary", "start_url": "/", "display": "standalone",
        "background_color": "#F3ECDF", "theme_color": "#102B46",
        "icons": [{"src": "/img/brand/icon-192.png", "sizes": "192x192", "type": "image/png"},
                  {"src": "/img/brand/icon-512.png", "sizes": "512x512", "type": "image/png"}]}, indent=1))
    (OUT / "_headers").write_text("""/*
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  X-Frame-Options: SAMEORIGIN
/css/*
  Cache-Control: public, max-age=31536000, immutable
/js/*
  Cache-Control: public, max-age=31536000, immutable
/img/*
  Cache-Control: public, max-age=2592000
/.well-known/apple-app-site-association
  Content-Type: application/json
/auth/*
  Cache-Control: no-store
  Referrer-Policy: no-referrer
  X-Robots-Tag: noindex
""", encoding="utf-8")
    # Every invite link shows the one join page (its script reads the code).
    (OUT / "_redirects").write_text("/join/*  /join  200\n", encoding="utf-8")
    # The app's link association, so invite links open the app.
    well_known = OUT / ".well-known"
    well_known.mkdir(exist_ok=True)
    # webcredentials / get_login_creds: the phone's password manager keeps
    # Travary's email passwords under travary.app, and suggests strong ones.
    (well_known / "apple-app-site-association").write_text(json.dumps({
        "applinks": {"details": [{"appIDs": [APPLE_APP_ID],
                                  "components": [{"/": "/join/*", "comment": "Family invites"}]}]},
        "webcredentials": {"apps": [APPLE_APP_ID]},
    }, indent=1), encoding="utf-8")
    (well_known / "assetlinks.json").write_text(json.dumps([{
        "relation": ["delegate_permission/common.handle_all_urls", "delegate_permission/common.get_login_creds"],
        "target": {"namespace": "android_app", "package_name": ANDROID_PACKAGE,
                   "sha256_cert_fingerprints": ANDROID_CERT_SHA256},
    }], indent=1), encoding="utf-8")
    # A short map of the site for AI assistants (llmstxt.org).
    lines = ["# Travary", "",
             "> Travary is a holiday organiser app for iPhone and Android. Add your bookings and it sorts them "
             "into days, forms the trip from their dates, counts down to it, and opens each morning on what you "
             "need right now, with tickets one tap away, even offline. Travel documents stay on the phone.", "",
             "## Free tools", f"- [Holiday countdown]({DOMAIN}/holiday-countdown)",
             f"- [Printable itinerary template]({DOMAIN}/itinerary-template)", "", "## Guides"]
    lines += [f"- [{p.h1}]({p.url}): {p.meta}" for p in sorted(GUIDES, key=lambda p: (p.section, p.order))]
    lines += ["", "## Itineraries"] + [f"- [{p.h1}]({p.url}): {p.meta}" for p in ITINERARIES]
    lines += ["", "## The app, by use"] + [f"- [{p.h1}]({p.url}): {p.meta}" for p in APP_PAGES]
    (OUT / "llms.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    shutil.copytree(SITE / "static", OUT, dirs_exist_ok=True)
    build_assets()
    load_content()
    pages = build_pages()
    write_meta(pages)
    size = sum(f.stat().st_size for f in OUT.rglob("*") if f.is_file())
    print(f"built {len(pages)} pages ({len(GUIDES)} guides, {len(ITINERARIES)} itineraries) "
          f"into {OUT.relative_to(REPO)} — {size / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
