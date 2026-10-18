#!/bin/bash
NS=exam
CJ=beat
SCHED=$(kubectl -n $NS get cronjob $CJ -o jsonpath='{.spec.schedule}' 2>/dev/null)
if [ -z "$SCHED" ]; then echo "❌ CronJob '$CJ' not found in namespace $NS"; exit 1; fi
if [ "$SCHED" != "*/5 * * * *" ]; then echo "❌ schedule must be '*/5 * * * *' (got '$SCHED')"; exit 1; fi
IMG=$(kubectl -n $NS get cronjob $CJ -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ "$IMG" != "busybox:1.36" ]; then echo "❌ job container image must be busybox:1.36 (got '${IMG:-none}')"; exit 1; fi
echo "✅ CronJob 'beat' exists with schedule */5 * * * * and busybox:1.36"; exit 0
