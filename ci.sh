#!/usr/bin/env bash
# Gate entry — the handl-gates campaign (workflows/gate.yaml ->
# gates/handl.yaml) runs `bash ci.sh` when present; ci.sh delegates
# to scripts/hnl-gate.sh so the gate can also be run by hand.
set -euo pipefail

# Skeleton repos have the layout but no implementation yet — a skipped gate is
# honest; a failing one would just be noise.
if ! find src -name '*.hnl' 2>/dev/null | grep -q .; then
  echo "no .hnl sources under src/ yet - gate skipped"
  exit 0
fi

exec ./scripts/hnl-gate.sh "$@"
