#!/bin/bash

# This script is going to set up lucas amazing Raspberry Pi cloud service!
# This round is the Kubernetes round.
# We'll set up kubernetes common parts (used for both master and minion)
#
#
#
#
#
#
#
#
#


trap 'exit' ERR


echo "Again, check how much free space we have on our system, for later comparision"
df -h

echo "Install compilation tools"
pacman -S gcc make patch screen linux-raspberrypi-headers --noconfirm



#### INSTALL GO, WHICH WILL POWER EVERYTHING ####

cd /
cd /lib/luxas

echo "Download go"
git clone https://go.googlesource.com/go
cd go

echo "Don't know why but i use go 1.4 anyway"
git checkout go1.4.1

cd src
./make.bash




## CHANGE THE PATH ##
# Should it be better to create a symlink?

echo "Add go binaries to PATH"
sed -e 's@PATH="@PATH="/lib/luxas/go/bin:@' -i /etc/profile

echo "Update our current PATH"
export PATH="$PATH:/lib/luxas/go/bin"

echo "Make GOPATH"
mkdir /lib/luxas/gopath

cat >> /etc/profile <<EOF

GOPATH="/lib/luxas/gopath"
export GOPATH
EOF

export GOPATH="/lib/luxas/gopath"

# To compile go took about 10 mins




## ETCD ##


echo "Time to hack with etcd, not always fun :)"

cd /lib/luxas

echo "Downloading etcd version 2.0.4"
git clone https://github.com/coreos/etcd.git

echo "Build etcd binaries"
cd etcd

git checkout v2.0.4

# Apply some 32-bit patches
curl https://raw.githubusercontent.com/mkaczanowski/docker-archlinux-arm/master/archlinux-etcd/patches/raft.go.patch > raft.go.patch
curl https://raw.githubusercontent.com/mkaczanowski/docker-archlinux-arm/master/archlinux-etcd/patches/server.go.patch > server.go.patch
curl https://raw.githubusercontent.com/mkaczanowski/docker-archlinux-arm/master/archlinux-etcd/patches/watcher_hub.go.patch > watcher_hub.go.patch
patch etcdserver/raft.go < raft.go.patch
patch etcdserver/server.go < server.go.patch
patch store/watcher_hub.go < watcher_hub.go.patch

./build

echo "Make symlinks"
ln -s /lib/luxas/etcd/bin/* /usr/bin

# Etcd working dir
mkdir /var/lib/etcd


# Maybe some more args to etcd how to handle
# Important, no "" around the arguments!
cat > /etc/systemd/system/etcd.service <<EOF
[Unit]
Description=etcd server
After=network.target

[Service]
Type=simple
WorkingDirectory=/var/lib/etcd
ExecStart=/usr/bin/etcd --listen-client-urls=http://0.0.0.0:4001,http://0.0.0.0:2379 --listen-peer-urls=http://localhost:2380,http://localhost:7001 --advertise-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001

[Install]
WantedBy=multi-user.target
EOF

# Etcd took about 2-3 mins to compile


## FLANNEL ##

cd /lib/luxas

git clone https://github.com/coreos/flannel.git

cd flannel

./build


### KUBERNETES ###

echo "Download the awesome kubernetes!"

cd /lib/luxas

git clone https://github.com/GoogleCloudPlatform/kubernetes.git

cd kubernetes


# git checkout [version]


# is it a must to remove sudo -E?
hack/local-up-cluster.sh

# -------->>>>>>>>>>>>> own thread

# Took about 10 min



## WEB SERVER ##
# This could be in a docker container

pacman -S nodejs npm --noconfirm

npm install bower -g

cd www/master

npm install

sed -e 's@bower install"@bower install --allow-root"@' -i package.json

cp shared/config/development.example.json shared/config/development.json

npm start

# ----------->>>>>>>>>>>>>> own thread

npm install -g http-server

# start web server
# cd www/app
# http-server -a 0.0.0.0 -p 8000

# ---------->>>>>>>>>>> own thread