#!/bin/bash
# Prepare the image-building lab: stage a build context, clear prior artifacts so the
# learner must rebuild, and (re)create an empty local registry on a free port.
# Port 5000 (AirPlay/ControlCenter) and 5050 clash on macOS, so we use 5001.
DIR=/tmp/kindlab-img
REG=kindlab-registry
PORT=5001

mkdir -p "$DIR"
cat > "$DIR/Dockerfile" <<'EOF'
FROM busybox:1.36
LABEL stage=base
COPY hello.txt /hello.txt
CMD ["sh","-c","cat /hello.txt && sleep 3600"]
EOF
printf 'hello from myapp\n' > "$DIR/hello.txt"

# Clean slate: drop prior images + archive so steps 1-3 are not trivially pre-satisfied.
rm -f "$DIR/myapp-2.0.tgz"
docker rmi -f myapp:1.0 myapp:2.0 "localhost:${PORT}/myapp:2.0" >/dev/null 2>&1 || true
docker rmi -f committed:1.0 >/dev/null 2>&1 || true
rm -f "$DIR/myapp-oci.tar"
# seed a running container for the commit step
docker rm -f appbox >/dev/null 2>&1 || true
docker run -d --name appbox busybox:1.36 sh -c 'sleep 3600' >/dev/null 2>&1 || true

# Fresh, empty registry (so step 5's catalog check is meaningful).
docker rm -f "$REG" >/dev/null 2>&1 || true
docker run -d --restart=always -p "127.0.0.1:${PORT}:5000" --name "$REG" registry:2 >/dev/null 2>&1 || true

# PREREQUISITE (severed-chain reseed): the distribute steps (save/export/load/push)
# all operate on myapp:2.0, which the learner built in an earlier exercise now
# living in ckad-images-build. Build it here so this lab stands alone.
docker build -t myapp:2.0 --label version=2 "$DIR" >/dev/null 2>&1 || true

# Namespace for the run step; remove any leftover pod from a prior attempt.
kubectl get ns images-learn >/dev/null 2>&1 || kubectl create namespace images-learn >/dev/null 2>&1
kubectl -n images-learn delete pod myapp --ignore-not-found >/dev/null 2>&1

echo "build context ready at $DIR; myapp:2.0 pre-built; empty registry at localhost:${PORT}; namespace images-learn ready"
