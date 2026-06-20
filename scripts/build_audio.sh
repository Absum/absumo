#!/usr/bin/env bash
#
# build_audio.sh — generate Italian audio for every graded item with Piper.
#
# TTS = Piper (open-source, MIT) using the it_IT-paola-medium voice. Runs at
# BUILD TIME on this machine; the resulting WAVs are bundled into the app, so
# there is no runtime TTS dependency, no network, and no per-user cost.
#
# Idempotent. The Piper venv + voice model live under scripts/.piper/ (gitignored);
# only the small generated audio files in Absumo/Resources/audio/ are committed.
# Re-run after editing graded_it.json.
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIPER_DIR="$ROOT/scripts/.piper"
VENV="$PIPER_DIR/venv"
VOICE="$PIPER_DIR/it_IT-paola-medium.onnx"
JSON="$ROOT/Absumo/Resources/graded_it.json"
OUT="$ROOT/Absumo/Resources/audio"
mkdir -p "$PIPER_DIR" "$OUT"

# 1. Python venv with piper-tts (system python may be too new for the wheels;
#    prefer python3.12 if available).
if [ ! -x "$VENV/bin/piper" ]; then
  echo "Setting up piper-tts venv…"
  PY="$(command -v python3.12 || command -v python3)"
  "$PY" -m venv "$VENV"
  "$VENV/bin/pip" install -q --upgrade pip
  "$VENV/bin/pip" install -q piper-tts
fi

# 2. paola voice model (downloaded once from the Piper voices repo).
if [ ! -f "$VOICE" ]; then
  echo "Downloading paola (it_IT, medium) voice…"
  B="https://huggingface.co/rhasspy/piper-voices/resolve/main/it/it_IT/paola/medium"
  curl -sL "$B/it_IT-paola-medium.onnx"      -o "$VOICE"
  curl -sL "$B/it_IT-paola-medium.onnx.json" -o "$VOICE.json"
fi

# 3. Synthesize one WAV per graded item.
"$VENV/bin/python" - "$JSON" <<'PY' | while IFS=$'\t' read -r id text; do
import json, sys
data = json.load(open(sys.argv[1]))
for item in data["items"]:
    print(item["id"] + "\t" + item["text"])
PY
  echo "$text" | "$VENV/bin/piper" -m "$VOICE" -f "$OUT/$id.wav" >/dev/null 2>&1
  echo "  ✓ $id.wav"
done

echo "Done. Audio in $OUT"
