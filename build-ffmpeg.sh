#!/bin/bash

### Build dependencies:
apt install -y wget curl unzip build-essential libtool pkg-config cmake autoconf automake yasm gperf nasm meson python3-distutils cython3 python3-numpy

# Parse opts
FFMPEG_VERSION=6.1
QSV=0
NVENC=0
TENBIT=0
ZLIB=0
FRIBIDI=0
FREETYPE=0
LIBUUID=0
LIBXML2=0
FONTCONFIG=0
LIBASS=0
NASM=0
ZIMG=0
VMAF=0
LAME=0
LIBVPX=0
OPUS=0
FDKAAC=0
LIBPNG=0
LIBX264=0
LIBX265=0
LIBOGG=0
LIBVORBIS=0
LIBTHEORA=0
DAV1D=0
OPENJPEG=0
BUILD=$PWD/build
OUTPUT=/opt/noisypeak/np-ux
SELECTED_LIBRARIES=()

while true; do
  case "$1" in
    -o | --output) OUTPUT=$2; shift; shift ;;
    --ffmpeg-version) FFMPEG_VERSION=$2; shift; shift ;;
    --qsv) QSV=1; shift ;;
    --nvenc) NVENC=1; shift ;;
    --10bit) TENBIT=1; shift ;;
    zlib) ZLIB=1; shift ;;
    fribidi) FRIBIDI=1; shift ;;
    freetype) FREETYPE=1; shift ;;
    libuuid) LIBUUID=1; shift ;;
    libxml2) LIBXML2=1; shift ;;
    fontconfig) FONTCONFIG=1; shift ;;
    libass) LIBASS=1; shift ;;
    nasm) NASM=1; shift ;;
    zimg) ZIMG=1; shift ;;
    vmaf) VMAF=1; shift ;;
    lame) LAME=1; shift ;;
    libvpx) LIBVPX=1; shift ;;
    opus) OPUS=1; shift ;;
    fdkaac) FDKAAC=1; shift ;;
    libpng) LIBPNG=1; shift ;;
    libx264) LIBX264=1; shift ;;
    libx265) LIBX265=1; shift ;;
    libogg) LIBOGG=1; shift ;;
    libvorbis) LIBVORBIS=1; shift ;;
    libtheora) LIBTHEORA=1; shift ;;
    dav1d) DAV1D=1; shift ;;
    openjpeg) OPENJPEG=1; shift ;;
    *) break ;;
  esac
done

# Define installer fns
function install {
    echo -n Installing $1-$2...
    ARGS=($@)
    INSTALLED=$(IFS=_ ; echo ".${ARGS[*]}.installed")
    if [ -f "$INSTALLED" ] ; then
        echo DONE
        return
    fi

    NAME=$1
    shift
    (
        exec 1>>build.log
        exec 2>&1
        install_$NAME $@
    )
    if [ ! $? -eq 0 ] ; then
        echo ERROR, please check build.log
        return 1
    fi

    touch $INSTALLED
    echo OK
}


function install_nasm {
    tar xvf dist/nasm-2.15.05.tar.bz2 && \
    cd nasm-* && \
    ./autogen.sh && \
    ./configure --prefix=$BUILD && \
    make install
}

function install_freetype {
    tar xf dist/freetype-2.10.0.tar.bz2 && \
    cd freetype-* && \
    ./configure --prefix=$BUILD --disable-shared &&
    make install
}

function install_fribidi {
    tar xf dist/fribidi-1.0.13.tar.xz && \
    cd fribidi-* && \
    autoreconf -fiv && \
    ./configure --prefix=$BUILD --disable-shared && \
    make install
}

function install_libuuid {
    tar xvf dist/util-linux_2.34.orig.tar.xz && \
    cd util-linux-2.34 && \
    ./configure --prefix=$BUILD --disable-shared --without-ncurses --disable-all-programs --enable-libuuid --enable-libtool && \
    make install
}

function install_libxml2 {
    tar xzvf dist/libxml2-sources-2.9.7.tar.gz && \
    cd libxml2-* && \
    ./autogen.sh && \
    ./configure --prefix=$BUILD --disable-shared && \
    make install
}

function install_fontconfig {
    tar xf dist/fontconfig-2.12.93.tar.gz && \
    cd fontconfig-* && \
    export UUID_CFLAGS="-I$BUILD/include" && \
    ./configure --prefix=$BUILD --disable-shared --enable-libxml2 && \
    make install
}

function install_libass {
    tar xf dist/libass-0.13.2.tar.gz && \
    cd libass-* && \
    ./configure --prefix=$BUILD --disable-shared --without-docbook && \
    make install
}

function install_libx264 {
    CONFIGURE_FLAGS="--prefix=$BUILD --disable-shared --enable-static --enable-pic"
    if [ $2 -eq 1 ] ; then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --bit-depth=10"
    fi
    tar xf dist/x264-stable-baee400f.tar.bz2 && \
    cd x264-* && \
    ./configure $CONFIGURE_FLAGS && \
    make install
}

function install_libx265 {
    CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX:PATH=$BUILD -DENABLE_SHARED:bool=off -DX265_LATEST_TAG=3.5"
    if [ $2 -eq 1 ] ; then
        CMAKE_FLAGS="$CMAKE_FLAGS -DHIGH_BIT_DEPTH=ON"
    fi
    tar xzf dist/x265_3.5.tar.gz && \
    cd x265*/build/linux && \
    echo 'set(X265_LATEST_TAG "3.5")' >>../../source/cmake/Version.cmake
    cmake -G "Unix Makefiles" $CMAKE_FLAGS ../../source && \
    make && \
    make install
}

function install_fdkaac {
    tar xf dist/fdk-aac-0.1.6.tar.gz && \
    cd fdk-aac-* && \
    autoreconf -fiv && \
    ./configure --prefix=$BUILD --disable-shared --enable-static && \
    make install
}

function install_lame {
    tar xf dist/lame-3.100.tar.gz && \
    cd lame-* && \
    ./configure --prefix=$BUILD --enable-nasm --disable-shared && \
    make install
}

function install_opus {
    tar xf dist/opus-1.1.2.tar.gz && \
    cd opus-* && \
    ./configure --prefix=$BUILD --disable-shared && \
    make install
}

function install_libvpx {
    tar xf dist/libvpx-1.5.0.tar.bz2 && \
    cd libvpx-* && \
    ./configure --prefix=$BUILD --disable-shared --disable-examples --disable-unit-tests --enable-pic && \
    make install
}

function install_libogg {
    tar xf dist/libogg-1.3.1.tar.gz && \
    cd libogg-* && \
    ./configure --prefix=$BUILD --disable-shared && \
    make install
}

function install_libvorbis {
    tar xf dist/libvorbis-1.3.3.tar.gz && \
    cd libvorbis-* && \
    ./configure --prefix=$BUILD --disable-shared && \
    make install
}

function install_libtheora {
    tar xf dist/libtheora-1.1.1.tar.bz2 && \
    cd libtheora-* && \
    ./configure --prefix=$BUILD --disable-shared --disable-examples && \
    make install
}

function install_openjpeg {
    unzip -o dist/openjpeg-2.3.0.zip && \
    cd openjpeg-2.3.0 && \
    mkdir -p build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=$BUILD -DBUILD_SHARED_LIBS:bool=OFF && \
    make && \
    # install everything by hand, openjpeg install make target is broken when BUILD_SHARED_LIBS:bool=off
    mkdir -p $BUILD/lib $BUILD/include/openjpeg-2.3 && \
    cp bin/libopenjp2.a $BUILD/lib && \
    cp ../src/lib/openjp2/{openjpeg.h,opj_stdint.h} $BUILD/include/openjpeg-2.3 && \
    cp src/lib/openjp2/opj_config.h $BUILD/include/openjpeg-2.3 && \
    cp libopenjp2.pc $BUILD/lib/pkgconfig/
}

function install_zimg {
    tar xf dist/zimg-3.0.5.tar.gz && \
    cd zimg-release-3.0.5 && \
    ./autogen.sh && \
    ./configure --prefix=$BUILD --disable-shared && \
    make install
}

function install_vmaf {
    unzip -o dist/vmaf-2.3.1.zip && \
    cd vmaf-* && \
    meson setup libvmaf/build libvmaf --buildtype release -Dprefix=$BUILD -Ddefault_library=static &&
    ninja -vC libvmaf/build install &&
    cp $BUILD/lib/x86_64-linux-gnu/pkgconfig/libvmaf.pc $BUILD/lib/pkgconfig &&
    sed -i 's/Libs:/Libs: -lstdc++/' $BUILD/lib/pkgconfig/libvmaf.pc
}

function install_zlib {
    tar xf dist/zlib-1.3.tar.gz && \
    cd zlib-* && \
    ./configure --prefix=$BUILD --static && \
    make install
}

function install_libpng {
    tar xf dist/libpng-1.6.37.tar.xz &&
    cd libpng-1.6.37 &&
    LDFLAGS=-L$BUILD/lib/ CFLAGS=-I$BUILD/include/ ./configure --prefix=$BUILD --disable-shared && \
    CPATH=$BUILD/include/ LIBRARY_PATH=$BUILD/include/ make install
}

function install_dav1d {
    unzip dist/dav1d-0.8.2.zip && \
    cd dav1d-0.8.2 && \
    mkdir build && cd build && \
    meson .. --default-library=static --prefix=$BUILD --libdir=$BUILD/lib && \
    ninja && \
    meson install
}

function install_nvenc {
    tar xf dist/nv-codec-headers-11.0.10.0.tar.gz && \
    cd nv-codec-headers-11.0.10.0 && \
    make install PREFIX=$BUILD  && \
    cd - && \
    curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-minimal-build-11-1_11.1.0-1_amd64.deb && \
    curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-compiler-11-1_11.1.0-1_amd64.deb && \
    curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-cudart-dev-11-1_11.1.74-1_amd64.deb && \
    curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-cudart-11-1_11.1.74-1_amd64.deb && \
    curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-nvprune-11-1_11.1.74-1_amd64.deb && \
    curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-driver-dev-11-1_11.1.74-1_amd64.deb && \
    curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-nvcc-11-1_11.1.74-1_amd64.deb && \
    curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-cuobjdump-11-1_11.1.74-1_amd64.deb && \
    curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/libnpp-dev-11-1_11.1.1.269-1_amd64.deb && \
    curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/libnpp-11-1_11.1.1.269-1_amd64.deb && \
    dpkg -i cuda-* libnpp-*
}

function install_qsv {
    tar xf dist/msdk-20.3.tgz -C $BUILD && \
    cp $BUILD/opt/intel/mediasdk/lib/pkgconfig/{libmfx.pc,libva.pc,libva-drm.pc} $BUILD/lib/pkgconfig/ && \
    sed -i -e "s+=/opt/intel/mediasdk+=$BUILD/opt/intel/mediasdk+g" $BUILD/lib/pkgconfig/libmfx.pc && \
    sed -i -e "s+=/opt/intel/mediasdk+=$BUILD/opt/intel/mediasdk+g" $BUILD/lib/pkgconfig/libva.pc && \
    sed -i -e "s+=/opt/intel/mediasdk+=$BUILD/opt/intel/mediasdk+g" $BUILD/lib/pkgconfig/libva-drm.pc && \
    apt-get install -y libdrm-dev
}

function install_vpl {
#    apt-get install -y libdrm-dev libva-dev
#    tar xf dist/libvpl-2.11.0.tar.gz && \
#    cd libvpl-2.11.0 && \
#    mkdir build && cd build && \
#    cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$BUILD" \
#        -DCMAKE_INSTALL_BINDIR="$BUILD"/bin -DCMAKE_INSTALL_LIBDIR="$BUILD"/lib \
#        -DBUILD_DISPATCHER=ON -DBUILD_DEV=ON \
#        -DBUILD_PREVIEW=OFF -DBUILD_TOOLS=OFF -DBUILD_TOOLS_ONEVPL_EXPERIMENTAL=OFF -DINSTALL_EXAMPLE_CODE=OFF \
#        -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF .. && \
#    ninja -j4 && \
#    ninja install

    tar xf dist/libvpl-24.3.4+libmfx-22.5.4.tar.gz -C $BUILD && \
    cp $BUILD/opt/intel/media/lib64/pkgconfig/{vpl.pc,libmfx.pc,libmfx-gen.pc,libva.pc,libva-drm.pc,libdrm.pc} $BUILD/lib/pkgconfig/ && \
    sed -i -e "s+=/opt/intel/media+=$BUILD/opt/intel/media+g" $BUILD/lib/pkgconfig/vpl.pc && \
    sed -i -e "s+=/opt/intel/media+=$BUILD/opt/intel/media+g" $BUILD/lib/pkgconfig/libmfx.pc && \
    sed -i -e "s+=/opt/intel/media+=$BUILD/opt/intel/media+g" $BUILD/lib/pkgconfig/libmfx-gen.pc && \
    sed -i -e "s+=/opt/intel/media+=$BUILD/opt/intel/media+g" $BUILD/lib/pkgconfig/libva.pc && \
    sed -i -e "s+=/opt/intel/media+=$BUILD/opt/intel/media+g" $BUILD/lib/pkgconfig/libva-drm.pc && \
    sed -i -e "s+=/opt/intel/media+=$BUILD/opt/intel/media+g" $BUILD/lib/pkgconfig/libdrm.pc
}

function install_get_ffmpeg {
    tar xf dist/ffmpeg-$1.tar.xz
}

# Prepare environment
export PATH=$BUILD/bin:/usr/local/cuda-11.1/bin/:$PATH
export PKG_CONFIG_PATH=$BUILD/lib/pkgconfig:$BUILD/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig
mkdir -p $BUILD $OUTPUT

# Build dependencies
echo >build.log
echo "Starting installation with selected libraries: ${SELECTED_LIBRARIES[*]}"

FFMPEG_CONFIGURE_FLAGS="\
    --prefix=$BUILD \
    --pkg-config-flags="--static" \
    --disable-shared \
    --enable-gpl --enable-nonfree \
"
# Проверка и установка зависимостей
if [ "$ZLIB" -eq 1 ]; then
  install zlib 0 || exit 1
fi

if [ "$LIBPNG" -eq 1 ]; then
  install libpng 0 || exit 1
fi

if [ "$FREETYPE" -eq 1 ]; then
  install freetype 0 || exit 1
fi

if [ "$FRIBIDI" -eq 1 ]; then
  install fribidi 0 || exit 1
fi

if [ "$LIBUUID" -eq 1 ]; then
  install libuuid 0 || exit 1
fi

if [ "$LIBXML2" -eq 1 ]; then
  install libxml2 0 || exit 1
fi

if [ "$FONTCONFIG" -eq 1 ]; then
  install fontconfig 0 || exit 1
fi

if [ "$LIBASS" -eq 1 ]; then
  install libass 0 || exit 1
fi

if [ "$NASM" -eq 1 ]; then
  install nasm 0 || exit 1
fi

if [ "$LIBX264" -eq 1 ]; then
  install libx264 0 $TENBIT || exit 1
fi

if [ "$LIBX265" -eq 1 ]; then
  install libx265 0 $TENBIT || exit 1
fi

if [ "$FDKAAC" -eq 1 ]; then
  install fdkaac 0 || exit 1
fi

if [ "$LAME" -eq 1 ]; then
  install lame 0 || exit 1
fi

if [ "$OPUS" -eq 1 ]; then
  install opus 0 || exit 1
fi

if [ "$LIBVPX" -eq 1 ]; then
  install libvpx 0 || exit 1
fi

if [ "$LIBOGG" -eq 1 ]; then
  install libogg 0 || exit 1
fi

if [ "$LIBVORBIS" -eq 1 ]; then
  install libvorbis 0 || exit 1
fi

if [ "$LIBTHEORA" -eq 1 ]; then
  install libtheora 0 || exit 1
fi

if [ "$OPENJPEG" -eq 1 ]; then
  install openjpeg 0 || exit 1
fi

if [ "$ZIMG" -eq 1 ]; then
  install zimg 0 || exit 1
fi

if [ "$VMAF" -eq 1 ]; then
  install vmaf 0 || exit 1
fi

if [ "$DAV1D" -eq 1 ]; then
  install dav1d 0 || exit 1
fi


FFMPEG_CONFIGURE_QSV_FLAGS=
if [ $QSV -eq 1 ] ; then
    install vpl 0 || exit 1
    FFMPEG_CONFIGURE_QSV_FLAGS="--enable-libvpl --enable-vaapi --enable-libdrm --extra-cflags=-I$BUILD/opt/intel/media/include"
fi

FFMPEG_CONFIGURE_NVENC_FLAGS=
if [ $NVENC -eq 1 ] ; then
    install nvenc 0 || exit 1
    FFMPEG_CONFIGURE_NVENC_FLAGS="\
        --enable-nvenc --enable-cuvid --enable-cuda-sdk \
        --enable-libnpp \
        --extra-ldflags=-L/usr/local/cuda-11.1/lib64 \
        --extra-ldflags=-L/usr/local/cuda-11.1/lib64/stubs \
        --extra-ldflags=-lnppc \
        --extra-cflags=-I/usr/local/cuda-11.1/include"
fi

install get_ffmpeg $FFMPEG_VERSION || exit 1

(
    cd ffmpeg-$FFMPEG_VERSION && \
    ./configure $FFMPEG_CONFIGURE_FLAGS $FFMPEG_CONFIGURE_QSV_FLAGS $FFMPEG_CONFIGURE_NVENC_FLAGS && \
    make -j4
) || exit 1

# Deliver ffmpeg binaries
#§FMPEG_BINARY_SUFFIX=""
#if [ $TENBIT -eq 1 ] ; then
#    FFMPEG_BINARY_SUFFIX="10bit"
#fi

cp -v ffmpeg-$FFMPEG_VERSION/ffmpeg $OUTPUT/ffmpeg$FFMPEG_BINARY_SUFFIX-$FFMPEG_VERSION
cp -v ffmpeg-$FFMPEG_VERSION/ffprobe $OUTPUT/ffprobe-$FFMPEG_VERSION
