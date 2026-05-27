"""Local scoring CLI — compare your submission against ground truth.

Usage:
    python score_local.py --gt examples/tiny_gt.csv --submission /path/to/submission.csv
    python score_local.py --gt examples/tiny_gt.csv --submission /path/to/submission.csv --json score.json
"""
import argparse
import json
import sys

import pandas as pd

from kaggle_metric import score_detailed, ParticipantVisibleError


def main():
    ap = argparse.ArgumentParser(description="Score a submission locally")
    ap.add_argument("--gt", required=True, help="Ground truth CSV (image, regions)")
    ap.add_argument("--submission", required=True, help="Submission CSV (image, regions)")
    ap.add_argument("--json", help="Write detailed scores to JSON file")
    args = ap.parse_args()

    gt = pd.read_csv(args.gt)
    sub = pd.read_csv(args.submission)

    try:
        r = score_detailed(gt, sub, "image")
    except ParticipantVisibleError as e:
        print(f"\n  SUBMISSION REJECTED: {e}\n", file=sys.stderr)
        sys.exit(1)

    print()
    print("────────────────────────────────────────────────────────────")
    print(f"  Images evaluated         : {r['n_images']}")
    print(f"  Matched regions (IoU≥0.5): {r['n_matched_regions']}")
    print(f"  False positives          : {r['n_false_positives']}")
    print(f"  False negatives          : {r['n_false_negatives']}")
    print()
    print(f"  Detection F1             : {r['detection_f1']:.4f}   (P={r['detection_precision']:.3f} / R={r['detection_recall']:.3f})")
    print(f"  Classification accuracy  : {r['classification_accuracy']:.4f}")
    print(f"  Region CER               : {r['region_cer']:.4f}   →  score {1-r['region_cer']:.4f}")
    print(f"  Page CER                 : {r['page_cer']:.4f}   →  score {1-r['page_cer']:.4f}")
    print("────────────────────────────────────────────────────────────")
    print(f"  COMPOSITE                : {r['composite_score']:.4f}")
    print("────────────────────────────────────────────────────────────")
    print()

    if args.json:
        with open(args.json, "w") as f:
            json.dump(r, f, indent=2)
        print(f"  Saved to: {args.json}")


if __name__ == "__main__":
    main()
