
os_install(){

	# Update the system and use pacman to install all the packages
	# The two commands may be combined, but I leave it as is for now.
	os_upgrade

	if [[ -z $STATICALLY_DOCKER ]]; then

		if [[ $MACHINE == "rpi" ]]; then
			pacman -S docker git --noconfirm --needed
		else
			# for armv7
			# Install this manually, docker v1.7.1
			pacman -S bridge-utils iproute2 device-mapper sqlite git --noconfirm --needed
			curl -sSL https://s3.amazonaws.com/docker-armv7/docker-1:1.7.1-2-armv7h.pkg.tar.xz > /var/cache/pacman/pkg/docker-1:1.7.1-2-armv7h.pkg.tar.xz
			pacman -U  /var/cache/pacman/pkg/docker-1:1.7.1-2-armv7h.pkg.tar.xz --noconfirm
		fi
	else
		# Install git
		pacman -S git --noconfirm --needed

		# Download docker daemon
		curl -sSL $STATIC_DOCKER_DOWNLOAD > /usr/bin/docker

		# Enable the service files
		mv /usr/lib/systemd/system/docker.service{.backup,}
		mv /usr/lib/systemd/system/docker.socket{.backup,}

		systemctl daemon-reload
	fi
	# Add more commands here, archlinux specific
}


os_upgrade(){
	pacman -Syu --noconfirm
}

os_post_install(){

	systemctl stop system-docker docker

	# Only set if its specified
	if [[ -z $NEW_HOSTNAME ]]; then
		read -p "What hostname do you want? Defaults to $DEFAULT_HOSTNAME. " hostnameanswer

		# Defaults to kubepi
		if [[ -z $hostnameanswer ]]; then
			hostnamectl set-hostname $DEFAULT_HOSTNAME
		else
			hostnamectl set-hostname $hostnameanswer
		fi
		
	else
		hostnamectl set-hostname $NEW_HOSTNAME
	fi

	# Set timezone
	if [[ -z $TIMEZONE ]]; then
		read -p "Which timezone should be set? Defaults to $DEFAULT_TIMEZONE. " timezoneanswer

		# Defaults to Helsinki
		if [[ -z $timezoneanswer ]]; then
			timedatectl set-timezone $DEFAULT_TIMEZONE
		else
			timedatectl set-timezone $timezoneanswer
		fi
		
	else
		timedatectl set-timezone $TIMEZONE
	fi
}