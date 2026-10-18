#!/bin/bash
NS=workloads-learn
SCHED=$(kubectl -n "$NS" get cronjob report -o jsonpath='{.spec.schedule}' 2>/dev/null)
POL=$(kubectl -n "$NS" get cronjob report -o jsonpath='{.spec.concurrencyPolicy}' 2>/dev/null)
if [ -z "$SCHED" ]; then
  if ! kubectl -n "$NS" get cronjob report >/dev/null 2>&1; then
    echo "❌ CronJob 'report' not found in $NS. Create it with schedule '*/5 * * * *' and concurrencyPolicy Forbid."; exit 1
  fi
fi
if [ "$SCHED" != "*/5 * * * *" ]; then
  echo "❌ CronJob 'report' schedule is '${SCHED:-unset}', expected '*/5 * * * *'."; exit 1
fi
if [ "$POL" != "Forbid" ]; then
  echo "❌ CronJob 'report' concurrencyPolicy is '${POL:-Allow}', expected 'Forbid'."; exit 1
fi
echo "✅ CronJob 'report' has schedule '*/5 * * * *' and concurrencyPolicy Forbid"; exit 0
