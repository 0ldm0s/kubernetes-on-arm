#!/bin/bash

# Require two args
if [[ $# < 2 ]]; then
	cat <<EOF
Create a .deb file of https://github.com/luxas/kubernetes-on-arm

Arguments: 
1: A commit, tag or branch in the repo
2: The package revision. Just a number like 2
EOF
	exit
fi

PACKAGE_GIT_COMMIT=$1
PACKAGE_REVISION=$2
OUT_DIR=${OUT_DIR:-"/build"}

### PART 1: GATHER FILES

cd /kubernetes-on-arm

# First, pull the latest code and use that
git pull origin
git checkout $PACKAGE_GIT_COMMIT

# Export paths required for the dynamic-rootfs script
export PROJROOT=$(pwd)
export ROOT=$(mktemp -d /tmp/make-deb.XXXX)

# Copy kube-systemd source to /tmp
cp -r $PROJROOT/sdcard/rootfs/kube-systemd/* $ROOT

# Source our pre-packaging script
source $ROOT/dynamic-rootfs.sh
cd sdcard

# Invoke the function that customizes the kube-systemd with symlinks and stuff
rootfs

# That file is temporary and do not include env information in the .deb file
rm $ROOT/etc/kubernetes/dynamic-env/env.conf

# Fix that the kubernetes-on-arm folder shouldn't be there
# TODO: make this better in the future
# cp -r $ROOT/etc/kubernetes/source/kubernetes-on-arm/* $ROOT/etc/kubernetes/source
# rm -r $ROOT/etc/kubernetes/source/kubernetes-on-arm


### PART 2: MAKE DEB
# Inspired by: https://github.com/hypriot/rpi-docker-builder/blob/master/builder.sh

# Get uncompressed size and get the $VERSION variable
PACKAGE_SIZE=`du -sk $ROOT | cut -f1`

# Fetch the $VERSION variable
source $PROJROOT/version

# Make control file
mkdir -p $ROOT/DEBIAN
mv /debian-control-file $ROOT/DEBIAN/control

# Replace the dynamic variables
sed -e "s/FILESIZE/$PACKAGE_SIZE/g;s/VERSION/$VERSION/g;s/REVISION/$PACKAGE_REVISION/g;" -i $ROOT/DEBIAN/control

# Generate MD5 checksums
(cd $ROOT; find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' -printf '%P ' | xargs md5sum > DEBIAN/md5sums)

# Make target dir
mkdir -p $OUT_DIR

# The package process
fakeroot dpkg -b $ROOT $OUT_DIR
tar -czf $OUT_DIR/kubernetes-on-arm_${VERSION}-${PACKAGE_REVISION}_armhf.tar.gz $ROOT

# Output info
echo ".deb package size (uncompressed): $PACKAGE_SIZE kByte"
echo "The packages are here:"
ls -l $OUT_DIR/*