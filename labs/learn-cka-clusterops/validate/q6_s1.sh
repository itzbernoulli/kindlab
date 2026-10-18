#!/bin/bash
if ! kubectl get node "$CP" >/dev/null 2>&1; then echo "❌ node '$CP' not found."; exit 1; fi
U=$(kubectl get node "$CP" -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$U" != "true" ]; then echo "✅ control-plane $CP is schedulable again (uncordoned)"; exit 0; fi
echo "❌ control-plane '$CP' is still cordoned (unschedulable=true). Run: kubectl uncordon $CP"; exit 1
