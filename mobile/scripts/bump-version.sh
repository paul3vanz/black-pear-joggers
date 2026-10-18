#!/usr/bin/env bash
# Increase the build number (the Android "version code") in pubspec.yaml by one.
#
# Usage (from anywhere; Git Bash on Windows is fine):
#   mobile/scripts/bump-version.sh [--name 1.2.0]
#
#   --name X.Y.Z   Also change the visible version name (the build number still goes up by one).
#
# `version: 1.0.0+7` means name 1.0.0, build number 7. Google Play needs a HIGHER build
# number for every upload (even one that was rejected), and testers on Firebase App
# Distribution only get an update when it goes up. The build scripts call this for you.
# Prints the new version on the last line, e.g. `1.0.0+8`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

NEW_NAME=""
while [ $# -gt 0 ]; do
  case "$1" in
    --name)
      [ $# -ge 2 ] || { echo "error: --name needs a value, e.g. --name 1.2.0" >&2; exit 1; }
      NEW_NAME="$2"
      shift 2
      ;;
    -h|--help)
      sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      exit 1
      ;;
  esac
done

command -v node >/dev/null 2>&1 || { echo "error: node is not on PATH" >&2; exit 1; }

node -e '
  const fs = require("fs");
  const file = "pubspec.yaml";
  const text = fs.readFileSync(file, "utf8");
  const re = /^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$/m;
  const m = text.match(re);
  if (!m) { console.error("error: no `version: x.y.z+n` line found in pubspec.yaml"); process.exit(2); }
  const name = process.argv[1] || m[1];
  if (!/^\d+\.\d+\.\d+$/.test(name)) { console.error("error: --name must look like 1.2.3"); process.exit(3); }
  const next = `${name}+${Number(m[2]) + 1}`;
  fs.writeFileSync(file, text.replace(re, `version: ${next}`));
  console.log(next);
' "$NEW_NAME"
