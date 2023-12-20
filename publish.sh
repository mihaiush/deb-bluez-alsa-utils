#!/bin/bash -e

cd ../github-debian

git pull

rm -fv dists/testing/main/binary-all/{bluez-alsa-utils,libasound2-plugin-bluez}_*
cp -v ../deb-bluez-alsa-utils/out/*.deb dists/testing/main/binary-all/

./make-repo.sh

git add .
git commit -a -m 'Update bluez-alsa'
git push

