# Handwritten to Data — Docker Submission Kit

Participant kit for the [Handwritten to Data](https://www.kaggle.com/competitions/handwritten-to-data) Kaggle competition — an AI challenge for recognizing Ukrainian handwritten documents.

This kit contains a working Dockerfile, an entrypoint script, a baseline `predict.py` (outputs empty submissions), a small test set, and a self-check script.

**Your task**: replace the logic in `predict.py` with your model and submit **one Docker image** for final evaluation on a held-out dataset.

---

## TL;DR — Build & Run

```bash
# 1. Build the image (from this directory)
docker build -t my-htr .

# 2. Run on your images
docker run --rm --gpus all --shm-size=8g \
    -v /path/to/images:/data/input:ro \
    -v /path/to/output:/data/output \
    my-htr

# 3. Result → /path/to/output/submission.csv
```

Quick end-to-end sanity check on 3 sample images:

```bash
./examples/self_check.sh           # CPU only
./examples/self_check.sh --gpu     # with GPU
```

---

## Repository Structure

```
.
├── Dockerfile              ← change base image and deps for your model
├── entrypoint.sh           ← container entrypoint — do NOT change I/O paths
├── predict.py              ← your code — replace predict_one_image()
├── requirements.txt        ← Python dependencies
├── .dockerignore
├── kaggle_metric.py        ← official metric (for local scoring)
├── score_local.py          ← python score_local.py --gt ... --submission ...
├── submit.sh               ← upload script (pre-signed URL from organizers)
└── examples/
    ├── tiny_images/        ← 3 real images from the public test set
    ├── tiny_gt.csv         ← ground truth for them
    └── self_check.sh       ← build + run + score in one call
```

---

## Contract (fixed — the judge will run exactly this)

| What | Path inside container | Who |
|---|---|---|
| Images | `/data/input/*.jpg` (read-only) | Mounted by the judge |
| Submission | `/data/output/submission.csv` | Written by your code |
| Logs | stdout / stderr | Captured by Docker |

**Run command** (no CMD arguments — your container knows what to do):

```bash
docker run --rm --gpus all --shm-size=8g \
    -v "$IMAGES_DIR:/data/input:ro" \
    -v "$OUTPUT_DIR:/data/output" \
    "$YOUR_IMAGE"
```

**Constraints**:
- **1× GPU — NVIDIA H100 80GB.**
- **8 GB** shared memory (`--shm-size=8g`).
- **Fully offline** — no network access during evaluation. All model weights, configs, and dependencies must be inside the image.

**Exit code**:
- `0` — success. `submission.csv` must be non-empty and contain a row for **every** image in `/data/input/`.
- Any other — failure, no score awarded.

---

## `submission.csv` Format

```csv
image,regions
09ba34df-2665-452c-9ef4-6998a5e7944c.jpg,"[{""bbox"":[1213,350,2052,530],""type"":""handwritten"",""text"":""Магія голосу.""}]"
2accc0fa-0368-4a59-9b16-ae107479c630.jpg,"[]"
```

- Columns: `image`, `regions` (in this exact order).
- `regions` — JSON string, a list of `{bbox, type, text}` (all three fields required).
- `bbox` — `[x1, y1, x2, y2]` in pixels of the **original** image.
- `type` — one of: `handwritten`, `printed`, `formula`, `table`, `annotation`, `image`, `graph`.
- `text` — transcription. Use `""` for `image`/`graph` regions.
- **Images with no predictions — use an empty list `[]`, but the row must be present.**

Full metric details (CER + Page CER + Detection F1 + Classification Accuracy) are in `kaggle_metric.py`.

---

## How to Adapt for Your Model

### 1. Choose a base image

For GPU models, replace the base image in `Dockerfile`:

```Dockerfile
# Option A: slim CUDA runtime — install torch yourself
FROM nvidia/cuda:12.4.0-runtime-ubuntu22.04

# Option B: PyTorch pre-installed
FROM pytorch/pytorch:2.4.0-cuda12.4-cudnn9-runtime

# Option C: vLLM-ready (includes torch + vLLM)
FROM vllm/vllm-openai:latest
```

### 2. Bake model weights into the image

Downloading at runtime is slow, fragile, and may fail during evaluation (no internet guaranteed). Include your weights in the image.

```Dockerfile
# Option A: download during build
ENV HF_HOME=/opt/hf_cache
RUN python -c "from huggingface_hub import snapshot_download; \
    snapshot_download('your-org/your-model', cache_dir='/opt/hf_cache')"

# Option B: copy from local directory
COPY ./my_weights /opt/solution/weights
```

**Important**: all model weights must be baked into the image. No external volumes will be mounted during evaluation — the only mounts are `/data/input` (images) and `/data/output` (your submission).

### 3. Implement inference

In `predict.py`, replace the body of `predict_one_image(image_path) -> list[dict]`. Each returned region must have:

```python
{"bbox": [x1, y1, x2, y2], "type": "handwritten", "text": "..."}
```

The rest of the script (CSV writer, progress logging, exception handling) is ready to use:
- Iterates all `.jpg` files from `--input`
- Catches per-image exceptions (one bad image won't crash the run)
- Writes `submission.csv` with correct CSV escaping for JSON in the `regions` column

### 4. Update `requirements.txt`

Add your Python dependencies (transformers, torch, vllm, peft, etc.).

### 5. Test locally

```bash
docker build -t my-htr .
./examples/self_check.sh --gpu
# Composite should increase from 0.0 (baseline) to something meaningful
```

---

## How to Submit

1. **Request an upload link** — email the organizers when you're ready. You'll receive a personal pre-signed URL (valid 48 hours).

2. **Save your Docker image**:
   ```bash
   docker save my-htr | gzip > my-htr.tar.gz
   ```

3. **Upload**:
   ```bash
   UPLOAD_URL="https://..." ./submit.sh my-htr.tar.gz
   ```

   Or with curl directly:
   ```bash
   curl -X PUT -H "Content-Type: application/gzip" -T my-htr.tar.gz "$UPLOAD_URL"
   ```

4. You can **re-upload** before the deadline — the latest upload wins.

If the URL expires, email the organizers for a new one.

---

## FAQ

**Can `predict.py` write to the input directory?**
No. During evaluation, `/data/input` is mounted read-only. Write temporary files to `/tmp` or `/data/output`.

**Can I read from `/data/input` multiple times?**
Yes. It's only read-only for writing.

**Can I use an external API (OpenAI, Gemini, etc.)?**
No. Evaluation is fully offline — no network access. Everything must be inside the image.

**Are seeds / determinism required?**
Not required, but recommended for reproducibility.

**Can I use an ensemble of multiple models?**
Yes, as long as you stay within the 4-hour time limit on 1× H100 GPU.

**What Python version should I use?**
Python 3.10+ is recommended. The base CUDA image ships with 3.10; you can install 3.11+ if needed.
