#!/bin/bash
SZ=$(docker exec "$CP" sh -c 'stat -c%s /opt/snapshot.db 2>/dev/null || echo 0')
if [ "${SZ:-0}" -gt 1024 ]; then echo "✅ snapshot is ${SZ} bytes (valid backup)"; exit 0; fi
echo "❌ snapshot missing or too small (${SZ:-0} bytes). Use: etcdctl snapshot save"; exit 1
