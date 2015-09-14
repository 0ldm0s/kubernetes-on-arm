#!/bin/bash

# Make the build dir
mkdir /build /build/bin
cd /build

# Get version variables
source /version.sh

## ETCD ##

# Determine how to get files
if [ "$ETCD_VERSION" == "latest" ]
then
	# Download via git, this way were always in HEAD and on the master branch
	git clone https://github.com/coreos/etcd.git
else
	# Download a gzipped archive and extract, much faster
	curl -sSL -k https://github.com/coreos/etcd/archive/v$ETCD_VERSION.tar.gz | tar -C /build -xz
	mv etcd* etcd
fi

cd etcd

# Apply some 32-bit patches
curl https://raw.githubusercontent.com/mkaczanowski/docker-archlinux-arm/master/archlinux-etcd/patches/raft.go.patch > raft.go.patch
curl https://raw.githubusercontent.com/mkaczanowski/docker-archlinux-arm/master/archlinux-etcd/patches/server.go.patch > server.go.patch
curl https://raw.githubusercontent.com/mkaczanowski/docker-archlinux-arm/master/archlinux-etcd/patches/watcher_hub.go.patch > watcher_hub.go.patch
patch etcdserver/raft.go < raft.go.patch
patch etcdserver/server.go < server.go.patch
patch store/watcher_hub.go < watcher_hub.go.patch

# Build etcd
./build

# Copy over the binaries
cp bin/* /build/bin

## /ETCD ##


cd /build

## FLANNEL ##

# Determine how to get files
if [ "$FLANNEL_VERSION" == "latest" ]
then
	# Download via git, this way were always in HEAD and on the master branch
	git clone https://github.com/coreos/flannel.git
else
	# Download a gzipped archive and extract, much faster
	curl -sSL -k https://github.com/coreos/flannel/archive/v$FLANNEL_VERSION.tar.gz | tar -C /build -xz
	mv flannel* flannel
fi

cd flannel

# And build
./build

# Copy over the binaries
cp bin/* /build/bin

## /FLANNEL ##

cd /build

### KUBERNETES ###

# Determine how to get files
if [ "$K8S_VERSION" == "latest" ]
then
	# Download via git, this way were always in HEAD and on the master branch
	git clone https://github.com/kubernetes/kubernetes.git
else
	# Download a gzipped archive and extract, much faster
	curl -sSL -k https://github.com/kubernetes/kubernetes/archive/v$K8S_VERSION.tar.gz | tar -C /build -xz
	mv kubernetes* kubernetes
fi

cd kubernetes

## PATCHES


# Do not build these
TOREMOVE=(
	"cmd/kube-proxy"
	"cmd/kube-apiserver"
	"cmd/kube-controller-manager"
	"cmd/kubelet"
	"cmd/linkcheck"
	"cmd/kubernetes"
	"plugin/cmd/kube-scheduler"

	"kube-apiserver"
	"kube-controller-manager"
	"kube-scheduler"

	"cmd/integration"
	"cmd/gendocs"
    "cmd/genman"
    "cmd/mungedocs"
    "cmd/genbashcomp"
    "cmd/genconversion"
    "cmd/gendeepcopy"
    "cmd/genswaggertypedocs"
    "github.com/onsi/ginkgo/ginkgo"
    "test/e2e/e2e.test"
)
  
# Now it should be faster
# Do not build these statically, (or at all btw)

for STR in "${TOREMOVE[@]}"; do
	sed -e "s@ $STR@@" -i hack/lib/golang.sh
done


# Build kubectl statically, instead of hyperkube
sed -e "s@ hyperkube@ kubectl@" -i hack/lib/golang.sh

# Do not build test targets
#sed -e 's@(kube::golang::test_targets)@()@' -i hack/lib/golang.sh
#sed -e 's@(kube::golang::server_targets)@($(echo "cmd/hyperkube"))@' -i hack/lib/golang.sh



# Build kubernetes binaries
./hack/build-go.sh

# Copy over the binaries
cp _output/local/bin/linux/arm/* /build/bin

## PAUSE ##

cd build/pause

# Build the binary
./prepare.sh

# Copy over the binary
cp pause /build/bin