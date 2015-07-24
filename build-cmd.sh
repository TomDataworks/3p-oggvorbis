#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

OGG_VERSION=1.3.2
OGG_SOURCE_DIR="libogg"
VORBIS_VERSION=1.3.5
VORBIS_SOURCE_DIR="libvorbis"

# load autbuild provided shell functions and variables
eval "$("$AUTOBUILD" source_environment)"

top="$(pwd)"
stage="$(pwd)/stage"

echo "${OGG_VERSION}-${VORBIS_VERSION}" > "${stage}/VERSION.txt"

case "$AUTOBUILD_PLATFORM" in
    "windows")
        pushd "$OGG_SOURCE_DIR"

        packages="$(cygpath -m "$stage/packages")"

        build_sln "win32/ogg.sln" "Debug" "Win32" "ogg_static"
        build_sln "win32/ogg.sln" "Release" "Win32" "ogg_static"

        mkdir -p "$stage/lib"/{debug,release}
        cp "win32/Static_Debug/ogg_static_d.lib" "$stage/lib/debug/ogg_static_d.lib"
        cp "win32/Static_Release/ogg_static.lib" "$stage/lib/release/ogg_static.lib"

        mkdir -p "$stage/include"
        cp -a "include/ogg/" "$stage/include/"
        
        popd
        pushd "$VORBIS_SOURCE_DIR"
        
        build_sln "win32/vorbis.sln" "Debug" "Win32" "vorbis_static"
        build_sln "win32/vorbis.sln" "Release" "Win32" "vorbis_static"
        build_sln "win32/vorbis.sln" "Debug" "Win32" "vorbisenc_static"
        build_sln "win32/vorbis.sln" "Release" "Win32" "vorbisenc_static"
        build_sln "win32/vorbis.sln" "Debug" "Win32" "vorbisfile_static"
        build_sln "win32/vorbis.sln" "Release" "Win32" "vorbisfile_static"
        
        cp "win32/Vorbis_Static_Debug/vorbis_static_d.lib" "$stage/lib/debug/vorbis_static_d.lib"
        cp "win32/Vorbis_Static_Release/vorbis_static.lib" "$stage/lib/release/vorbis_static.lib"
        cp "win32/VorbisEnc_Static_Debug/vorbisenc_static_d.lib" "$stage/lib/debug/vorbisenc_static_d.lib"
        cp "win32/VorbisEnc_Static_Release/vorbisenc_static.lib" "$stage/lib/release/vorbisenc_static.lib"
        cp "win32/VorbisFile_Static_Debug/vorbisfile_static_d.lib" "$stage/lib/debug/vorbisfile_static_d.lib"
        cp "win32/VorbisFile_Static_Release/vorbisfile_static.lib" "$stage/lib/release/vorbisfile_static.lib"
        cp -a "include/vorbis/" "$stage/include/"
        popd
    ;;
    "windows64")
        pushd "$OGG_SOURCE_DIR"

        packages="$(cygpath -m "$stage/packages")"

        build_sln "win32/ogg.sln" "Debug" "x64" "ogg_static"
        build_sln "win32/ogg.sln" "Release" "x64" "ogg_static"

        mkdir -p "$stage/lib"/{debug,release}
        cp "win32/Static_Debug/ogg_static_d.lib" "$stage/lib/debug/ogg_static_d.lib"
        cp "win32/Static_Release/ogg_static.lib" "$stage/lib/release/ogg_static.lib"

        mkdir -p "$stage/include"
        cp -a "include/ogg/" "$stage/include/"
        
        popd
        pushd "$VORBIS_SOURCE_DIR"
        
        build_sln "win32/vorbis.sln" "Debug" "x64" "vorbis_static"
        build_sln "win32/vorbis.sln" "Release" "x64" "vorbis_static"
        build_sln "win32/vorbis.sln" "Debug" "x64" "vorbisenc_static"
        build_sln "win32/vorbis.sln" "Release" "x64" "vorbisenc_static"
        build_sln "win32/vorbis.sln" "Debug" "x64" "vorbisfile_static"
        build_sln "win32/vorbis.sln" "Release" "x64" "vorbisfile_static"
        
        cp "win32/Vorbis_Static_Debug/vorbis_static_d.lib" "$stage/lib/debug/vorbis_static_d.lib"
        cp "win32/Vorbis_Static_Release/vorbis_static.lib" "$stage/lib/release/vorbis_static.lib"
        cp "win32/VorbisEnc_Static_Debug/vorbisenc_static_d.lib" "$stage/lib/debug/vorbisenc_static_d.lib"
        cp "win32/VorbisEnc_Static_Release/vorbisenc_static.lib" "$stage/lib/release/vorbisenc_static.lib"
        cp "win32/VorbisFile_Static_Debug/vorbisfile_static_d.lib" "$stage/lib/debug/vorbisfile_static_d.lib"
        cp "win32/VorbisFile_Static_Release/vorbisfile_static.lib" "$stage/lib/release/vorbisfile_static.lib"
        cp -a "include/vorbis/" "$stage/include/"
        popd
    ;;
    "darwin")
        DEVELOPER=$(xcode-select --print-path)
        opts="-arch x86_64 -iwithsysroot ${DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.10.sdk -mmacosx-version-min=10.8"
        export CFLAGS="$opts"
        export CPPFLAGS="$opts"
        export LDFLAGS="$opts"
        pushd "$OGG_SOURCE_DIR"
        ./configure --prefix="$stage" --enable-shared=no --enable-static=yes
        make
        make install
        popd
        
        pushd "$VORBIS_SOURCE_DIR"
        ./configure --prefix="$stage" --enable-shared=no --enable-static=yes \
			--with-ogg-libraries="${stage}/lib" --with-ogg-includes="${stage}/include"
        make
        make install
        popd
        
        mv "$stage/lib" "$stage/release"
        mkdir -p "$stage/lib"
        mv "$stage/release" "$stage/lib"
     ;;
    "linux")
        # Linux build environment at Linden comes pre-polluted with stuff that can
        # seriously damage 3rd-party builds.  Environmental garbage you can expect
        # includes:
        #
        #    DISTCC_POTENTIAL_HOSTS     arch           root        CXXFLAGS
        #    DISTCC_LOCATION            top            branch      CC
        #    DISTCC_HOSTS               build_name     suffix      CXX
        #    LSDISTCC_ARGS              repo           prefix      CFLAGS
        #    cxx_version                AUTOBUILD      SIGN        CPPFLAGS
        #
        # So, clear out bits that shouldn't affect our configure-directed build
        # but which do nonetheless.
        #
        # unset DISTCC_HOSTS CC CXX CFLAGS CPPFLAGS CXXFLAGS

        # Prefer gcc-4.8 if available.
        if [[ -x /usr/bin/gcc-4.8 && -x /usr/bin/g++-4.8 ]]; then
            export CC=/usr/bin/gcc-4.8
            export CXX=/usr/bin/g++-4.8
        fi

        # Default target to 32-bit
        opts="${TARGET_OPTS:--m32}"
        JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
        HARDENED="-fstack-protector-strong -D_FORTIFY_SOURCE=2"

        # Handle any deliberate platform targeting
        if [ -z "$TARGET_CPPFLAGS" ]; then
            # Remove sysroot contamination from build environment
            unset CPPFLAGS
        else
            # Incorporate special pre-processing flags
            export CPPFLAGS="$TARGET_CPPFLAGS"
        fi

        pushd "$OGG_SOURCE_DIR"

        CFLAGS="$opts -Og -g -fno-fast-math" \
        CXXFLAGS="$opts -Og -g -fno-fast-math -std=c++11" \
        ./configure --with-pic --prefix="$stage" --libdir="$stage/lib/debug"
        make -j$JOBS
        make install

        # conditionally run unit tests
        if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
            make check
        fi

        make distclean

        CFLAGS="$opts -O3 -g $HARDENED" \
        CXXFLAGS="$opts -O3 -g -std=c++11 $HARDENED" \
        ./configure --with-pic --prefix="$stage" --libdir="$stage/lib/release"
        make -j$JOBS
        make install

        # conditionally run unit tests
        if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
            make check
        fi

        make distclean
        popd
        
        pushd "$VORBIS_SOURCE_DIR"

        CFLAGS="$opts -Og -g -fno-fast-math" \
        CXXFLAGS="$opts -Og -g -fno-fast-math -std=c++11" \
        LDFLAGS="-L$stage/lib/debug" \
        ./configure --with-pic --prefix="$stage" --libdir="$stage/lib/debug"
        make -j$JOBS
        make install

        # conditionally run unit tests
        if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
            make check
        fi

        make distclean

        CFLAGS="$opts -O3 -g $HARDENED" \
        CXXFLAGS="$opts -O3 -g -std=c++11 $HARDENED" \
        LDFLAGS="-L$stage/lib/release" \
        ./configure --with-pic --prefix="$stage" --libdir="$stage/lib/release"
        make -j$JOBS
        make install

        # conditionally run unit tests
        if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
            make check
        fi

        make distclean
        popd
    ;;
    "linux64")
        # Linux build environment at Linden comes pre-polluted with stuff that can
        # seriously damage 3rd-party builds.  Environmental garbage you can expect
        # includes:
        #
        #    DISTCC_POTENTIAL_HOSTS     arch           root        CXXFLAGS
        #    DISTCC_LOCATION            top            branch      CC
        #    DISTCC_HOSTS               build_name     suffix      CXX
        #    LSDISTCC_ARGS              repo           prefix      CFLAGS
        #    cxx_version                AUTOBUILD      SIGN        CPPFLAGS
        #
        # So, clear out bits that shouldn't affect our configure-directed build
        # but which do nonetheless.
        #
        # unset DISTCC_HOSTS CC CXX CFLAGS CPPFLAGS CXXFLAGS

        # Prefer gcc-4.8 if available.
        if [[ -x /usr/bin/gcc-4.8 && -x /usr/bin/g++-4.8 ]]; then
            export CC=/usr/bin/gcc-4.8
            export CXX=/usr/bin/g++-4.8
        fi

        # Default target to 64-bit
        opts="${TARGET_OPTS:--m64}"
        JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
        HARDENED="-fstack-protector-strong -D_FORTIFY_SOURCE=2"

        # Handle any deliberate platform targeting
        if [ -z "$TARGET_CPPFLAGS" ]; then
            # Remove sysroot contamination from build environment
            unset CPPFLAGS
        else
            # Incorporate special pre-processing flags
            export CPPFLAGS="$TARGET_CPPFLAGS"
        fi

        pushd "$OGG_SOURCE_DIR"

        CFLAGS="$opts -Og -g -fno-fast-math" \
        CXXFLAGS="$opts -Og -g -fno-fast-math -std=c++11" \
        ./configure --with-pic --prefix="$stage" --libdir="$stage/lib/debug"
        make -j$JOBS
        make install

        # conditionally run unit tests
        if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
            make check
        fi

        make distclean

        CFLAGS="$opts -O3 -g $HARDENED" \
        CXXFLAGS="$opts -O3 -g -std=c++11 $HARDENED" \
        ./configure --with-pic --prefix="$stage" --libdir="$stage/lib/release"
        make -j$JOBS
        make install

        # conditionally run unit tests
        if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
            make check
        fi

        make distclean

        popd
        
        pushd "$VORBIS_SOURCE_DIR"

        CFLAGS="$opts -Og -g -fno-fast-math" \
        CXXFLAGS="$opts -Og -g -fno-fast-math -std=c++11" \
        LDFLAGS="-L$stage/lib/debug" \
        ./configure --with-pic --prefix="$stage" --libdir="$stage/lib/debug"
        make -j$JOBS
        make install

        # conditionally run unit tests
        if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
            make check
        fi

        make distclean

        CFLAGS="$opts -O3 -g $HARDENED" \
        CXXFLAGS="$opts -O3 -g -std=c++11 $HARDENED" \
        LDFLAGS="-L$stage/lib/release" \
        ./configure --with-pic --prefix="$stage" --libdir="$stage/lib/release"
        make -j$JOBS
        make install

        # conditionally run unit tests
        if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
            make check
        fi

        make distclean
        popd
    ;;
esac
mkdir -p "$stage/LICENSES"
pushd "$OGG_SOURCE_DIR"
    cp COPYING "$stage/LICENSES/ogg-vorbis.txt"
popd

pass

