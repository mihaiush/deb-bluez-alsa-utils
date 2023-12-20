#!/bin/bash -e

cd $(dirname $0)

. config

if [[ ! -f /.dockerenv ]] && [[ ! -f /run/.containerenv ]] ; then
    (podman kill deb_build && sleep 2) || true
    podman run -ti --rm --name deb_build --mount type=bind,source="$(pwd)",target=/work -w /work debian_build:${DIST}-slim ./build.sh 
    exit
fi

mkdir -p out
rm -rf out/*

export EMAIL="Mihai Craiu <mihaiush@gmail.com>"

cp /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian-src.sources
sed -ri 's/Types: deb/Types: deb-src/g' /etc/apt/sources.list.d/debian-src.sources
apt-get update

cd /tmp
apt-get source bluez-alsa-utils

cd bluez-alsa-*

# AAC
sed -ri 's/dh_auto_configure --/dh_auto_configure -- --enable-aac/' debian/rules
sed -ri 's/^Build-Depends: /Build-Depends: libfdk-aac-dev, /g' debian/control

# APTX
sed -ri 's/dh_auto_configure --/dh_auto_configure -- --enable-aptx --enable-aptx-hd --with-libopenaptx/' debian/rules
sed -ri 's/^Build-Depends: /Build-Depends: libopenaptx-dev, /g' debian/control

dch -i "Enable extra codecs"
dch -r ""
echo | mk-build-deps -i
debuild -uc -us -b

cd /work
cp -v /tmp/*.deb out/
rm -f out/*dbgsym*
cp config out/
chown --reference=README.md -R out

