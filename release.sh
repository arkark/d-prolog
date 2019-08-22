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

echo -e "\e[36mBuilding $FILE_NAME\e[0m"

mkdir "bin/$FILE_NAME"
dub build -b release --arch=x86_64 --force
cp "bin/dprolog" "bin/$FILE_NAME"
cp -r example "bin/$FILE_NAME/example"

tar cvfz "bin/$FILE_NAME.tar.gz" -C bin "$FILE_NAME"
rm -r "bin/$FILE_NAME"
echo -e "\e[32m-> Succeeded!\e[0m"

if type docker >/dev/null 2>&1; then
    echo -e "\e[36mRunning tokei from mbologna/docker-tokei > docs/LoC.md\e[0m"

    docker image pull mbologna/docker-tokei \
        && docker container run -v $PWD:/data:ro mbologna/docker-tokei tokei \
         | sed -e '1i## Lines of Code\n\n```sh\n$ tokei' -e '$a```' > docs/LoC.md \
        && echo -e "\e[32m-> Succeeded!\e[0m"
fi
