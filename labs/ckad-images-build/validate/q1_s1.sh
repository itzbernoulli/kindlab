#!/bin/bash
if ! docker image inspect myapp:1.0 >/dev/null 2>&1; then
  echo "❌ image 'myapp:1.0' not found — build it: docker build -t myapp:1.0 /tmp/kindlab-img"; exit 1
fi
STAGE=$(docker image inspect myapp:1.0 --format '{{ index .Config.Labels "stage" }}' 2>/dev/null)
if [ "$STAGE" != "base" ]; then
  echo "❌ 'myapp:1.0' exists but wasn't built from the provided Dockerfile (missing LABEL stage=base). Build from /tmp/kindlab-img"; exit 1
fi
echo "✅ image myapp:1.0 built from the provided Dockerfile (LABEL stage=base present)"; exit 0
