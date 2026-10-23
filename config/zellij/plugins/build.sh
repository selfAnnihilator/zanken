#!/bin/bash

# Rebuild the local menu extensions against the exact upstream version.
set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/zanken-zellij-plugin.XXXXXXXX")
trap 'rm -rf -- "$build_dir"' EXIT

curl --fail --location --silent --show-error \
  "https://codeload.github.com/zellij-org/zellij/tar.gz/refs/tags/v0.45.1" \
  -o "$build_dir/source.tar.gz"
tar -xzf "$build_dir/source.tar.gz" --strip-components=1 -C "$build_dir"
patch --directory="$build_dir" --strip=1 < "$plugin_dir/plugin-manager.patch"
patch --directory="$build_dir" --strip=1 < "$plugin_dir/vim-navigation.patch"
patch --directory="$build_dir" --strip=1 < "$plugin_dir/status-bar.patch"
cd -- "$build_dir"
rustup target add --toolchain 1.95.0 wasm32-wasip1
cargo +1.95.0 build --locked --release --target wasm32-wasip1 -p plugin-manager -p about -p configuration -p layout-manager -p share -p status-bar -j 4
for plugin in plugin-manager about configuration layout-manager share status-bar; do
  install -m 0644 "target/wasm32-wasip1/release/$plugin.wasm" "$plugin_dir/$plugin.wasm"
done
