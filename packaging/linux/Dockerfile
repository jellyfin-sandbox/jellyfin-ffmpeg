# Use a build argument for the base image
ARG BASE_IMAGE=debian:bookworm
FROM ${BASE_IMAGE}

# The target platform is automatically provided by Docker Buildx
ARG TARGETPLATFORM
ARG TARGETARCH

# Other build arguments with default values
ARG GCC_VER=12
ARG LLVM_VER=19
ARG LLVMSPIRVLIB_VER=15
ARG SOURCE_DIR=/ffmpeg
ARG ARTIFACT_DIR=/dist

# Docker run environment
ENV DEB_BUILD_OPTIONS=noddebs
ENV DEBIAN_FRONTEND=noninteractive
ENV SOURCE_DIR=${SOURCE_DIR}
ENV ARTIFACT_DIR=${ARTIFACT_DIR}
ENV TARGET_DIR=/usr/lib/jellyfin-ffmpeg
ENV DPKG_INSTALL_LIST=${SOURCE_DIR}/debian/jellyfin-ffmpeg7.install
ENV PATH=${TARGET_DIR}/bin:${PATH}
ENV PKG_CONFIG_PATH=${TARGET_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}
ENV LD_LIBRARY_PATH=${TARGET_DIR}/lib:${TARGET_DIR}/lib/mfx:${TARGET_DIR}/lib/xorg:${LD_LIBRARY_PATH}
ENV LDFLAGS="-Wl,-rpath=${TARGET_DIR}/lib -L${TARGET_DIR}/lib -lm"
ENV CXXFLAGS="-I${TARGET_DIR}/include $CXXFLAGS"
ENV CPPFLAGS="-I${TARGET_DIR}/include $CPPFLAGS"
ENV CFLAGS="-I${TARGET_DIR}/include $CFLAGS"
ENV CMAKE_POLICY_VERSION_MINIMUM="3.5"

# Set versions from args to env
ENV ARCH=${TARGETARCH}
ENV GCC_VER=${GCC_VER}
ENV LLVM_VER=${LLVM_VER}
ENV LLVMSPIRVLIB_VER=${LLVMSPIRVLIB_VER}

# Prepare Debian build environment
RUN apt-get update \
 && apt-get dist-upgrade -y \
 && apt-get install -y apt-transport-https \
    curl ninja-build debhelper gnupg wget devscripts \ 
    mmv equivs git nasm pkg-config subversion dh-autoreconf \
    libpciaccess-dev libwayland-dev libx11-dev libx11-xcb-dev \
    libxcb-dri2-0-dev libxcb-dri3-dev libxcb-present-dev \
    libxcb-shm0-dev libxcb-sync-dev libxshmfence-dev libxext-dev \ 
    libxfixes-dev libxcb1-dev libxrandr-dev libzstd-dev \ 
    libelf-dev python3-pip zip unzip tar flex bison gperf ragel lsb-release \
 && apt-get clean autoclean -y \
 && apt-get autoremove -y

# Install newer tools from pip3
RUN pip3 install $(pip3 help install | grep -o "\-\-break-system-packages") --ignore-installed pip \
 && pip3 install $(pip3 help install | grep -o "\-\-break-system-packages") meson cmake mako jinja2 pyyaml

# Avoids timeouts when using git and disable the detachedHead advice
RUN git config --global http.postbuffer 524288000 \
 && git config --global advice.detachedHead false

# Copy the source code
COPY . ${SOURCE_DIR}/

# Prepare debian/ directory for the build
RUN mkdir -p ${SOURCE_DIR}/debian && \
    cp -r ${SOURCE_DIR}/packaging/debian/* ${SOURCE_DIR}/debian/

# Link to docker-build script
RUN ln -sf ${SOURCE_DIR}/packaging/linux/docker-build.sh /docker-build.sh

VOLUME ${ARTIFACT_DIR}/

ENTRYPOINT ["/docker-build.sh"]
