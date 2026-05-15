#!/bin/bash
# Entry point for macOS builds
set -e
arch=${1:-$(uname -m)}
# Build from project root
cd "$(dirname "$0")/.."
./packaging/portable/macos/buildmac.sh "$arch"
