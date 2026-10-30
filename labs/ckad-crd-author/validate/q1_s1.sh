#!/bin/bash
J=$(kubectl get crd widgets.stable.example.com -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ CRD widgets.stable.example.com not found — create it (group stable.example.com, kind Widget, plural widgets, Namespaced)"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
c=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
sp=c["spec"]; names=sp.get("names") or {}
if c["metadata"]["name"]!="widgets.stable.example.com": fail("metadata.name must be widgets.stable.example.com")
if sp.get("group")!="stable.example.com": fail("spec.group must be stable.example.com (got %r)"%sp.get("group"))
if names.get("kind")!="Widget": fail("spec.names.kind must be Widget (got %r)"%names.get("kind"))
if names.get("plural")!="widgets": fail("spec.names.plural must be widgets (got %r)"%names.get("plural"))
if sp.get("scope")!="Namespaced": fail("spec.scope must be Namespaced (got %r)"%sp.get("scope"))
v=next((x for x in (sp.get("versions") or []) if x.get("name")=="v1"), None)
if not v: fail("need a versions[] entry named v1")
if not v.get("served"): fail("version v1 must be served:true")
if not v.get("storage"): fail("version v1 must be storage:true")
props=((((v.get("schema") or {}).get("openAPIV3Schema") or {}).get("properties") or {}).get("spec") or {}).get("properties") or {}
if (props.get("size") or {}).get("type")!="integer": fail("schema spec.size must be type integer (got %r)"%(props.get("size") or {}).get("type"))
if (props.get("color") or {}).get("type")!="string": fail("schema spec.color must be type string (got %r)"%(props.get("color") or {}).get("type"))
est=next((cd.get("status") for cd in (c.get("status",{}).get("conditions") or []) if cd.get("type")=="Established"), None)
if est!="True": fail("CRD not Established yet (status=%r) — wait for the API server to accept it"%est)
print("✅ CRD widgets.stable.example.com: Namespaced, spec.size:integer + spec.color:string, Established")
PY
