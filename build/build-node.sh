#!/bin/sh
# Build the fully-static node for one arch and drop it in v/<arch>/node.
#
#   build/build-node.sh <amd64|arm64>
#
# Runs the Dockerfile.node build for the given platform and extracts the
# binary. V8 is a heavy compile (1-3h natively); on an arm64 host, `amd64`
# runs under QEMU emulation and takes far longer — prefer a native runner
# (see vendor.yml).

set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
V="$(dirname "$HERE")"
. "$HERE/versions.env"

PLAT="${1:?usage: build-node.sh <amd64|arm64>}"
case "$PLAT" in
	amd64)  ARCH=x86_64 ;;
	arm64)  ARCH=aarch64 ;;
	*) echo "error: arch must be amd64 or arm64, got '$PLAT'" >&2; exit 1 ;;
esac

OUT="$V/$ARCH"
mkdir -p "$OUT"

# Compile parallelism is memory-bound (~1GB per heavy V8 TU). Default low so
# the build fits a typical 8GB Docker VM without OOM; override COMPILE_JOBS
# upward on a high-RAM machine.
COMPILE_JOBS="${COMPILE_JOBS:-4}"

echo ">> building static node ${NODE_VERSION} for linux/${PLAT} (compile jobs: ${COMPILE_JOBS}) -> $OUT/node"
docker buildx build \
	--platform "linux/${PLAT}" \
	-f "$HERE/Dockerfile.node" \
	--build-arg "NODE_VERSION=${NODE_VERSION}" \
	--build-arg "ALPINE_TAG=${ALPINE_TAG}" \
	--build-arg "COMPILE_JOBS=${COMPILE_JOBS}" \
	--target export \
	--output "type=local,dest=${OUT}" \
	"$HERE"

chmod +x "$OUT/node"
echo ">> done: $(ls -la "$OUT/node")"
