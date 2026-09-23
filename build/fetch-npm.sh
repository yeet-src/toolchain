#!/bin/sh
# Producer step: pull the npm registry tarball for the pinned npm and unpack it
# to v/npm/ (bin/npm-cli.js, lib/, node_modules/ with every dep bundled) so CI
# can publish it as one arch-independent npm.tar.gz on our toolchain release.
# npm is pure JS — nothing to build and nothing per-arch — and it is NOT baked
# into our node (Dockerfile.node passes --without-npm) so the two pin
# independently. The consumer-facing integrity check is the published
# tarball's checksum (versions.env, verified by build/fetch-toolchain.sh), so
# this upstream fetch — run in CI from the registry over TLS — isn't pinned.
#
#   build/fetch-npm.sh

set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
V="$(dirname "$HERE")"
. "$HERE/versions.env"

url="https://registry.npmjs.org/npm/-/npm-${NPM_VERSION}.tgz"
tmp="$(mktemp -d)"
echo ">> fetching npm ${NPM_VERSION}"
curl -fSL --retry 3 -o "$tmp/npm.tgz" "$url"
# Registry tarballs extract to a top-level package/ dir.
tar xzf "$tmp/npm.tgz" -C "$tmp"
[ -f "$tmp/package/bin/npm-cli.js" ] || { echo "error: bin/npm-cli.js missing from tarball" >&2; exit 1; }
rm -rf "$V/npm"
mv "$tmp/package" "$V/npm"
rm -rf "$tmp"
echo ">> done: $V/npm ($(du -sh "$V/npm" | cut -f1))"
