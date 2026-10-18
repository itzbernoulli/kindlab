#!/bin/bash
A=$(kubectl auth can-i get configmaps/app-config   --as=dev -n rbac-learn 2>/dev/null)
B=$(kubectl auth can-i get configmaps/other-config --as=dev -n rbac-learn 2>/dev/null)
if [ "$A" = "yes" ] && [ "$B" = "no" ]; then echo "✅ dev can get app-config but NOT other-config (least privilege)"; exit 0; fi
if [ "$A" != "yes" ]; then echo "❌ dev cannot get app-config yet (can-i='${A:-no}'). Grant get on configmaps with resourceNames=app-config."; exit 1; fi
echo "❌ dev can also get other-config (can-i='${B}') — too broad. Restrict with resourceNames: [app-config]."; exit 1
