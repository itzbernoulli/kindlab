#!/bin/bash
NS=workloads-learn
COMP=$(kubectl -n "$NS" get job pi -o jsonpath='{.spec.completions}' 2>/dev/null)
PAR=$(kubectl -n "$NS" get job pi -o jsonpath='{.spec.parallelism}' 2>/dev/null)
if [ -z "$COMP" ] && [ -z "$PAR" ]; then
  if ! kubectl -n "$NS" get job pi >/dev/null 2>&1; then
    echo "❌ Job 'pi' not found in $NS. Create it with completions=6 and parallelism=2."; exit 1
  fi
fi
if [ "$COMP" != "6" ]; then
  echo "❌ Job 'pi' completions is '${COMP:-unset}', expected 6."; exit 1
fi
if [ "$PAR" != "2" ]; then
  echo "❌ Job 'pi' parallelism is '${PAR:-unset}', expected 2."; exit 1
fi
echo "✅ Job 'pi' has completions=6 and parallelism=2"; exit 0
