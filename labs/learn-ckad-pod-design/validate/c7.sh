#!/bin/bash
J=$(kubectl -n pod-design get pod qos-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'qos-pod' not found in pod-design"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
q=json.loads(os.environ['J']).get("status",{}).get("qosClass")
if q!="Guaranteed": print("❌ qos-pod QoS class is %r, expected 'Guaranteed' (set requests == limits for cpu AND memory)"%q); sys.exit(1)
print("✅ qos-pod status.qosClass == Guaranteed")
PY
