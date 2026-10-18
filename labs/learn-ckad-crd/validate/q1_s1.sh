#!/bin/bash
if ! kubectl get crd widgets.stable.example.com >/dev/null 2>&1; then
  echo "❌ CRD widgets.stable.example.com not found — create a CustomResourceDefinition (group stable.example.com, kind Widget, plural widgets, scope Namespaced)"; exit 1
fi
GROUP=$(kubectl get crd widgets.stable.example.com -o jsonpath='{.spec.group}' 2>/dev/null)
KIND=$(kubectl get crd widgets.stable.example.com -o jsonpath='{.spec.names.kind}' 2>/dev/null)
SCOPE=$(kubectl get crd widgets.stable.example.com -o jsonpath='{.spec.scope}' 2>/dev/null)
EST=$(kubectl get crd widgets.stable.example.com -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' 2>/dev/null)
SIZE=$(kubectl get crd widgets.stable.example.com -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.size.type}' 2>/dev/null)
COLOR=$(kubectl get crd widgets.stable.example.com -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.color.type}' 2>/dev/null)
if [ "$GROUP" != "stable.example.com" ] || [ "$KIND" != "Widget" ]; then echo "❌ CRD group/kind wrong (got group='${GROUP}' kind='${KIND}', expected stable.example.com / Widget)"; exit 1; fi
if [ "$SCOPE" != "Namespaced" ]; then echo "❌ CRD scope must be Namespaced (got '${SCOPE}')"; exit 1; fi
if [ "$SIZE" != "integer" ] || [ "$COLOR" != "string" ]; then echo "❌ schema must define spec.size (integer) and spec.color (string) — got size='${SIZE}' color='${COLOR}'"; exit 1; fi
if [ "$EST" != "True" ]; then echo "❌ CRD exists but is not Established yet (status='${EST}') — wait for the API server to accept it"; exit 1; fi
echo "✅ CRD widgets.stable.example.com is Established (Widget, Namespaced, spec.size:integer spec.color:string)"; exit 0
