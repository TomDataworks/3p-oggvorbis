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

OGG_VERSION=1.1.3
OGG_SOURCE_DIR="libogg-$OGG_VERSION"

# load autbuild provided shell functions and variables
eval "$("$AUTOBUILD" source_environment)"

top="$(pwd)"
stage="$(pwd)/stage"

pushd "$OGG_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        "windows")
            packages="$(cygpath -m "$stage/packages")"
            load_vsvars

			#devenv.com /Upgrade "win32/ogg.dsw"

			build_sln "win32/ogg.dsw" "Debug|Win32"
            build_sln "win32/ogg.dsw" "Release|Win32"

            mkdir -p "$stage/lib"/{debug,release}
            cp "win32/Static_Debug/ogg_static_d.lib" "$stage/lib/debug/ogg_static_d.lib"
            cp "win32/Static_Debug/vc100.pdb" "$stage/lib/debug/ogg_static_d.pdb"
            cp "win32/Static_Release/ogg_static.lib" "$stage/lib/release/ogg_static.lib"
            cp "win32/Static_Release/vc100.pdb" "$stage/lib/release/ogg_static.pdb"

            mkdir -p "$stage/include"
            cp -a "include/ogg/" "$stage/include/"
        ;;
        "darwin")
            # TODO: this produces a package that actually will create link errors when building the viewer. Notes:
            # - Try to compile and link against our own OpenSSL (right now though, openssl-autobuild does not build for Mac)
            # - May be same thing for zlib
            # - Disabling ldap suppresses half of the link errors so that's something to keep
            opts='-arch i386 -iwithsysroot /Developer/SDKs/MacOSX10.4u.sdk'
            CFLAGS="$opts" CXXFLAGS="$opts" ./configure  --disable-ldap --disable-ldaps --with-ssl --prefix="$stage"
            make
            make install
            mkdir -p "$stage/lib/release"
            cp "$stage/lib/libogg.a" "$stage/lib/release"
        ;;
        "linux")
            # TODO: see darwin notes here above
            CFLAGS=-m32 CXXFLAGS=-m32 ./configure --disable-ldap --disable-ldaps --with-ssl --prefix="$stage"
            make
            make install
            mkdir -p "$stage/lib/release"
            cp "$stage/lib/libogg.a" "$stage/lib/release"
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp COPYING "$stage/LICENSES/ogg-vorbis.txt"
popd

pass

