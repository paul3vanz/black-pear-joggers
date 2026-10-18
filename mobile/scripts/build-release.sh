#!/usr/bin/env bash
# Bump the build number, then build the signed release files.
#
# Usage (from anywhere; Git Bash on Windows is fine):
#   mobile/scripts/build-release.sh [--aab-only | --apk-only] [--no-bump] [--name 1.2.0]
#
#   (default)     Bump the build number, build the Play app bundle AND the split APKs.
#   --aab-only    Only the app bundle (for Google Play).
#   --apk-only    Only the split APKs (for phones / Firebase App Distribution).
#   --no-bump     Build with the version already in pubspec.yaml.
#   --name X.Y.Z  Also change the visible version name when bumping.
#
# Output:
#   build/app/outputs/bundle/release/app-release.aab
#   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (and the other ABIs)
# Signing uses android/key.properties (see docs/store/release-checklist.md).
# Remember to commit the pubspec.yaml change so the next build continues from it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

BUMP=1
AAB=1
APK=1
NAME_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --aab-only) APK=0; shift ;;
    --apk-only) AAB=0; shift ;;
    --no-bump) BUMP=0; shift ;;
    --name)
      [ $# -ge 2 ] || { echo "error: --name needs a value, e.g. --name 1.2.0" >&2; exit 1; }
      NAME_ARGS=(--name "$2")
      shift 2
      ;;
    -h|--help)
      sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      exit 1
      ;;
  esac
done

[ -f config/prod.json ] || { echo "error: config/prod.json not found" >&2; exit 1; }
[ -f android/key.properties ] || echo "warning: android/key.properties missing: builds will be signed with the DEBUG key and Play will reject them" >&2

if [ "$BUMP" -eq 1 ]; then
  VERSION="$("$SCRIPT_DIR/bump-version.sh" "${NAME_ARGS[@]}")"
else
  VERSION="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml)"
fi
echo "Building version $VERSION"

if [ "$AAB" -eq 1 ]; then
  flutter build appbundle --release --dart-define-from-file=config/prod.json
fi
if [ "$APK" -eq 1 ]; then
  flutter build apk --release --split-per-abi --dart-define-from-file=config/prod.json
fi

echo
echo "Done: version $VERSION"
[ "$AAB" -eq 1 ] && echo "  Play bundle: build/app/outputs/bundle/release/app-release.aab"
[ "$APK" -eq 1 ] && echo "  Phone APK:   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
echo "Commit pubspec.yaml so the next build continues from this number."
