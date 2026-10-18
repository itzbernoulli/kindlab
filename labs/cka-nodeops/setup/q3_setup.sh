#!/bin/bash
# Cordon $W1 so it is unschedulable; the candidate uncordons it.
kubectl cordon "$W1" >/dev/null 2>&1
echo "node $W1 cordoned (unschedulable)"
