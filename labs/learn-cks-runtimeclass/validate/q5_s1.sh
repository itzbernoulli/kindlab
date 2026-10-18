#!/bin/bash
H=$(kubectl get runtimeclass kata -o jsonpath='{.handler}' 2>/dev/null)
G=$(kubectl get runtimeclass gvisor -o jsonpath='{.handler}' 2>/dev/null)
if [ "$H" = "kata" ] && [ "$G" = "runsc" ]; then
  echo "✅ both RuntimeClasses exist: gvisor (runsc) and kata (kata)"; exit 0
fi
if [ -z "$H" ]; then echo "❌ RuntimeClass 'kata' not found. Create it with handler: kata."; exit 1; fi
if [ "$H" != "kata" ]; then echo "❌ RuntimeClass 'kata' has handler '$H', expected 'kata'."; exit 1; fi
echo "❌ RuntimeClass 'gvisor' is missing/changed (handler '${G:-<empty>}') — keep gvisor from step 1."; exit 1
