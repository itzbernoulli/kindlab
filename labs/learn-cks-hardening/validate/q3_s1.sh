#!/bin/bash
# Verify kubelet on $W2 is locked down: authentication.anonymous.enabled: false
# AND authorization.mode: Webhook, parsed from the live config file; then node Ready.
C=/var/lib/kubelet/config.yaml
CFG=$(docker exec "$W2" cat "$C" 2>/dev/null)
[ -z "$CFG" ] && { echo "❌ cannot read $C on $W2"; exit 1; }
export CFG
RES=$(python3 - <<'PY'
import os,sys,yaml
try:
    d=yaml.safe_load(os.environ['CFG']) or {}
except Exception:
    # Fallback: crude parse if PyYAML missing (kind nodes usually have it on the host runner).
    print("PARSE_ERR"); sys.exit(0)
anon=(((d.get("authentication") or {}).get("anonymous") or {}).get("enabled"))
mode=((d.get("authorization") or {}).get("mode"))
if anon is not False:
    print("ANON %r"%anon); sys.exit(0)
if mode!="Webhook":
    print("MODE %r"%mode); sys.exit(0)
print("OK")
PY
)
case "$RES" in
  OK) : ;;
  PARSE_ERR)
    # Fallback to block-aware grep if PyYAML is unavailable on the runner.
    ANON=$(echo "$CFG" | awk '/^authentication:/{a=1} a&&/anonymous:/{b=1} b&&/enabled:/{print $2; exit}')
    MODE=$(echo "$CFG" | awk '/^authorization:/{z=1} z&&/mode:/{print $2; exit}')
    [ "$ANON" = "false" ] || { echo "❌ authentication.anonymous.enabled is '${ANON:-unset}' on $W2 (want false)"; exit 1; }
    [ "$MODE" = "Webhook" ] || { echo "❌ authorization.mode is '${MODE:-unset}' on $W2 (want Webhook)"; exit 1; }
    ;;
  ANON*) echo "❌ authentication.anonymous.enabled is ${RES#ANON } on $W2 (want false)"; exit 1 ;;
  MODE*) echo "❌ authorization.mode is ${RES#MODE } on $W2 (want Webhook)"; exit 1 ;;
  *) echo "❌ unexpected validation error on $W2: $RES"; exit 1 ;;
esac
# The change requires a kubelet restart; confirm the node came back Ready.
for i in $(seq 1 12); do
  ST=$(kubectl get node "$W2" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  [ "$ST" = "True" ] && { echo "✅ kubelet on $W2: anonymous auth false + authorization mode Webhook, node Ready"; exit 0; }
  sleep 5
done
echo "❌ kubelet hardened but node $W2 not Ready (Ready='${ST:-unknown}'). Check: docker exec $W2 systemctl status kubelet"; exit 1
