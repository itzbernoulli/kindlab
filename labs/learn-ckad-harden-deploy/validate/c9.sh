#!/bin/bash
J=$(kubectl -n shop get deploy checkout -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Deployment 'checkout' not found in namespace shop"; exit 1; }
export J
python3 - <<'PY'
import os,json
d=json.loads(os.environ['J'])
sp=d["spec"]; ps=sp["template"]["spec"]; cs=ps.get("containers",[]) or [{}]; cont=cs[0]
p=cont.get("readinessProbe") or {}; h=p.get("httpGet") or {}
errs=[]
if h.get("path")!="/": errs.append("httpGet.path!=/")
if str(h.get("port"))!="80": errs.append("port!=80")
if p.get("initialDelaySeconds")!=5: errs.append("initialDelaySeconds!=5")
if p.get("periodSeconds")!=10: errs.append("periodSeconds!=10")
if errs: print("❌ readinessProbe: "+", ".join(errs)); raise SystemExit(1)
print("✅ readinessProbe httpGet / :80, delay 5s, period 10s")
PY
