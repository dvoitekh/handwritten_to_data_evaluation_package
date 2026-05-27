# Baseline submission Dockerfile — outputs an EMPTY submission for every image.
# Replace this with a real model (CUDA base + your inference code).
#
# Contract:
#   - Read images from  /data/input/*.jpg   (mounted read-only by judge)
#   - Write submission to /data/output/submission.csv
#   - Exit 0 on success, non-zero on failure.

FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        libjpeg62-turbo \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/solution

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY predict.py entrypoint.sh ./
RUN chmod +x entrypoint.sh

ENV PYTHONUNBUFFERED=1

ENTRYPOINT ["/opt/solution/entrypoint.sh"]
