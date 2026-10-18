#!/bin/bash
if docker exec "$CP" test -f /opt/snapshot.db 2>/dev/null; then echo "✅ /opt/snapshot.db exists on $CP"; exit 0; fi
echo "❌ no snapshot at /opt/snapshot.db on $CP. Save with 'etcdctl snapshot save', then copy it to /opt/snapshot.db."; exit 1
