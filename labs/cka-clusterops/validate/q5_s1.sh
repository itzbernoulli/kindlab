#!/bin/bash
if docker exec "$CP" test -f /opt/snapshot.db 2>/dev/null; then echo "✅ /opt/snapshot.db exists on $CP"; exit 0; fi
echo "❌ no snapshot at /opt/snapshot.db on $CP"; exit 1
