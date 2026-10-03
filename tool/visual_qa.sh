#!/usr/bin/env bash
# Renders the canonical Today screen at the reference size and compares it
# with docs/reference/travary_today_reference.png, and renders Today between
# trips (the countdown) for docs/mockups/today-empty/02-hanging-luggage-tag.png,
# the Trips tab's coming trips for
# docs/mockups/trips-postcards-v2/02-hanging-tag-postcards.png, and the
# Documents tab's stamps for
# docs/mockups/documents-themed-v2/02-collectible-scenic-stamps.png (Orlando,
# the Lake District, and rows on light and dark backdrops).
# Outputs in build/visual_qa/.
#
# The render uses the app's real fonts: Source Serif 4 and Inter as
# google_fonts downloads them (copied from an iOS Simulator where the app
# has run), and Flutter's Material icons font. Nothing is downloaded here.
set -euo pipefail
cd "$(dirname "$0")/.."

fonts=build/visual_qa/fonts
mkdir -p "$fonts"
if ! ls "$fonts"/SourceSerif4* >/dev/null 2>&1; then
  sims="$HOME/Library/Developer/CoreSimulator/Devices"
  if [ -d "$sims" ]; then
    find "$sims" -path '*Application Support*' \( -name 'SourceSerif4_*.ttf' -o -name 'Inter_*.ttf' \) -print0 2>/dev/null |
      while IFS= read -r -d '' font; do cp -n "$font" "$fonts/" 2>/dev/null || true; done
  fi
fi
flutter_root="$(dirname "$(dirname "$(command -v flutter)")")"
icons="$(find "$flutter_root" -path '*material_fonts*' -name 'MaterialIcons-Regular.otf' 2>/dev/null | head -1 || true)"
[ -n "$icons" ] && cp -n "$icons" "$fonts/" 2>/dev/null || true
ls "$fonts" | sed 's/^/  font: /'

TRAVARY_VISUAL_QA=1 flutter test test/visual_qa/today_reference_test.dart test/visual_qa/countdown_hero_test.dart \
  test/visual_qa/trips_postcards_test.dart test/visual_qa/documents_stamps_test.dart
