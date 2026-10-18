#!/bin/bash
J=$(kubectl -n pod-design get pod sidecar-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'sidecar-pod' not found in pod-design"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ps=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
cs={c["name"]:c for c in ps.get("containers",[])}
if set(cs)!={"writer","reader"}: fail("need exactly two containers 'writer' and 'reader' (got %s)"%sorted(cs))
def mnt(c): return next((m for m in (c.get("volumeMounts") or []) if m.get("mountPath")=="/data"), None)
mw,mr=mnt(cs["writer"]),mnt(cs["reader"])
if not mw or not mr: fail("both writer and reader must mount a volume at /data")
if mw["name"]!=mr["name"]: fail("writer and reader must share the SAME volume at /data")
v=next((x for x in (ps.get("volumes") or []) if x["name"]==mw["name"]), None)
if not v or "emptyDir" not in v: fail("/data must be backed by an emptyDir volume")
print("✅ sidecar-pod: writer + reader share one emptyDir at /data")
PY
