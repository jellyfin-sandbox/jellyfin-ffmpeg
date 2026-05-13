#!/bin/bash
# MacOS build script for Jellyfin FFmpeg
set -e

SOURCE_DIR="$(pwd)"
ARTIFACT_DIR="${SOURCE_DIR}/artifacts"
mkdir -p "${ARTIFACT_DIR}"

# Prepare builder/ directory for the build as it expects it
mkdir -p builder
cp -r packaging/portable/* builder/

./builder/macos/buildmac.sh "$@"
