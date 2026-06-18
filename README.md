# toolchain

Static, version-pinned build tools for yeet scripts, so a project's `make`
runs with **no system C/BPF toolchain** installed. This repo *produces and
publishes* the toolchain; consumers (e.g. `script-template`) fetch it on demand
into a shared per-machine cache.

## What it ships

Each tool is a fully-static binary (no shared-library deps), built or fetched
per arch (`x86_64`, `aarch64`) and published as a version-addressed asset on
the rolling **`toolchain`** release.

| tool      | for                                                | source |
|-----------|----------------------------------------------------|--------|
| `clang`   | compile `*.bpf.c` (`-target bpf`)                  | built from LLVM source, musl-static |
| `make`    | drive the build                                    | built from GNU make source, musl-static |
| `git`     | `git init` a generated project                     | built from git source, musl-static, lean (no https) |
| `bpftool` | `vmlinux.h` (BTF dump) + link BPF objects          | official static release, re-hosted |
| `esbuild` | bundle the JS entry                                | official static (Go) binary, re-hosted |
| `bpf/*.h` | libbpf program headers (`<bpf/bpf_helpers.h>`, …)  | libbpf bundled with bpftool |

```
build/      reproducible recipe — Dockerfile.{clang,make,git}, build-*.sh,
            fetch-*.sh, versions.env (pins + checksums)
include/    arch-independent libbpf SDK headers (source for the headers tarball)
embed/      the glue a template carries: toolchain.mk + fetch-toolchain.sh
.github/    vendor.yml — builds on native runners and publishes the release
```

Built binaries (`x86_64/`, `aarch64/`) are **not committed** — they're the
release assets. Only the recipe, headers, and embed glue are tracked.

## Consuming it

A template carries the [`embed/`](embed/) glue plus a `toolchain.lock`
(a copy of [`build/versions.env`](build/versions.env): pins + checksums +
`TOOLCHAIN_BASE_URL`). The project's `build/toolchain.mk` resolves each tool
from the cache, and `build/fetch-toolchain.sh` downloads any missing one (once)
from this repo's release, checksum-verified. Pull updates with
`git subtree pull` (or copy `embed/` + `build/versions.env`).

## Releasing

Bump a version in [`build/versions.env`](build/versions.env) and push — the
[`vendor-toolchain`](.github/workflows/vendor.yml) workflow rebuilds clang/make/
git on native x86_64 and arm64 runners, re-hosts bpftool/esbuild/headers,
publishes all assets to the `toolchain` release, and records the checksums back
into `versions.env`.

Build a single tool locally:

```sh
build/build-clang.sh arm64        # or amd64; also build-make.sh / build-git.sh
build/fetch-bpftool.sh            # prebuilt; also fetch-esbuild.sh / fetch-libbpf-headers.sh
```
