#!/usr/bin/env bash

set -eu -o pipefail

VERSION=$(git describe --abbrev=0 --tags)
ARCH="x86_64"

UNAME_OUT="$(uname -s)"
case "$UNAME_OUT" in
    Linux*) OS=linux ;;
    Darwin*) OS=osx ;;
    *) echo "Unknown OS: $UNAME_OUT"; exit 1
esac

FILE_NAME="dprolog-$VERSION-$OS-$ARCH"

echo "Building $FILE_NAME"

mkdir "bin/$FILE_NAME"
dub build -b release --arch=x86_64 --force
cp "bin/dprolog" "bin/$FILE_NAME"
cp -r example "bin/$FILE_NAME/example"

tar cvfz "bin/$FILE_NAME.tar.gz" -C bin "$FILE_NAME"
rm -r "bin/$FILE_NAME"
