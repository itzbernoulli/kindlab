#!/bin/bash
if ! docker image inspect committed:1.0 >/dev/null 2>&1; then
  echo "❌ image 'committed:1.0' not found — snapshot the running container: docker commit appbox committed:1.0"; exit 1
fi
echo "✅ running container 'appbox' committed to image committed:1.0"; exit 0
