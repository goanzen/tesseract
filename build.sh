#!/bin/bash

set -eo pipefail

rm -rf build build-out || true

mkdir -p build build-out

cd build

CONFIGURE_ARGS="--disable-openmp --disable-doc --disable-graphics"
if [[ -z "$ENABLE_CPU_OPTIMIZATIONS" ]]; then 
    CONFIGURE_ARGS+=" --disable-cpu-optimizations --enable-debug"
    export CFLAGS="-O0 -fexcess-precision=standard -fno-fast-math -fsignaling-nans -ffloat-store"
    export CXXFLAGS="-O0 -fexcess-precision=standard -fno-fast-math -fsignaling-nans -ffloat-store"
fi

export CC=clang

export CXX=clang++

case "$(uname -s)" in
    Linux*) 
        ../configure \
            LDFLAGS="-Wl,-rpath,'\$\$ORIGIN/../lib' -Wl,--disable-new-dtags" \
            $CONFIGURE_ARGS \
            --prefix=$(realpath ../build-out)

        make
        make install

        cp include/config_auto.h ../build-out/

        cd ..
        sed '4i\TESSERACT_DIR=$(dirname $SCRIPT_DIR)' download_tessdata.sh > build-out/bin/download_tessdata.sh
        chmod +x build-out/bin/download_tessdata.sh
        ;;
    Darwin*)
        ../configure \
            $CONFIGURE_ARGS \
            --prefix=$(realpath ../build-out)

        make
        make install

        cp include/config_auto.h ../build-out/

        cd ..
        ./macos_link.sh
        cd -

        cd ..
        sed '4i\
TESSERACT_DIR=$(dirname $SCRIPT_DIR)
' download_tessdata.sh > build-out/bin/download_tessdata.sh
        chmod +x build-out/bin/download_tessdata.sh
        ;;
    *)
        echo "Unsupported platform: $(uname -s)"
        exit 1
        ;;
esac
