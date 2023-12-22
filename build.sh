#!/bin/bash 

set -e

if [ -z "$1" ] ; then
    echo "$(basename $0) PATCH_SCRIPT"
    exit 2
fi

cd $(dirname $0)

. $1

if [[ ! -f /.dockerenv ]] && [[ ! -f /run/.containerenv ]] ; then
    (podman kill deb_build && sleep 2) || true
    podman run -ti --rm --name deb_build --mount type=bind,source="$(pwd)",target=/work -w /work debian_build:${DIST}-slim ./build.sh $1
    exit
fi

mkdir -p out
rm -rf out/*

export EMAIL="Mihai Craiu <mihaiush@gmail.com>"

# Add "src" repos
cp /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian-src.sources
sed -ri 's/Types: deb/Types: deb-src/g' /etc/apt/sources.list.d/debian-src.sources

apt-get update
apt-get -y dist-upgrade --auto-remove

cd /tmp
apt-get source $SRC

# Autodetect build dir
cd $(find . -name debian -type d | head -1)
cd ..

# From $1
main

dch -i ""
dch -r ""
echo | mk-build-deps -i
debuild -uc -us -b

cd /work
cp -v /tmp/*.deb out/
rm -f out/*dbgsym*
echo 'export DIST='$DIST >>out/config
echo 'export SRC='$SRC >>out/config
chown --reference=README.md -R out

