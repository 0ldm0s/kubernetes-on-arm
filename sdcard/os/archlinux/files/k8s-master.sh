#!/bin/bash

# Compile binaries and docker images

# Catch errors
trap 'exit' ERR


#echo "Again, check how much free space we have on our system, for later comparision"
#df -h

# Now we are in the current dir
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Eventually get k8s/etcd to docker via pull



# Get etcd container hash
#ETCD=$(system-docker run -d --net=host k8s/etcd)

# etcdctl and kubelet should be present on every 

# Set flannel subnet
#system-docker run --rm --net=host k8s/etcd etcdctl set /coreos.com/network/config '{ "Network": "10.1.0.0/16" }'

# Stop docker


# Start flannel
#FLANNEL=$(system-docker run -d --net=host --privileged -v /dev/net:/dev/net k8s/flannel /flanneld)

# Get the settings
#system-docker cp $FLANNEL:/run/flannel/subnet.env .

# Source those settings
#source subnet.env



cat > /usr/lib/systemd/system/etcd.service <<EOF
[Unit]
Description=Etcd Master Data Store for Kubernetes Apiserver
After=system-docker.service

[Service]
ExecStartPre=-/usr/bin/docker -H unix:///var/run/system-docker.sock kill etcd-k8s
ExecStartPre=-/usr/bin/docker -H unix:///var/run/system-docker.sock rm etcd-k8s
ExecStartPre=-/usr/bin/mkdir -p /var/etcd/data
ExecStart=/usr/bin/docker -H unix:///var/run/system-docker.sock run --net=host --name=etcd-k8s -v /var/etcd/data:/var/etcd/data k8s/etcd
ExecStartPost=/usr/bin/docker -H unix:///var/run/system-docker.sock run --rm --net=host k8s/etcd etcdctl set /coreos.com/network/config '{ "Network": "10.1.0.0/16" }'
ExecStop=/usr/bin/docker -H unix:///var/run/system-docker.sock stop etcd-k8s

[Install]
WantedBy=multi-user.target
EOF

cat > /usr/lib/systemd/system/flannel.service <<EOF
[Unit]
Description=Flannel Overlay Network for Kubernetes
After=etcd.service

[Service]
ExecStartPre=-/usr/bin/docker -H unix:///var/run/system-docker.sock kill flannel-k8s
ExecStartPre=-/usr/bin/docker -H unix:///var/run/system-docker.sock rm flannel-k8s
ExecStartPre=-/usr/bin/rm -rf /var/lib/flannel
ExecStartPre=-/usr/bin/mkdir -p /var/lib/flannel
ExecStart=/usr/bin/docker -H unix:///var/run/system-docker.sock run --name=flannel-k8s --net=host --privileged -v /dev/net:/dev/net k8s/flannel /flanneld)
ExecStartPost=/usr/bin/docker -H unix:///var/run/system-docker.sock cp flannel-k8s:/run/flannel/subnet.env /var/lib/flannel
ExecStop=/usr/bin/docker -H unix:///var/run/system-docker.sock stop flannel-k8s

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/docker.service.d/luxcloud.conf <<EOF
[Unit]
After=system-docker.service flannel.service

[Service]
EnvironmentFile=/var/lib/flannel/subnet.env
ExecStart=
ExecStart=/usr/bin/docker -d -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375 -s overlay --bip=$FLANNEL_SUBNET --mtu=$FLANNEL_MTU --insecure-registry=localhost:5000
EOF


cat > /usr/lib/systemd/system/master-k8s.service <<EOF
[Unit]
Description=The Master Components for Kubernetes
After=docker.service

[Service]
ExecStartPre=-/usr/bin/docker kill master-k8s
ExecStartPre=-/usr/bin/docker rm master-k8s
ExecStart=/usr/bin/docker run --name=master-k8s --net=host  -v /var/run/docker.sock:/var/run/docker.sock  k8s/hyperkube /hyperkube kubelet --pod_infra_container_image="k8s/pause" --api-servers=http://localhost:8080 --v=2 --address=0.0.0.0 --enable-server --hostname-override=$(/usr/bin/hostname -i | /usr/bin/awk '{print $1}') --config=/etc/kubernetes/manifests-multi
ExecStop=/usr/bin/docker stop master-k8s

[Install]
WantedBy=multi-user.target
EOF

cat > /usr/lib/systemd/system/registry.service <<EOF
[Unit]
Description=The Docker Image Registry
After=docker.service

[Service]
ExecStartPre=-/usr/bin/docker kill registry
ExecStartPre=-/usr/bin/docker rm registry
ExecStartPre=-/usr/bin/mkdir -p /var/lib/registry
ExecStart=/usr/bin/docker run --name=registry --net=host -v /var/lib/registry:/var/lib/registry luxas/registry
ExecStop=/usr/bin/docker stop registry

[Install]
WantedBy=multi-user.target
EOF

# Modify docker settings
#sed -e "s@-s overlay@-s overlay --bip=$FLANNEL_SUBNET --mtu=$FLANNEL_MTU@" -i /usr/lib/systemd/system/docker.service


# Load the images which is necessary
docker save k8s/etcd | system-docker load
docker save k8s/flannel | system-docker load

systemctl stop docker.service docker.socket

# Bring the docker bridge down
ifconfig docker0 down

# And delete it
brctl delbr docker0

# Reload systemd
systemctl daemon-reload

# Start it again
systemctl enable flannel etcd master-k8s registry
systemctl start etcd flannel docker master-k8s registry


# Start k8s master components, is working
#docker run -d --net=host  -v /var/run/docker.sock:/var/run/docker.sock  k8s/hyperkube /hyperkube kubelet --pod_infra_container_image="k8s/pause" --api-servers=http://localhost:8080 --v=2 --address=0.0.0.0 --enable-server --hostname-override=$(hostname -i | awk '{print $1}') --config=/etc/kubernetes/manifests-multi


# OK, Now the k8s cluster should be ready



#docker run -d --net=host -v /var/run/docker.sock:/var/run/docker.sock  k8s/hyperkube /hyperkube kubelet --pod_infra_container_image="k8s/pause" --api-servers=http://${MASTER_IP}:8080 --v=2 --address=127.0.0.1 --enable-server --hostname-override=$(hostname -i | awk '{print $1}')

#docker run -d --net=host --privileged k8s/hyperkube /hyperkube proxy --master=http://127.0.0.1:8080 --v=2



## THIS IS K8S HEAD SINGLE NODE
#docker run -d --net=host -v=/:/rootfs:ro -v=/sys:/sys:ro -v=/dev:/dev -v=/var/lib/docker/:/var/lib/docker:rw -v=/var/lib/kubelet/:/var/lib/kubelet:rw -v=/var/run:/var/run:rw --privileged=true k8s/hyperkube /hyperkube kubelet --containerized --pod_infra_container_image="k8s/pause" --hostname-override="test" --address="0.0.0.0" --api-servers=http://localhost:8080 --config=/etc/kubernetes/manifests-multi