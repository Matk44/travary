#!/bin/sh
# Prints the Dart defines for the iOS app's Flutter build. The Runner
# target's "Run Script" phase runs this and hands the result to
# xcode_backend.sh as DART_DEFINES.
#
# Xcode builds with the defines the last flutter command wrote into
# ios/Flutter/Generated.xcconfig. An Archive from Xcode after `flutter run`
# (or with no flutter build before it) has none: its app has no RevenueCat
# keys and refuses to start (see bootstrap). So a Release build adds what
# tool/build_release.sh would have passed and is missing: RevenueCat's iOS
# key and offering from config/revenuecat.local.json, and live flight
# lookup. Defines already there stay as they are (FLIGHT_LOOKUP=false
# tool/build_release.sh still leaves flight lookup out), and Debug and
# Profile builds are left alone. Without the keys file a Release build
# fails here, not on the phone (demo builds need no keys).
#
# DART_DEFINES is Flutter's encoding: each KEY=value in base64, joined by
# commas.
set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"
keys="$root/config/revenuecat.local.json"
defines="${DART_DEFINES:-}"

# xcode_backend.sh picks the build mode the same way.
mode="$(printf '%s' "${FLUTTER_BUILD_MODE:-${CONFIGURATION:-}}" | tr '[:upper:]' '[:lower:]')"
case "$mode" in
  *release*) ;;
  *) printf '%s' "$defines"; exit 0 ;;
esac

fail() { echo "error: $*" >&2; exit 1; }

# Prints the value of define $1; fails if it isn't set.
value_of() {
  old_ifs=$IFS
  IFS=,
  for entry in $defines; do
    decoded="$(printf '%s' "$entry" | base64 --decode 2>/dev/null)" || continue
    case "$decoded" in
      "$1="*) IFS=$old_ifs; printf '%s' "${decoded#*=}"; return 0 ;;
    esac
  done
  IFS=$old_ifs
  return 1
}

add() {
  defines="${defines:+$defines,}$(printf '%s' "$1" | base64 | tr -d '\n')"
}

# Prints the string value of $1 in the keys file.
from_keys() {
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$keys" | head -n 1
}

if ! value_of TRAVARY_REVENUECAT_IOS_KEY >/dev/null && [ "$(value_of TRAVARY_BACKEND || true)" != demo ]; then
  [ -f "$keys" ] || fail "config/revenuecat.local.json is missing: a Release build needs RevenueCat's public SDK keys, or the app refuses to start (see CLAUDE.md, Premium)."
  key="$(from_keys TRAVARY_REVENUECAT_IOS_KEY)"
  case "$key" in
    appl_*) add "TRAVARY_REVENUECAT_IOS_KEY=$key" ;;
    *) fail "config/revenuecat.local.json has no iOS key (appl_…)." ;;
  esac
  offering="$(from_keys TRAVARY_REVENUECAT_OFFERING)"
  if [ -n "$offering" ] && ! value_of TRAVARY_REVENUECAT_OFFERING >/dev/null; then
    add "TRAVARY_REVENUECAT_OFFERING=$offering"
  fi
fi
value_of TRAVARY_FLIGHT_LOOKUP >/dev/null || add TRAVARY_FLIGHT_LOOKUP=true

printf '%s' "$defines"
