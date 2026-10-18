#!/bin/bash
# Cordon the control-plane so the learner must actually uncordon it in step 6.
kubectl cordon "$CP" >/dev/null 2>&1
echo "control-plane $CP cordoned for maintenance — bring it back in step 6"
