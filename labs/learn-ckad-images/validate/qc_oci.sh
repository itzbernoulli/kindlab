#!/bin/bash
F=/tmp/kindlab-img/myapp-oci.tar
if [ ! -f "$F" ]; then
  echo "❌ $F not found — export OCI: docker buildx build --output type=oci,dest=$F /tmp/kindlab-img"; exit 1
fi
L=$(tar -tf "$F" 2>/dev/null)
echo "$L" | grep -qx 'oci-layout' || { echo "❌ $F is not an OCI layout (missing 'oci-layout'). docker save is Docker format, not OCI — use: docker buildx build --output type=oci,dest=$F /tmp/kindlab-img"; exit 1; }
echo "$L" | grep -qx 'index.json' || { echo "❌ $F missing 'index.json' (OCI layout marker)"; exit 1; }
echo "✅ myapp-oci.tar is a valid OCI image layout (oci-layout + index.json)"; exit 0
