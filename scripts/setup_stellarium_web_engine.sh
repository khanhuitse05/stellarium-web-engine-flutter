#!/usr/bin/env bash
# Build Stellarium Web Engine and copy wasm/js + sky data into Flutter assets.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SWE="${SWE_ROOT:-$ROOT/../stellarium-web-engine}"
EMSDK="${EMSDK_ROOT:-$ROOT/../emsdk}"
DEST="$ROOT/assets/sky_map/stellarium"
SKYDATA_SRC="$SWE/apps/test-skydata"

if [[ ! -d "$SWE" ]]; then
  echo "Clone stellarium-web-engine next to mlastro-flutter first:" >&2
  echo "  git clone https://github.com/Stellarium/stellarium-web-engine.git $SWE" >&2
  exit 1
fi

if [[ ! -d "$EMSDK" ]]; then
  echo "Clone emsdk next to mlastro-flutter first:" >&2
  echo "  git clone https://github.com/emscripten-core/emsdk.git $EMSDK" >&2
  exit 1
fi

# shellcheck disable=SC1091
source "$EMSDK/emsdk_env.sh"
export PATH="$(dirname "$EMSDK_PYTHON"):$PATH"

if ! ./emsdk list 2>/dev/null | grep -q '3.1.56.*INSTALLED'; then
  (cd "$EMSDK" && ./emsdk install 3.1.56)
fi
(cd "$EMSDK" && ./emsdk activate 3.1.56)
# shellcheck disable=SC1091
source "$EMSDK/emsdk_env.sh"
export PATH="$(dirname "$EMSDK_PYTHON"):$PATH"

"$EMSDK_PYTHON" -m pip install -q scons

echo "Building Stellarium Web Engine (release)..."
(cd "$SWE" && emscons scons -j8 mode=release werror=0)

mkdir -p "$DEST"
cp "$SWE/build/stellarium-web-engine.js" "$DEST/"
cp "$SWE/build/stellarium-web-engine.wasm" "$DEST/"

echo "Patching SWE JS for iOS WebView (WebGL2-first + init errors)..."
"$EMSDK_PYTHON" - "$DEST" << 'PY'
import sys
from pathlib import Path

p = Path(sys.argv[1]) / "stellarium-web-engine.js"
text = p.read_text()

replacements = [
    (
        "contextAttributes.antialias=true",
        "contextAttributes.antialias=false",
    ),
    (
        'Module["onRuntimeInitialized"]=function(){if(Module.canvasElement)',
        'Module["onRuntimeInitialized"]=function(){try{if(Module.canvasElement)',
    ),
    (
        "if(Module.onReady)Module.onReady(Module)};",
        'if(Module.onReady)Module.onReady(Module)}catch(e){if(typeof window.__mlastroSweInitFailed==="function")window.__mlastroSweInitFailed(e);throw e}};',
    ),
    (
        "contextAttributes.majorVersion=1;contextAttributes.minorVersion=0;var ctx=Module.GL.createContext(Module.canvas,contextAttributes);Module.GL.makeContextCurrent(ctx)",
        'var ctx=null;contextAttributes.majorVersion=2;contextAttributes.minorVersion=0;ctx=Module.GL.createContext(Module.canvas,contextAttributes);if(!ctx){contextAttributes.majorVersion=1;contextAttributes.minorVersion=0;ctx=Module.GL.createContext(Module.canvas,contextAttributes)}if(!ctx)throw new Error("WebGL context unavailable");Module.GL.makeContextCurrent(ctx)',
    ),
    (
        "Module._core_init(0,0,1);",
        'var _cw=Module.canvas?(Module.canvas.width||414):414;var _ch=Module.canvas?(Module.canvas.height||896):896;var _dpr=window.devicePixelRatio||1;Module._core_init(_cw,_ch,_dpr);',
    ),
    (
        'Module.core=Module.getModule("core");Module.observer=Module.core.observer;',
        'Module.core=Module.getModule("core");if(!Module.core)throw new Error("Stellarium core module missing after _core_init");try{Module.observer=Module.core.observer}catch(e){try{Module.observer=Module.getModule("core.observer")}catch(e2){Module.observer=null}}',
    ),
    (
        'function run(){if(runDependencies>0)',
        'Module._free=_free;Module._malloc=_malloc;function run(){if(runDependencies>0)',
    ),
    (
        'var mouseDown=false;var mouseButtons=0;var mousePos;var render=function',
        'var mouseDown=false;var mouseButtons=0;var mousePos;Module._mlastroResetPointer=function(){mouseDown=false;mouseButtons=0;if(typeof Module._core_on_mouse==="function"){for(var i=0;i<16;i++)Module._core_on_mouse(i,0,0,0,0)}};var render=function',
    ),
]

for old, new in replacements:
    if old not in text:
        raise SystemExit(f"Missing SWE patch pattern: {old[:80]}...")
    text = text.replace(old, new, 1)

p.write_text(text)
PY

echo "Packing sky data for Flutter assets..."
TMP_SKY="$(mktemp -d)"
# Avoid macOS xattrs / AppleDouble files — Dart tar decode fails on binary PAX xattrs.
rsync -a --delete \
  --exclude 'tle_satellite.jsonl.gz' \
  --exclude 'CometEls.txt' \
  --exclude 'mpcorb.dat' \
  --exclude '._*' \
  "$SKYDATA_SRC/" "$TMP_SKY/"
find "$TMP_SKY" -name '._*' -delete 2>/dev/null || true
COPYFILE_DISABLE=1 tar --disable-copyfile --no-xattrs --no-acls --no-fflags \
  -czf "$DEST/skydata.tar.gz" -C "$TMP_SKY" .
rm -rf "$TMP_SKY" "$DEST/skydata"

echo "Done. Assets installed under assets/sky_map/stellarium/"
ls -lh "$DEST/stellarium-web-engine.js" "$DEST/stellarium-web-engine.wasm" "$DEST/skydata.tar.gz"
du -sh "$DEST/skydata.tar.gz"
