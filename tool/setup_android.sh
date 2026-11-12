#!/usr/bin/env bash
# Sets up the Android (Gradle) project for DocNest. Safe to run more than once.
#
#   1. If android/ is missing, `flutter create` writes the Gradle project, the
#      Gradle wrapper and the launcher files. Existing lib/ and test/ are kept.
#   2. Adds the CAMERA permission to AndroidManifest.xml if it is not there yet.
#
# Run from any folder:  bash tool/setup_android.sh
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -d android ]; then
  flutter create --platforms=android --org com.docnest --project-name docnest .
fi

manifest=android/app/src/main/AndroidManifest.xml

if ! grep -q 'android.permission.CAMERA' "$manifest"; then
  python3 - "$manifest" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
if "<application" not in text:
    sys.exit("AndroidManifest.xml has no <application> tag")

permission = '<uses-permission android:name="android.permission.CAMERA"/>'
text = re.sub(
    r"^(\s*)<application",
    lambda m: f"{m.group(1)}{permission}\n{m.group(1)}<application",
    text,
    count=1,
    flags=re.MULTILINE,
)
path.write_text(text, encoding="utf-8")
PY
  echo "Added CAMERA permission to $manifest"
fi

echo "Android project ready: android/"
