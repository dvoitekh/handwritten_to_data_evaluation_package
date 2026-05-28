#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  Upload your Docker image to the hackathon S3 bucket.
#
#  Usage:
#    export AWS_ACCESS_KEY_ID="..."
#    export AWS_SECRET_ACCESS_KEY="..."
#    export AWS_SESSION_TOKEN="..."
#    S3_DEST="s3://bucket/team-name/submission.tar.gz" ./submit.sh my-htr.tar.gz
#
#  The credentials and S3_DEST come from the organizers after you fill
#  out the submission form. They are scoped to your team only and valid
#  for ~36 hours.
#
#  This script uses `aws s3 cp` which performs multipart upload
#  automatically (no size limit on individual files).
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage:"
    echo "  export AWS_ACCESS_KEY_ID=\"...\""
    echo "  export AWS_SECRET_ACCESS_KEY=\"...\""
    echo "  export AWS_SESSION_TOKEN=\"...\""
    echo "  S3_DEST=\"s3://bucket/team-X/submission.tar.gz\" $0 <image.tar.gz>"
    exit 1
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
    echo "ERROR: file not found: $FILE"
    exit 1
fi

if [[ -z "${S3_DEST:-}" ]]; then
    echo "ERROR: S3_DEST environment variable is not set."
    echo "It should look like: s3://htr-hackathon-submissions/team-YOURNAME/submission.tar.gz"
    echo "Get it from the upload email sent by the organizers."
    exit 1
fi

if [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" || -z "${AWS_SESSION_TOKEN:-}" ]]; then
    echo "ERROR: AWS credentials are not set."
    echo "Export AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN"
    echo "from the email sent by the organizers, then re-run."
    exit 1
fi

if ! command -v aws &>/dev/null; then
    echo "ERROR: aws CLI not installed."
    echo "Install with: pip install awscli   (or: brew install awscli)"
    exit 1
fi

SIZE_BYTES=$(stat -f%z "$FILE" 2>/dev/null || stat -c%s "$FILE" 2>/dev/null)
SIZE_GB=$(awk "BEGIN {printf \"%.2f\", $SIZE_BYTES / 1073741824}")

echo "═══════════════════════════════════════════════════════════════"
echo "  File : $FILE"
echo "  Size : ${SIZE_GB} GB"
echo "  Dest : $S3_DEST"
echo "═══════════════════════════════════════════════════════════════"
echo "Uploading (multipart)..."

if aws s3 cp "$FILE" "$S3_DEST"; then
    echo ""
    echo "SUCCESS — uploaded ${SIZE_GB} GB"
    echo "You can re-upload before the deadline (latest upload wins)."
else
    echo ""
    echo "UPLOAD FAILED"
    echo ""
    echo "Common causes:"
    echo "  ExpiredToken — credentials expired (request new ones from organizers)"
    echo "  AccessDenied — credentials don't match the S3_DEST (check both fields)"
    echo "  NetworkError — connection issue, retry"
    exit 1
fi
