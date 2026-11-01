#!/bin/bash
# CRD widgets.example.com: group example.com, Namespaced, version v1 served, Established=True.
J=$(kubectl get crd widgets.example.com -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ CRD 'widgets.example.com' not found — apply the CustomResourceDefinition"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
d=json.loads(os.environ["J"]); sp=d["spec"]
if sp.get("group")!="example.com": fail("group must be example.com (got %r)"%sp.get("group"))
if sp.get("scope")!="Namespaced": fail("scope must be Namespaced (got %r)"%sp.get("scope"))
if sp.get("names",{}).get("kind")!="Widget": fail("names.kind must be Widget")
vs=[v for v in sp.get("versions",[]) if v.get("name")=="v1" and v.get("served")]
if not vs: fail("a served version 'v1' is required")
conds={c["type"]:c["status"] for c in d.get("status",{}).get("conditions",[])}
if conds.get("Established")!="True": fail("CRD not Established yet (conditions=%r) — give it a moment"%conds)
print("✅ CRD widgets.example.com Established (Namespaced, group example.com, v1)")
PY
