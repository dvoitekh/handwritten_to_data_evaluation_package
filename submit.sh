#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  Upload your Docker image to the hackathon S3 bucket.
#
#  Usage:
#    UPLOAD_URL="https://..." ./submit.sh my-htr.tar.gz
#
#  The UPLOAD_URL is a pre-signed S3 PUT URL — you'll receive
#  it from the organizers after requesting a submission slot.
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: UPLOAD_URL=\"https://...\" $0 <image.tar.gz>"
    exit 1
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
    echo "ERROR: file not found: $FILE"
    exit 1
fi

if [[ -z "${UPLOAD_URL:-}" ]]; then
    echo "ERROR: UPLOAD_URL environment variable is not set."
    echo ""
    echo "Request your personal upload link from the organizers,"
    echo "then run:"
    echo "  UPLOAD_URL=\"https://...\" $0 $FILE"
    exit 1
fi

SIZE_BYTES=$(stat -f%z "$FILE" 2>/dev/null || stat -c%s "$FILE" 2>/dev/null)
SIZE_GB=$(awk "BEGIN {printf \"%.2f\", $SIZE_BYTES / 1073741824}")

echo "═══════════════════════════════════════════════════════════════"
echo "  File : $FILE"
echo "  Size : ${SIZE_GB} GB"
echo "═══════════════════════════════════════════════════════════════"

echo "Uploading..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT \
    -H "Content-Type: application/gzip" \
    -T "$FILE" \
    "$UPLOAD_URL")

echo ""
if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "204" ]]; then
    echo "SUCCESS — uploaded ${SIZE_GB} GB"
    echo "You can re-upload before the deadline (latest upload wins)."
else
    echo "UPLOAD FAILED — HTTP $HTTP_CODE"
    echo ""
    echo "Common causes:"
    echo "  403 — URL expired (request a new one from the organizers)"
    echo "  400 — wrong Content-Type or file format"
    echo "  413 — file too large"
    echo ""
    echo "If the issue persists, try uploading with aws CLI instead:"
    echo "  aws s3 cp $FILE s3://BUCKET/team-YOURTEAM/submission.tar.gz"
    echo "  (ask the organizers for the exact command)"
    exit 1
fi
