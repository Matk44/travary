#!/bin/sh
# Runs every test that needs the Firebase emulators, each against a demo
# project (nothing real is touched, no credentials needed):
#   - the Firestore-backed classification store (functions)
#   - Firestore and Storage security rules
#   - art packs end to end: publish, download, verify, install, draw
set -e
cd "$(dirname "$0")/.."
npm --prefix functions run test:emulator
npm --prefix rules-tests test
firebase emulators:exec --project demo-travary --only auth,storage "flutter test test_emulator"
