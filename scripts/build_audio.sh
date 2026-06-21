#!/usr/bin/env bash
#
# build_audio.sh — generate Italian audio for the app with Piper, compressed to AAC.
#
# TTS = Piper (open-source, MIT) using the it_IT-paola-medium voice. Runs at
# BUILD TIME; Piper emits WAV, which is then compressed to AAC (.m4a, ~64 kbps
# mono) via ffmpeg — ~10x smaller — and bundled. No runtime TTS, no network,
# no per-user cost.
#
# Idempotent. Piper venv + voice model live under scripts/.piper/ (gitignored);
# only the small .m4a files in Absumo/Resources/audio/ are committed.
# Re-run after editing graded_it.json or minimal_pairs_it.json.
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIPER_DIR="$ROOT/scripts/.piper"
VENV="$PIPER_DIR/venv"
VOICE="$PIPER_DIR/it_IT-paola-medium.onnx"
JSON="$ROOT/Absumo/Resources/graded_it.json"
PAIRS="$ROOT/Absumo/Resources/minimal_pairs_it.json"
OUT="$ROOT/Absumo/Resources/audio"
TMP="$OUT/.tmp.wav"
mkdir -p "$PIPER_DIR" "$OUT"

command -v ffmpeg >/dev/null || { echo "ffmpeg not found (brew install ffmpeg)"; exit 1; }

# 1. Python venv with piper-tts.
if [ ! -x "$VENV/bin/piper" ]; then
  echo "Setting up piper-tts venv…"
  PY="$(command -v python3.12 || command -v python3)"
  "$PY" -m venv "$VENV"
  "$VENV/bin/pip" install -q --upgrade pip
  "$VENV/bin/pip" install -q piper-tts
fi

# 2. paola voice model.
if [ ! -f "$VOICE" ]; then
  echo "Downloading paola (it_IT, medium) voice…"
  B="https://huggingface.co/rhasspy/piper-voices/resolve/main/it/it_IT/paola/medium"
  curl -sL "$B/it_IT-paola-medium.onnx"      -o "$VOICE"
  curl -sL "$B/it_IT-paola-medium.onnx.json" -o "$VOICE.json"
fi

# Synthesize `text` to OUT/<name> (name includes .m4a): Piper → WAV → AAC.
synth() {
  local name="$1" text="$2"
  echo "$text" | "$VENV/bin/piper" -m "$VOICE" -f "$TMP" >/dev/null 2>&1
  ffmpeg -y -i "$TMP" -c:a aac -b:a 64k -ac 1 "$OUT/$name" >/dev/null 2>&1
  echo "  ✓ $name"
}

# 3. One clip per graded item.
"$VENV/bin/python" - "$JSON" <<'PY' | while IFS=$'\t' read -r name text; do
import json, sys
for item in json.load(open(sys.argv[1]))["items"]:
    print(item["id"] + ".m4a\t" + item["text"])
PY
  synth "$name" "$text"
done

# 4. One clip per minimal-pair word.
if [ -f "$PAIRS" ]; then
  "$VENV/bin/python" - "$PAIRS" <<'PY' | while IFS=$'\t' read -r name text; do
import json, sys
for pair in json.load(open(sys.argv[1]))["pairs"]:
    for side in ("a", "b"):
        print(pair[side]["file"] + "\t" + pair[side]["it"])
PY
    synth "$name" "$text"
  done
fi

rm -f "$TMP"
echo "Done. Audio in $OUT"
