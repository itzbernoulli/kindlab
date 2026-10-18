#!/bin/bash
J=$(kubectl get crd regions.stable.example.com -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ CRD regions.stable.example.com not found — create a Cluster-scoped CRD (kind Region, plural regions)"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
c=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
sp=c["spec"]; names=sp.get("names") or {}
if sp.get("group")!="stable.example.com": fail("spec.group must be stable.example.com (got %r)"%sp.get("group"))
if names.get("kind")!="Region": fail("spec.names.kind must be Region (got %r)"%names.get("kind"))
if sp.get("scope")!="Cluster": fail("spec.scope must be Cluster (got %r) — this step is about a cluster-scoped CRD"%sp.get("scope"))
v=next((x for x in (sp.get("versions") or []) if x.get("name")=="v1"), None)
if not v or not v.get("served") or not v.get("storage"): fail("version v1 must exist with served:true and storage:true")
props=((((v.get("schema") or {}).get("openAPIV3Schema") or {}).get("properties") or {}).get("spec") or {}).get("properties") or {}
if (props.get("zone") or {}).get("type")!="string": fail("schema spec.zone must be type string (got %r)"%(props.get("zone") or {}).get("type"))
est=next((cd.get("status") for cd in (c.get("status",{}).get("conditions") or []) if cd.get("type")=="Established"), None)
if est!="True": fail("CRD not Established yet (status=%r)"%est)
PY
rc=$?; [ $rc -ne 0 ] && exit $rc
# Region is cluster-scoped: no -n.
R=$(kubectl get region us-east -o json 2>/dev/null)
[ -z "$R" ] && { echo "❌ Region 'us-east' not found (cluster-scoped: create it with no namespace) — spec.zone must be iad"; exit 1; }
export R
python3 - <<'PY'
import os,json,sys
r=json.loads(os.environ['R'])
def fail(m): print("❌ "+m); sys.exit(1)
if r.get("apiVersion")!="stable.example.com/v1": fail("Region apiVersion must be stable.example.com/v1 (got %r)"%r.get("apiVersion"))
if (r.get("spec") or {}).get("zone")!="iad": fail("Region us-east spec.zone must be iad (got %r)"%(r.get("spec") or {}).get("zone"))
print("✅ Cluster-scoped CRD regions.stable.example.com Established; Region 'us-east' with zone=iad")
PY
