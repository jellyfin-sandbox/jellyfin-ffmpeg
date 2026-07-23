#!/bin/bash

SCRIPT_REPO="https://github.com/harfbuzz/harfbuzz.git"
SCRIPT_COMMIT="e9348cd76d38f72cf881cc860035403220ffbe0b"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerbuild() {
    git-mini-clone "$SCRIPT_REPO" "$SCRIPT_COMMIT" harfbuzz
    cd harfbuzz

    mkdir build && cd build

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --buildtype=release
        --default-library=static
        -Dfreetype=enabled
        -Dglib=disabled
        -Dgobject=disabled
        -Dcairo=disabled
        -Dchafa=disabled
        -Dicu=disabled
        -Dtests=disabled
        -Dintrospection=disabled
        -Ddocs=disabled
        -Dutilities=disabled
    )

    if [[ $TARGET == win* || $TARGET == linux* ]]; then
        myconf+=(
            --cross-file=/cross.meson
        )
    elif [[ $TARGET == mac* ]]; then
        # freetype's pkg-config usage cannot find static libbrotli
        export FREETYPE_LIBS="$(pkg-config --libs --static freetype2)"
        if [ "$MACOS_BUILDER_CPU_ARCH" = "arm64" ] && [ "$TARGET" = "mac64" ]; then
            myconf+=(
                --cross-file="$BUILDER_ROOT"/images/macos/cross/cross-x86_64.txt
            )
        fi
    else
        echo "Unknown target"
        return -1
    fi

    meson "${myconf[@]}" ..
    ninja -j$(nproc)
    ninja install
}

ffbuild_configure() {
    echo --enable-libharfbuzz
}

ffbuild_unconfigure() {
    echo --disable-libharfbuzz
}
