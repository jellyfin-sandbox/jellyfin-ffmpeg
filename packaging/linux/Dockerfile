ARG BASE_IMAGE=debian:bookworm
FROM --platform=$BUILDPLATFORM ${BASE_IMAGE}
ARG TARGETPLATFORM
ARG TARGETARCH
ARG GCC_VER=12
ARG LLVM_VER=19
ARG LLVMSPIRVLIB_VER=15
ARG SOURCE_DIR=/ffmpeg
ARG ARTIFACT_DIR=/dist
ENV DEB_BUILD_OPTIONS=noddebs \
    DEBIAN_FRONTEND=noninteractive \
    SOURCE_DIR=${SOURCE_DIR} \
    ARTIFACT_DIR=${ARTIFACT_DIR} \
    TARGET_DIR=/usr/lib/jellyfin-ffmpeg \
    DPKG_INSTALL_LIST=${SOURCE_DIR}/packaging/debian/jellyfin-ffmpeg7.install \
    CMAKE_POLICY_VERSION_MINIMUM="3.5"
ENV ARCH=${TARGETARCH} \
    GCC_VER=${GCC_VER} \
    LLVM_VER=${LLVM_VER} \
    LLVMSPIRVLIB_VER=${LLVMSPIRVLIB_VER}
ENV PATH=${TARGET_DIR}/bin:${PATH} \
    PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig \
    LD_LIBRARY_PATH=${TARGET_DIR}/lib:${TARGET_DIR}/lib/mfx:${TARGET_DIR}/lib/xorg \
    LDFLAGS="-Wl,-rpath=${TARGET_DIR}/lib -L${TARGET_DIR}/lib -lm" \
    CXXFLAGS="-I${TARGET_DIR}/include" \
    CPPFLAGS="-I${TARGET_DIR}/include" \
    CFLAGS="-I${TARGET_DIR}/include"
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y apt-transport-https \
    curl ninja-build debhelper gnupg wget devscripts mmv equivs git nasm pkg-config subversion dh-autoreconf \
    libpciaccess-dev libwayland-dev libx11-dev libx11-xcb-dev libxcb-dri2-0-dev libxcb-dri3-dev libxcb-present-dev \
    libxcb-shm0-dev libxcb-sync-dev libxshmfence-dev libxext-dev libxfixes-dev libxcb1-dev libxrandr-dev libzstd-dev \
    libelf-dev python3-pip zip unzip tar flex bison gperf ragel lsb-release quilt \
 && apt-get clean autoclean -y && apt-get autoremove -y
RUN pip3 install $(pip3 help install | grep -o "\-\-break-system-packages") --ignore-installed pip \
 && pip3 install $(pip3 help install | grep -o "\-\-break-system-packages") meson cmake mako jinja2 pyyaml
RUN git config --global http.postbuffer 524288000 && git config --global advice.detachedHead false
COPY . ${SOURCE_DIR}/
RUN mkdir -p ${SOURCE_DIR}/debian && cp -r ${SOURCE_DIR}/packaging/debian/* ${SOURCE_DIR}/debian/ && \
    ln -sf ${SOURCE_DIR}/patches/ffmpeg ${SOURCE_DIR}/debian/patches
RUN ln -sf ${SOURCE_DIR}/packaging/linux/docker-build.sh /docker-build.sh
VOLUME ${ARTIFACT_DIR}/
ENTRYPOINT ["/docker-build.sh"]
