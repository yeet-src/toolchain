#!/bin/sh
# Producer step: pull the native TypeScript compiler (tsgo, the Go port from
# @typescript/native-preview-<platform>) into v/<arch>/tsgo/ so CI can re-host
# it on our toolchain release. Unlike esbuild, tsgo is NOT a single file: the
# binary resolves its bundled standard library (lib.*.d.ts) relative to its own
# location and panics without it, so the whole lib/ dir travels with it. The
# consumer-facing integrity check is the published tarball's checksum (recorded
# in versions.env by CI, verified by build/fetch-toolchain.sh), so this upstream
# fetch — run in CI over TLS — isn't pinned. Keep TSGO_VERSION in sync with
# template/package.json if the template depends on it too.
#
#   build/fetch-tsgo.sh [amd64|arm64]   (default: both)

set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
V="$(dirname "$HERE")"
. "$HERE/versions.env"

fetch() {
	plat="$1"
	case "$plat" in
		amd64) arch=x86_64;  npmpkg=linux-x64   ;;
		arm64) arch=aarch64; npmpkg=linux-arm64 ;;
		*) echo "error: unknown arch '$plat'" >&2; exit 1 ;;
	esac
	url="https://registry.npmjs.org/@typescript/native-preview-${npmpkg}/-/native-preview-${npmpkg}-${TSGO_VERSION}.tgz"
	tmp="$(mktemp -d)"
	echo ">> fetching tsgo ${TSGO_VERSION} for ${plat}"
	curl -fSL -o "$tmp/tsgo.tgz" "$url"
	tar xzf "$tmp/tsgo.tgz" -C "$tmp"
	# package/lib holds the binary (tsgo) beside its standard-library
	# declarations (lib.*.d.ts); ship the whole dir so tsgo finds its libs.
	rm -rf "$V/$arch/tsgo"
	mkdir -p "$V/$arch/tsgo"
	cp -R "$tmp/package/lib/." "$V/$arch/tsgo/"
	chmod +x "$V/$arch/tsgo/tsgo"
	rm -rf "$tmp"
	echo ">> done: $V/$arch/tsgo ($(ls "$V/$arch/tsgo" | wc -l | tr -d ' ') files)"
}

if [ "$#" -eq 0 ]; then
	fetch amd64
	fetch arm64
else
	fetch "$1"
fi
