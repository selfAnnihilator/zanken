#!/bin/bash

# Rebuild the pinned tab bar with automatic numbered glyphs.
set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/zanken-zjstatus.XXXXXXXX")
trap 'rm -rf -- "$build_dir"' EXIT

curl --fail --location --silent --show-error \
  "https://codeload.github.com/dj95/zjstatus/tar.gz/refs/tags/v0.25.0" \
  -o "$build_dir/source.tar.gz"
tar -xzf "$build_dir/source.tar.gz" --strip-components=1 -C "$build_dir"
patch --directory="$build_dir" --strip=1 < "$plugin_dir/zjstatus.patch"
cd -- "$build_dir"
rustup target add --toolchain 1.95.0 wasm32-wasip1
cargo +1.95.0 build --locked --release --target wasm32-wasip1 --bin zjstatus -j 4
install -m 0644 "target/wasm32-wasip1/release/zjstatus.wasm" "$plugin_dir/zjstatus.wasm"
cd -- "$plugin_dir"
sha256sum zjstatus.wasm > zjstatus.sha256
