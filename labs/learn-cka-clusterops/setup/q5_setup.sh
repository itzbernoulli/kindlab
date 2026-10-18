#!/bin/bash
# Cordon the control-plane so the learner must actually uncordon it.
kubectl cordon "$CP" >/dev/null 2>&1
echo "control-plane $CP cordoned for maintenance (your task: bring it back)"
