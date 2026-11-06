#!/usr/bin/env bash
# Bump the build number, then build the signed App Store IPA for TestFlight.
#
# Usage (on a Mac, from anywhere):
#   mobile/scripts/build-ios.sh [--no-bump] [--name 1.2.0]
#
#   (default)     Bump the build number, then build the IPA.
#   --no-bump     Build with the version already in pubspec.yaml.
#   --name X.Y.Z  Also change the visible version name when bumping.
#
# Output:
#   build/ios/ipa/*.ipa  (upload it with the Transporter app, see README "Releasing")
# Signing is automatic: the Apple Distribution certificate must be in your login keychain
# and the Xcode project already has the team set.
# Remember to commit the pubspec.yaml change so the next build continues from it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

BUMP=1
NEW_NAME=""

while [ $# -gt 0 ]; do
  case "$1" in
    --no-bump) BUMP=0; shift ;;
    --name)
      [ $# -ge 2 ] || { echo "error: --name needs a value, e.g. --name 1.2.0" >&2; exit 1; }
      NEW_NAME="$2"
      shift 2
      ;;
    -h|--help)
      sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      exit 1
      ;;
  esac
done

[ "$(uname -s)" = "Darwin" ] || { echo "error: iOS builds need a Mac" >&2; exit 1; }
[ -f config/prod.json ] || { echo "error: config/prod.json not found" >&2; exit 1; }

VERSION="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml)"
if [ "$BUMP" -eq 1 ]; then
  # Same rule as bump-version.sh (`version: 1.0.0+7` -> `1.0.0+8`), in plain shell so
  # it works on a Mac without node.
  NAME="${VERSION%%+*}"
  BUILD="${VERSION##*+}"
  [[ "$BUILD" =~ ^[0-9]+$ ]] || { echo "error: can't read the build number from '$VERSION' in pubspec.yaml" >&2; exit 1; }
  [ -n "$NEW_NAME" ] && NAME="$NEW_NAME"
  VERSION="$NAME+$((BUILD + 1))"
  sed -i '' "s/^version:.*/version: $VERSION/" pubspec.yaml
fi
echo "Building version $VERSION"

flutter pub get
flutter build ipa --release --dart-define-from-file=config/prod.json

echo
echo "Done: version $VERSION"
echo "  IPA: $(ls build/ios/ipa/*.ipa)"
echo "Upload it with the Transporter app, then commit pubspec.yaml so the next build continues from this number."
