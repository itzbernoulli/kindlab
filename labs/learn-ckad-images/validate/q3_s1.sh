#!/bin/bash
F=/tmp/kindlab-img/myapp-2.0.tgz
if [ ! -f "$F" ]; then
  echo "❌ archive $F not found — save the image: docker save myapp:2.0 | gzip > $F"; exit 1
fi
# accept gzipped (.tgz, the intended form) or a plain tar; must be a docker-save archive
if tar -tzf "$F" >/dev/null 2>&1; then LIST=$(tar -tzf "$F" 2>/dev/null)
elif tar -tf "$F" >/dev/null 2>&1; then LIST=$(tar -tf "$F" 2>/dev/null)
else echo "❌ $F is not a valid tar archive — use: docker save myapp:2.0 | gzip > $F"; exit 1
fi
if ! echo "$LIST" | grep -q 'manifest.json'; then
  echo "❌ $F is not a docker image archive (no manifest.json). Re-run: docker save myapp:2.0 | gzip > $F"; exit 1
fi
echo "✅ myapp:2.0 saved to a valid image archive ($F)"; exit 0
