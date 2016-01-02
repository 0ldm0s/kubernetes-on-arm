os_install(){

	# Upgrade the system packages
	os_upgrade
	
	# Here docker have to be installed
	# Download docker daemon if docker doesn't exist
	if [[ ! -f $(which docker 2>&1) ]]; then
		curl -sSL $STATIC_DOCKER_DOWNLOAD > /usr/bin/docker
		chmod +x /usr/bin/docker

		# Enable the service files
		mv /usr/lib/systemd/system/docker.service{.backup,}
		mv /usr/lib/systemd/system/docker.socket{.backup,}

	# If docker is installed at another place than default, symlink
	elif [[ $(which docker) != "/usr/bin/docker" ]]; then
		
		ln -s $(which docker) /usr/bin/docker
	fi

	# If the docker group doesn't exist, make it
	if [[ -z $(grep docker /etc/group) ]]; then
		# Add the docker group, so the daemon starts
		groupadd docker
	fi
	
	# Ensure systemctl has the latest files in memory
	systemctl daemon-reload

	# If the raspi-config command exists, expand filesystem automatically
	if [[ -f $(which raspi-config 2>&1) ]]; then

		echo "Expanding the rootfs with raspi-config..."
		raspi-config --expand-rootfs
	fi

	# If brctl isn't installed, notify the user
	if [[ ! -f $(which brctl 2>&1) ]]; then

		# Install automatically if apt-get is present
		if [[ -f $(which apt-get 2>&1) ]]; then
			apt-get install bridge-utils -y
		else
			echo "WARNING: brctl is required for Kubernetes to function. Install it if you want Kubernetes to function properly."
		fi
	fi

	# If the dhclient config doesn't exist, notify the user
	if [[ ! -f /etc/dhcp/dhclient.conf ]]; then
		cat <<EOF
WARNING: You have to include these statements in your /etc/resolv.conf file if you want Kubernetes DNS to work on the host machine, not only in pods
/etc/resolv.conf
--------------------
nameserver $DNS_IP
search default.svc.$DNS_DOMAIN svc.$DNS_DOMAIN $DNS_DOMAIN
--------------------
EOF
	fi

	# If apt-get is there, use it
	if [[ -f $(which apt-get 2>&1) && -f $(which git 2>&1) ]]; then
		echo "Installing git..."
		apt-get install -y git
	else
		echo "WARNING: It's recommended to have git installed. Please install it via your package manager."
	fi
}


os_upgrade(){
	# If apt-get is there, use it
	if [[ -f $(which apt-get 2>&1) ]]; then
		echo "Updating your system"
		apt-get update -y && apt-get upgrade -y
	else
		echo "Don't know which package manager you are using. Upgrade the packages yourself..."
	fi
}

os_addon_dns(){

	# Only edit the DNS config if the file exists
	if [[ -f /etc/dhcp/dhclient.conf ]]; then

		# Write the DNS options to the file
		updatefile /etc/dhcp/dhclient.conf "prepend domain-search" "prepend domain-search \"default.svc.$DNS_DOMAIN\",\"svc.$DNS_DOMAIN\",\"$DNS_DOMAIN\";"
		updatefile /etc/dhcp/dhclient.conf "prepend domain-name-servers" "prepend domain-name-servers $DNS_IP;"

		# If we are using /etc/init.d/networking, restart it
		if [[ $(systemctl is-active networking) == "active" ]]; then
			systemctl restart networking
		elif [[ $(systemctl is-active systemd-networkd) == "active" ]]; then
			systemctl restart systemd-networkd
		else
			echo "WARNING: You have to restart your networking daemon for DNS changes to take effect and flush changes to /etc/resolv.conf"
		fi
	fi

}