#!/bin/bash
# Self-check: build the docker image, run it on tiny_images/, score against tiny_gt.csv.
#
# Run this from the project root:
#   ./examples/self_check.sh
#
# Pass --gpu to enable --gpus all (default: CPU). Pass --tag NAME to use a custom
# image tag (default: htr-submission:local).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

TAG="htr-submission:local"
GPU_ARG=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --gpu) GPU_ARG="--gpus all"; shift ;;
        --tag) TAG="$2"; shift 2 ;;
        *) echo "unknown arg: $1" >&2; exit 1 ;;
    esac
done

WORK_DIR="$(mktemp -d -t htr_selfcheck.XXXXXX)"

echo "═══════════════════════════════════════════════════════════════"
echo "  Self-check"
echo "  Build context : $ROOT"
echo "  Image tag     : $TAG"
echo "  GPU           : $([[ -n "$GPU_ARG" ]] && echo enabled || echo disabled)"
echo "  Work dir      : $WORK_DIR"
echo "═══════════════════════════════════════════════════════════════"

echo "[1/3] docker build"
docker build -t "$TAG" "$ROOT"

echo "[2/3] docker run (mount tiny_images → /data/input)"
mkdir -p "$WORK_DIR/output"
docker run --rm $GPU_ARG \
    -v "$HERE/tiny_images:/data/input:ro" \
    -v "$WORK_DIR/output:/data/output" \
    "$TAG"

echo "[3/3] scoring against tiny_gt.csv"
python3 "$ROOT/score_local.py" \
    --gt "$HERE/tiny_gt.csv" \
    --submission "$WORK_DIR/output/submission.csv"

echo "  artefacts kept in: $WORK_DIR"
echo "═══════════════════════════════════════════════════════════════"
