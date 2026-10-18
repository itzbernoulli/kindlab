#!/bin/bash
if ! docker image inspect myapp:2.0 >/dev/null 2>&1; then
  echo "❌ image 'myapp:2.0' not found — build it with the label: docker build -t myapp:2.0 --label version=2 /tmp/kindlab-img"; exit 1
fi
V=$(docker image inspect myapp:2.0 --format '{{ index .Config.Labels "version" }}' 2>/dev/null)
if [ "$V" != "2" ]; then
  echo "❌ 'myapp:2.0' is missing label version=2 (got '${V:-none}'). Rebuild: docker build -t myapp:2.0 --label version=2 /tmp/kindlab-img"; exit 1
fi
echo "✅ image myapp:2.0 built with label version=2"; exit 0
