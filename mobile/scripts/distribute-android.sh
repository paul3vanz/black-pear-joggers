#!/usr/bin/env bash
# Build the arm64 release APK and send it to testers with Firebase App Distribution.
#
# Usage (from anywhere; run it with Git Bash on Windows):
#   mobile/scripts/distribute-android.sh [--no-build] [--no-bump] [--group NAME] [--notes "text"]
#
# Options:
#   --no-build      Skip `flutter build`; upload the APK that is already built.
#   --no-bump       Build without increasing the build number first (it is bumped by default).
#   --group NAME    Tester group alias in Firebase (default: $GROUP, else "testers").
#   --notes "text"  Release notes (default: $NOTES, else "<version> <git short sha>").
#   -h, --help      Show this help.
#
# Needs: flutter, node (reads config/prod.json), firebase CLI (npm install -g firebase-tools)
# and a one-off `firebase login`. The app id comes from FIREBASE_ANDROID_APP_ID in
# config/prod.json. Only that app id is ever printed; no other config value is.
#
# Firebase App Distribution is for beta testing only. Play Store releases use the
# app bundle, see mobile/docs/store/release-checklist.md.

set -euo pipefail

usage() {
  sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

die() {
  echo "error: $*" >&2
  exit 1
}

# Work from the Flutter project root (mobile/), wherever the script is called from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

CONFIG="config/prod.json"
APK="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
BUILD=1
BUMP=1
GROUP_NAME="${GROUP:-testers}"
RELEASE_NOTES="${NOTES:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --no-build)
      BUILD=0
      shift
      ;;
    --no-bump)
      BUMP=0
      shift
      ;;
    --group)
      [ $# -ge 2 ] || die "--group needs a value, e.g. --group testers"
      GROUP_NAME="$2"
      shift 2
      ;;
    --notes)
      [ $# -ge 2 ] || die "--notes needs a value, e.g. --notes \"Fixes the chat\""
      RELEASE_NOTES="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "unknown option: $1"
      ;;
  esac
done

[ -f "$CONFIG" ] || die "$CONFIG not found (run from the mobile/ project; the file holds the public app ids)"

command -v node >/dev/null 2>&1 || die "node is not on PATH (needed to read $CONFIG)"

# Read FIREBASE_ANDROID_APP_ID from the config. The file path is passed as an argument,
# so nothing from the file is ever put on a command line or echoed except the app id.
APP_ID="$(node -e '
  const fs = require("fs");
  let cfg;
  try { cfg = JSON.parse(fs.readFileSync(process.argv[1], "utf8")); }
  catch (e) { console.error("cannot read " + process.argv[1] + ": " + e.message); process.exit(2); }
  const id = cfg.FIREBASE_ANDROID_APP_ID;
  if (typeof id !== "string" || id.trim() === "") { process.exit(3); }
  process.stdout.write(id.trim());
' "$CONFIG")" || die "FIREBASE_ANDROID_APP_ID is missing or empty in $CONFIG"
APP_ID="${APP_ID//$'\r'/}"

# A Firebase Android app id looks like 1:123456789012:android:0123456789abcdef.
case "$APP_ID" in
  [0-9]*:[0-9]*:android:*) ;;
  *) die "FIREBASE_ANDROID_APP_ID in $CONFIG does not look like 1:<number>:android:<hex>" ;;
esac

if ! command -v firebase >/dev/null 2>&1; then
  cat >&2 <<'EOF'
error: the Firebase CLI is not on PATH.

Install it once, then sign in once:
  npm install -g firebase-tools
  firebase login

Then run this script again.
EOF
  exit 1
fi

if [ "$BUILD" -eq 1 ]; then
  command -v flutter >/dev/null 2>&1 || die "flutter is not on PATH"
  if [ "$BUMP" -eq 1 ]; then
    echo "Bumping the build number: $("$SCRIPT_DIR/bump-version.sh")"
  fi
  echo "Building the arm64 release APK (config: $CONFIG)..."
  flutter build apk --release --split-per-abi --target-platform android-arm64 \
    --dart-define-from-file="$CONFIG"
else
  echo "Skipping the build (--no-build)."
fi

[ -f "$APK" ] || die "APK not found at $APK. Run without --no-build first."

if [ -z "$RELEASE_NOTES" ]; then
  VERSION="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n 1 | tr -d '\r')"
  SHA="$(git rev-parse --short HEAD 2>/dev/null || true)"
  RELEASE_NOTES="Build ${VERSION:-unknown}${SHA:+ ($SHA)}"
fi

echo "Uploading $APK"
echo "  app id:  $APP_ID"
echo "  group:   $GROUP_NAME"
echo "  notes:   $RELEASE_NOTES"

firebase appdistribution:distribute "$APK" \
  --app "$APP_ID" \
  --groups "$GROUP_NAME" \
  --release-notes "$RELEASE_NOTES"

echo "Done. Testers in the '$GROUP_NAME' group get an email about this build."
