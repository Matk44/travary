#!/usr/bin/env bash
# Builds the store uploads: an Android App Bundle for Google Play and an iOS
# archive (.ipa) for App Store Connect, with everything a release needs:
#
#   - RevenueCat's public SDK keys (config/revenuecat.local.json, git-ignored).
#     Without them the app would fall back to simulated purchases, so this
#     refuses to build (and the app refuses to start that way, see bootstrap).
#     An Archive from Xcode reads them too (tool/xcode_dart_defines.sh).
#   - Live flight lookup (the add-flight board and the flight page's status).
#     Needs the AeroDataBox plan on API.Market; FLIGHT_LOOKUP=false leaves it
#     out until then.
#   - The Play upload key (android/key.properties, git-ignored).
#
# Usage: tool/build_release.sh [android|ios|both]   (default both)
# Outputs: build/app/outputs/bundle/release/app-release.aab and build/ios/ipa/.
set -euo pipefail
cd "$(dirname "$0")/.."

target="${1:-both}"
keys=config/revenuecat.local.json
flight_lookup="${FLIGHT_LOOKUP:-true}"

fail() { echo "build_release: $*" >&2; exit 1; }

[[ -f "$keys" ]] || fail "$keys is missing: RevenueCat's public SDK keys (see CLAUDE.md, Premium)."
grep -q '"TRAVARY_REVENUECAT_IOS_KEY": *"appl_' "$keys" || fail "$keys has no iOS key (appl_…)."
grep -q '"TRAVARY_REVENUECAT_ANDROID_KEY": *"goog_' "$keys" || fail "$keys has no Android key (goog_…)."

# pubspec's +N and appBuildNumber must match (a test checks it too).
build_number="$(sed -n 's/^version: .*+\([0-9]*\)$/\1/p' pubspec.yaml)"
grep -q "const appBuildNumber = $build_number;" lib/app/build_info.dart \
  || fail "pubspec.yaml's build number ($build_number) isn't appBuildNumber in lib/app/build_info.dart."
echo "Building $(sed -n 's/^version: //p' pubspec.yaml) (flight lookup: $flight_lookup)"

defines=(--dart-define-from-file="$keys" --dart-define=TRAVARY_FLIGHT_LOOKUP="$flight_lookup")

if [[ "$target" == android || "$target" == both ]]; then
  [[ -f android/key.properties ]] || fail "android/key.properties is missing: Google Play rejects debug-signed bundles."
  flutter build appbundle --release "${defines[@]}"
fi

if [[ "$target" == ios || "$target" == both ]]; then
  LANG=en_US.UTF-8 flutter build ipa --release "${defines[@]}"
fi
