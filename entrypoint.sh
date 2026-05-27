#!/bin/bash
# Container entrypoint. Validates mounts, runs predict.py.
set -euo pipefail

INPUT_DIR="/data/input"
OUTPUT_DIR="/data/output"
SUBMISSION="${OUTPUT_DIR}/submission.csv"

echo "[entrypoint] starting ($(date -u +%FT%TZ))"

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "[entrypoint] ERROR: $INPUT_DIR not mounted" >&2
    exit 2
fi
if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo "[entrypoint] ERROR: $OUTPUT_DIR not mounted" >&2
    exit 2
fi

n_images=$(find "$INPUT_DIR" -maxdepth 1 -type f -iname '*.jpg' | wc -l)
echo "[entrypoint] found ${n_images} jpg image(s) in ${INPUT_DIR}"
if [[ "$n_images" -eq 0 ]]; then
    echo "[entrypoint] ERROR: no .jpg files in ${INPUT_DIR}" >&2
    exit 3
fi

python /opt/solution/predict.py \
    --input "$INPUT_DIR" \
    --output "$SUBMISSION"

if [[ ! -s "$SUBMISSION" ]]; then
    echo "[entrypoint] ERROR: ${SUBMISSION} not written or empty" >&2
    exit 4
fi

n_rows=$(($(wc -l < "$SUBMISSION") - 1))
echo "[entrypoint] wrote ${n_rows} row(s) to ${SUBMISSION}"
echo "[entrypoint] done"
