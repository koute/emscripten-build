#!/usr/bin/false
# This build script is based on the PKGBUILD from Arch Linux.

EMSCRIPTEN_URL="https://github.com/kripken/emscripten/archive/$VERSION.tar.gz"
EMSCRIPTEN_FASTCOMP_URL="https://github.com/kripken/emscripten-fastcomp/archive/$VERSION.tar.gz"
EMSCRIPTEN_FASTCOMP_CLANG_URL="https://github.com/kripken/emscripten-fastcomp-clang/archive/$VERSION.tar.gz"

rm -Rf emscripten-build
mkdir emscripten-build
pushd emscripten-build

##
# Download and unpacking
##

curl -Lo emscripten-$VERSION.tgz $EMSCRIPTEN_URL
curl -Lo emscripten_fastcomp-$VERSION.tgz $EMSCRIPTEN_FASTCOMP_URL
curl -Lo emscripten_fastcomp_clang-$VERSION.tgz $EMSCRIPTEN_FASTCOMP_CLANG_URL

sha256sum -c ../CHECKSUMS

tar -xf emscripten-$VERSION.tgz
tar -xf emscripten_fastcomp-$VERSION.tgz
tar -xf emscripten_fastcomp_clang-$VERSION.tgz

mv "emscripten-$VERSION" emscripten
mv "emscripten-fastcomp-$VERSION" emscripten-fastcomp
mv "emscripten-fastcomp-clang-$VERSION" emscripten-fastcomp-clang

##
# Patches
##

pushd emscripten-fastcomp
ln -s ../../emscripten-fastcomp-clang tools/clang
popd # emscripten-fastcomp

pushd emscripten
sed '1s|python$|python2|' -i $(find third_party tools -name \*.py) emrun
popd # emscripten

##
# Build
##

pushd emscripten-fastcomp
mkdir -p build
pushd build

cmake .. \
    -DPYTHON_EXECUTABLE=/usr/bin/python2 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SKIP_RPATH=YES \
    -DCMAKE_C_FLAGS="$EXTRA_CFLAGS" \
    -DCMAKE_CXX_FLAGS="$EXTRA_CFLAGS" \
    -DLLVM_TARGETS_TO_BUILD="X86;JSBackend" \
    -DLLVM_BUILD_RUNTIME=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DCLANG_INCLUDE_TESTS=OFF

make -j 3

popd # build
popd # emscripten-fastcomp

##
# Package creation
##

mkdir destdir
mkdir destdir/emscripten-fastcomp
cp -rup emscripten-fastcomp/build/bin/* destdir/emscripten-fastcomp
chmod 0755 destdir/emscripten-fastcomp/*
strip destdir/emscripten-fastcomp/* || true
install -m644 emscripten-fastcomp/emscripten-version.txt destdir/emscripten-fastcomp/emscripten-version.txt
rm destdir/emscripten-fastcomp/{*-test,llvm-lit}

install -d destdir/emscripten
cp -rup \
    emscripten/em* \
    emscripten/cmake \
    emscripten/src \
    emscripten/system \
    emscripten/third_party \
    emscripten/tools \
    destdir/emscripten

install -m644 emscripten/LICENSE destdir

pushd destdir
rm -f ../../$OUTPUT
tar -zcf ../../$OUTPUT *
popd # destdir

##
# Cleanup
##

popd # emscripten-build
