# Guidelines for Jellyfin FFmpeg Build Process

This repository is a tailored fork of FFmpeg for Jellyfin. Please observe the following conventions when working on this codebase:

## Directory Structure and Organization
- **Patches**: All source code patches and modifications must reside under the root `patches/` directory in subfolders per feature or dependency (e.g., `patches/ffmpeg/`, `patches/libplacebo/`, `patches/mfx/`).
- **Packaging Scripts**: All scripts, Dockerfiles, and logic related to building packages must be isolated within the `packaging/` directory at the repository root.
- **Portable Builds**: All shared portable building recipes (formerly in `builder/` at root) are organized under `packaging/portable/`.
- **Debian Packaging**: The Debian metadata directory resides at `packaging/debian/`.

## Build and Compilation Process
- **Static Dockerfiles**: Avoid generating temporary Dockerfiles via templates or Makefiles (do not use `Dockerfile.make` or `Dockerfile.in`). Instead, use the static `packaging/linux/Dockerfile` and `packaging/windows/Dockerfile.win64` with build arguments (`--build-arg`) and the `TARGETPLATFORM` variable for architecture-specific configurations.
- **Workflow Scope**: GitHub Actions workflows are restricted to orchestration and artifact management; they must not contain pure compilation logic.
- **Compilation Environment**: Compilation must be performed within Dockerfiles for all targets except Windows and macOS native builds.
