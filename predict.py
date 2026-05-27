"""Baseline predict.py — outputs EMPTY predictions for every image.

Replace the body of `predict_one_image()` with your model.
The rest (CLI args, CSV writer, exception handling) is ready to use.
"""
import argparse
import csv
import json
import sys
from pathlib import Path

from PIL import Image


def predict_one_image(image_path: str) -> list[dict]:
    """Return a list of detected regions for one image.

    Each region: {"bbox": [x1, y1, x2, y2], "type": "handwritten", "text": "..."}

    Valid types: handwritten, printed, formula, table, annotation, image, graph.
    For image/graph regions, text can be "".

    This baseline returns [] (no detections). Replace with your model.
    """
    # ── YOUR CODE HERE ──────────────────────────────────────────
    # img = Image.open(image_path)
    # regions = your_model.predict(img)
    # return [{"bbox": [x1, y1, x2, y2], "type": "handwritten", "text": "..."}]
    return []


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True, help="Directory with .jpg images")
    ap.add_argument("--output", required=True, help="Path to write submission.csv")
    args = ap.parse_args()

    input_dir = Path(args.input)
    images = sorted(input_dir.glob("*.jpg"))
    if not images:
        print(f"[predict] no .jpg files in {input_dir}", file=sys.stderr)
        sys.exit(1)

    print(f"[predict] processing {len(images)} image(s)")

    rows = []
    for i, img_path in enumerate(images, 1):
        try:
            regions = predict_one_image(str(img_path))
        except Exception as e:
            print(f"[predict] ERROR on {img_path.name}: {e}", file=sys.stderr)
            regions = []
        rows.append({"image": img_path.name, "regions": json.dumps(regions)})
        if i % 50 == 0 or i == len(images):
            print(f"[predict] {i}/{len(images)}")

    with open(args.output, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["image", "regions"])
        writer.writeheader()
        writer.writerows(rows)

    print(f"[predict] wrote {len(rows)} row(s) to {args.output}")


if __name__ == "__main__":
    main()
