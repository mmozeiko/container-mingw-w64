FROM ubuntu:26.04

WORKDIR /mnt

ENV MINGW=/mingw

ARG PKGCONF_VERSION=3.0.5
ARG CMAKE_VERSION=4.4.2
ARG BINUTILS_VERSION=2.47
ARG MINGW_VERSION=14.0.0
ARG GCC_VERSION=16.2.0
ARG NASM_VERSION=3.02
ARG NVCC_VERSION=13.3.1

RUN ln -sf /bin/bash /bin/sh

RUN set -ex \
    \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --no-install-recommends -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        ca-certificates \
        gcc \
        g++ \
        zlib1g-dev \
        libssl-dev \
        libgmp-dev \
        libmpfr-dev \
        libmpc-dev \
        libisl-dev \
        libssl3 \
        libgmp10 \
        libmpfr6 \
        libmpc3 \
        libisl23 \
        xz-utils \
        ninja-build \
        texinfo \
        meson \
        gnupg \
        bzip2 \
        patch \
        gperf \
        bison \
        file \
        flex \
        make \
        yasm \
        wget \
        zip \
        git \
        libarchive-tools \
    \
    && wget -q https://github.com/pkgconf/pkgconf/releases/download/pkgconf-${PKGCONF_VERSION}/pkgconf-${PKGCONF_VERSION}.tar.xz -O - | tar -xJ \
    && wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz -O - | tar -xz \
    && wget -q https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz -O - | tar -xJ \
    && wget -q https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v${MINGW_VERSION}.zip -O - | bsdtar -xf- \
    && wget -q https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz -O - | tar -xJ \
    && wget -q https://www.nasm.us/pub/nasm/releasebuilds/${NASM_VERSION}/nasm-${NASM_VERSION}.tar.xz -O - | tar -xJ \
    \
    && mkdir -p ${MINGW}/include ${MINGW}/lib/pkgconfig \
    && chmod 0777 -R /mnt ${MINGW} \
    \
    && cd pkgconf-${PKGCONF_VERSION} \
    && ./configure \
        --prefix=/usr/local \
        --with-pkg-config-dir=${MINGW}/lib/pkgconfig \
        --disable-shared \
    && make -j`nproc` \
    && make install \
    && cd .. \
    && ln -sf /usr/local/bin/pkgconf /usr/local/bin/pkg-config \
    \
    && cd cmake-${CMAKE_VERSION} \
    && ./configure \
        --prefix=/usr/local \
        --parallel=`nproc` \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && cd binutils-${BINUTILS_VERSION} \
    && ./configure \
        --prefix=/usr/local \
        --target=x86_64-w64-mingw32 \
        --disable-shared \
        --enable-static \
        --disable-lto \
        --disable-plugins \
        --disable-multilib \
        --disable-nls \
        --disable-werror \
        --with-system-zlib \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && mkdir mingw-w64 \
    && cd mingw-w64 \
    && ../mingw-w64-v${MINGW_VERSION}/mingw-w64-headers/configure \
        --prefix=/usr/local/x86_64-w64-mingw32 \
        --host=x86_64-w64-mingw32 \
        --enable-sdk=all \
    && make install \
    && cd .. \
    \
    && mkdir gcc \
    && cd gcc \
    && ../gcc-${GCC_VERSION}/configure \
        --prefix=/usr/local \
        --target=x86_64-w64-mingw32 \
        --enable-languages=c,c++ \
        --disable-shared \
        --enable-static \
        --enable-threads=win32 \
        --with-system-zlib \
        --enable-tls \
        --enable-libgomp \
        --enable-libatomic \
        --enable-graphite \
        --enable-libstdcxx-threads \
        --disable-libstdcxx-pch \
        --disable-libstdcxx-debug \
        --disable-multilib \
        --disable-lto \
        --disable-nls \
        --disable-werror \
    && make -j`nproc` all-gcc \
    && make install-gcc \
    && cd .. \
    \
    && cd mingw-w64 \
    && ../mingw-w64-v${MINGW_VERSION}/mingw-w64-crt/configure \
        --prefix=/usr/local/x86_64-w64-mingw32 \
        --host=x86_64-w64-mingw32 \
        --enable-wildcard \
        --disable-lib32 \
        --enable-lib64 \
    && (make || make || make || make) \
    && make install \
    && cd .. \
    \
    && cd mingw-w64 \
    && ../mingw-w64-v${MINGW_VERSION}/mingw-w64-libraries/winpthreads/configure \
        --prefix=/usr/local/x86_64-w64-mingw32 \
        --host=x86_64-w64-mingw32 \
        --enable-static \
        --disable-shared \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && cd gcc \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && cd nasm-${NASM_VERSION} \
    && ./configure --prefix=/usr/local \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && rm -r pkgconf-${PKGCONF_VERSION} \
    && rm -r cmake-${CMAKE_VERSION} \
    && rm -r binutils-${BINUTILS_VERSION} \
    && rm -r mingw-w64 mingw-w64-v${MINGW_VERSION} \
    && rm -r gcc gcc-${GCC_VERSION} \
    && rm -r nasm-${NASM_VERSION} \
    \
    && apt-get remove --purge -y file gcc g++ zlib1g-dev libssl-dev libgmp-dev libmpfr-dev libmpc-dev libisl-dev \
    \
    && wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2604/x86_64/cuda-keyring_1.1-1_all.deb \
    && dpkg -i cuda-keyring_1.1-1_all.deb \
    && rm cuda-keyring_1.1-1_all.deb \
    && apt-get update \
    \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        cuda-nvcc-${NVCC_VERSION:0:2}-${NVCC_VERSION:3:1} \
    \
    && ln -s /usr/bin/gcc /usr/local/cuda/bin/gcc \
    && ln -s /usr/bin/g++ /usr/local/cuda/bin/g++ \
    \
    && apt-get remove --purge -y gnupg \
    && apt-get autoremove --purge -y \
    && apt-get clean
