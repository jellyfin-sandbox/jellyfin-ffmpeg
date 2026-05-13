#!/usr/bin/env bash

usage() {
    echo -e "Build Jellyfin FFMPEG deb packages"
    echo -e " $0 <release> <arch>"
    echo -e "Releases:          Arches:"
    echo -e " * bullseye         * amd64"
    echo -e " * bookworm         * arm64"
    echo -e " * trixie"
    echo -e " * jammy"
    echo -e " * noble"
    echo -e " * resolute"
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CALL_DIR="$(pwd)"
cd "$SCRIPT_DIR"

if [[ -z ${1} ]]; then
    usage
    exit 1
fi

cli_release="${1}"
case ${cli_release} in
    'bullseye')
        base_image="debian"
        base_tag="bullseye"
        release="${base_image}:${base_tag}"
        gcc_ver="10"
        llvm_ver="16"
        llvmspirvlib_ver="11"
    ;;
    'bookworm')
        base_image="debian"
        base_tag="bookworm"
        release="${base_image}:${base_tag}"
        gcc_ver="12"
        llvm_ver="19"
        llvmspirvlib_ver="15"
    ;;
    'trixie')
        base_image="debian"
        base_tag="trixie"
        release="${base_image}:${base_tag}"
        gcc_ver="14"
        llvm_ver="19"
        llvmspirvlib_ver="19"
    ;;
    'jammy')
        base_image="ubuntu"
        base_tag="jammy"
        release="${base_image}:${base_tag}"
        gcc_ver="11"
        llvm_ver="15"
        llvmspirvlib_ver="15"
    ;;
    'noble')
        base_image="ubuntu"
        base_tag="noble"
        release="${base_image}:${base_tag}"
        gcc_ver="13"
        llvm_ver="19"
        llvmspirvlib_ver="19"
    ;;
    'resolute')
        base_image="ubuntu"
        base_tag="resolute"
        release="${base_image}:${base_tag}"
        gcc_ver="15"
        llvm_ver="20"
        llvmspirvlib_ver="20"
    ;;
    *)
        echo "Invalid release."
        usage
        exit 1
    ;;
esac

cli_arch="${2}"
case ${cli_arch} in
    'amd64')
        arch="amd64"
    ;;
    'arm64')
        arch="arm64"
    ;;
    *)
        echo "Invalid architecture."
        usage
        exit 1
    ;;
esac

set -o xtrace
set -o errexit

# Check for dependencies
if ! command -v "docker" &>/dev/null && command -v "podman" &>/dev/null; then
    container_cmd=podman
else
    container_cmd=docker
fi

for dep in ${container_cmd} mmv; do
    command -v "${dep}" &>/dev/null || { echo "The command '${dep}' is required."; exit 1; }
done

image_name="jellyfin-ffmpeg-build-${cli_release}"
package_temporary_dir="$( mktemp -d )"

# Trap cleanup for latter sections
cleanup() {
    # Remove tempdir
    rm -rf "${package_temporary_dir}"
}
trap cleanup EXIT INT

# Set up the build environment docker image
${container_cmd} build \
    --build-arg BASE_IMAGE="${base_image}" \
    --build-arg BASE_TAG="${base_tag}" \
    --build-arg GCC_VER="${gcc_ver}" \
    --build-arg LLVM_VER="${llvm_ver}" \
    --build-arg LLVMSPIRVLIB_VER="${llvmspirvlib_ver}" \
    --build-arg TARGETPLATFORM="linux/${arch}" \
    -f "$SCRIPT_DIR/Dockerfile.in" \
    -t "${image_name}" \
    "$REPO_ROOT"
# Build the APKs and copy out to ${package_temporary_dir}
${container_cmd} run --rm -e "RELEASE=${release}" -v "${package_temporary_dir}:/dist" "${image_name}"
# If no 3rd parameter was specified, move APKs to parent directory
if [[ -z ${3} ]]; then
    path="${REPO_ROOT}/bin"
elif [[ ${3} = /* ]]; then
    path="${3}"
else
    path="${CALL_DIR}/${3}"
fi
mkdir -p "${path}"
mmv "${package_temporary_dir}/deb/*.deb" "${path}/#1.deb"
mmv "${package_temporary_dir}/deb/*_${arch}.*" "${path}/#1-${cli_release}_${arch}.#2"
