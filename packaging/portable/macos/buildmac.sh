#!/bin/bash
set -xe
cd "$(dirname "$0")"
export BUILDER_ROOT="$(pwd)"
export ROOT_DIR="../../../"
export FFBUILD_PREFIX="/opt/ffbuild/prefix"

get_output() {
    (
        SELF="$1"
        source "$1"
        if ffbuild_enabled; then
            ffbuild_$2 || return 0
        else
            ffbuild_un$2 || return 0
        fi
    )
}

# Accept architecture as first argument, fallback to uname -m if not provided
if [ -n "$1" ]; then
    arch="$1"
else
    arch=$(uname -m)
fi
TARGET="macarm64"
VARIANT="gpl"
if [ "$arch" = "arm64" ]; then
    TARGET="macarm64"
elif [ "$arch" = "x86_64" ]; then
    TARGET="mac64"
else
    echo "Unknown architecture"
    return 1
fi

source "${ROOT_DIR}packaging/portable/variants/${TARGET}-gpl.sh"

for addin in ${ADDINS[*]}; do
    source "${ROOT_DIR}packaging/portable/addins/${addin}.sh"
done

for script in "${ROOT_DIR}packaging/portable/scripts.d/"*.sh; do
    FF_CONFIGURE+=" $(get_output "$script" configure)"
    FF_CFLAGS+=" $(get_output "$script" cflags)"
    FF_CXXFLAGS+=" $(get_output "$script" cxxflags)"
    FF_LDFLAGS+=" $(get_output "$script" ldflags)"
    FF_LDEXEFLAGS+=" $(get_output "$script" ldexeflags)"
    FF_LIBS+=" $(get_output "$script" libs)"
done

FF_CONFIGURE="$(xargs <<< "$FF_CONFIGURE")"
FF_CFLAGS="$(xargs <<< "$FF_CFLAGS")"
FF_CXXFLAGS="$(xargs <<< "$FF_CXXFLAGS")"
FF_LDFLAGS="$(xargs <<< "$FF_LDFLAGS")"
FF_LDEXEFLAGS="$(xargs <<< "$FF_LDEXEFLAGS")"
FF_LIBS="$(xargs <<< "$FF_LIBS")"
FF_HOST_CFLAGS="$(xargs <<< "$FF_HOST_CFLAGS")"
FF_HOST_LDFLAGS="$(xargs <<< "$FF_HOST_LDFLAGS")"
FFBUILD_TARGET_FLAGS="$(xargs <<< "$FFBUILD_TARGET_FLAGS")"

mkdir -p build
for macbase in "${ROOT_DIR}packaging/portable/images/macos/"*.sh; do
    cd "$BUILDER_ROOT"/build
    source "$macbase"
    ffbuild_macbase || return $?
done

cd "$BUILDER_ROOT"
for lib in "${ROOT_DIR}packaging/portable/scripts.d/"*.sh; do
    cd "$BUILDER_ROOT"/build
    source "$lib"
    ffbuild_enabled || continue
    ffbuild_dockerbuild || return $?
done

cd "$BUILDER_ROOT"
cd "${ROOT_DIR}"

# Reconstruct debian/ patches link for build
mkdir -p debian
ln -sf "$(pwd)/patches/ffmpeg" debian/patches

if [[ -f "debian/patches/series" ]]; then
    # patches are in debian/patches
    ln -sf "$(pwd)/debian/patches" patches
    quilt push -a
fi

./configure --prefix=/ffbuild/prefix \
    $FFBUILD_TARGET_FLAGS \
    --host-cflags="$FF_HOST_CFLAGS" \
    --host-ldflags="$FF_HOST_LDFLAGS" \
    --extra-version="Jellyfin" \
    --extra-cflags="$FF_CFLAGS" \
    --extra-cxxflags="$FF_CXXFLAGS" \
    --extra-ldflags="$FF_LDFLAGS" \
    --extra-ldexeflags="$FF_LDEXEFLAGS" \
    --extra-libs="$FF_LIBS" \
    $FF_CONFIGURE
make -j$(nproc) V=1

# We have to manually match lines to get version as there will be no dpkg-parsechangelog on macOS
PKG_VER=0.0.0
while IFS= read -r line; do
    if [[ $line == jellyfin-ffmpeg* ]]; then
        if [[ $line =~ \(([^\)]+)\) ]]; then
            PKG_VER="${BASH_REMATCH[1]}"
            break
        fi
    fi
done < "packaging/debian/changelog"

PKG_NAME="jellyfin-ffmpeg_${PKG_VER}_portable_${TARGET}-${VARIANT}${ADDINS_STR:+-}${ADDINS_STR}"
ARTIFACTS_PATH="${ROOT_DIR}artifacts"
OUTPUT_FNAME="${PKG_NAME}.tar.xz"
cd "$BUILDER_ROOT"
mkdir -p "${ARTIFACTS_PATH}"
# bsdtar can add files in parent dir, but macOS's native archive utility won't be able to unzip it by double clicking, we have to move it to current dir as a workaround
mv ../../../ffmpeg ./
mv ../../../ffprobe ./
tar -cJf "${ARTIFACTS_PATH}/${OUTPUT_FNAME}" ffmpeg ffprobe
cd "$BUILDER_ROOT"/..

if [[ -n "$GITHUB_ACTIONS" ]]; then
    echo "build_name=${BUILD_NAME}" >> "$GITHUB_OUTPUT"
    echo "${OUTPUT_FNAME}" > "${ARTIFACTS_PATH}/${TARGET}-${VARIANT}${ADDINS_STR:+-}${ADDINS_STR}.txt"
fi
