#!/bin/bash
PORT=5001
CAT=$(curl -s "http://localhost:${PORT}/v2/_catalog" 2>/dev/null)
if ! echo "$CAT" | grep -q '"myapp"'; then
  echo "❌ registry catalog has no 'myapp' repo — tag & push: docker tag myapp:2.0 localhost:${PORT}/myapp:2.0 && docker push localhost:${PORT}/myapp:2.0"; exit 1
fi
TAGS=$(curl -s "http://localhost:${PORT}/v2/myapp/tags/list" 2>/dev/null)
if ! echo "$TAGS" | grep -q '"2.0"'; then
  echo "❌ repo 'myapp' has no tag '2.0' (got: ${TAGS}). Push localhost:${PORT}/myapp:2.0"; exit 1
fi
echo "✅ myapp:2.0 pushed to the local registry (catalog + tag confirmed)"; exit 0
