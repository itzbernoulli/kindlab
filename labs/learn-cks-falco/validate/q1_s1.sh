#!/bin/bash
# A Falco DaemonSet must exist in namespace 'falco' running the Falco image.
NS=falco
DS=$(kubectl -n "$NS" get daemonset -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.template.spec.containers[*].image}{"\n"}{end}' 2>/dev/null)
if [ -z "$DS" ]; then
  echo "❌ no DaemonSet in namespace '$NS'. Install Falco: helm install falco falcosecurity/falco -n falco --create-namespace --set driver.kind=modern-ebpf"; exit 1
fi
if echo "$DS" | grep -qi 'falco'; then
  NAME=$(echo "$DS" | grep -i falco | head -1 | awk '{print $1}')
  echo "✅ Falco DaemonSet '$NAME' exists in namespace '$NS' running the Falco image"; exit 0
fi
echo "❌ a DaemonSet exists in '$NS' but none runs a Falco image. Deploy the falcosecurity/falco chart"; exit 1
