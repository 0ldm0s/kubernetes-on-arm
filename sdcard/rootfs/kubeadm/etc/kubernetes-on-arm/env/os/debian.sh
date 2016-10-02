os_install(){

    # If the raspi-config command exists, expand filesystem automatically
    if [[ -f $(which raspi-config 2>&1) ]]; then

        RASPICONFIG_EXPAND_LOG=$(mktemp /tmp/kube-config-raspi-config-expand-rootfs.XXXXX)
        echo "Expanding the rootfs with raspi-config... Log file: $RASPICONFIG_EXPAND_LOG"
        raspi-config --expand-rootfs 1>$RASPICONFIG_EXPAND_LOG 2>$RASPICONFIG_EXPAND_LOG
    fi

    # Only edit the DNS config if the file exists
    if [[ -f /etc/dhcp/dhclient.conf ]]; then

        # Write the DNS options to the file
        updateline /etc/dhcp/dhclient.conf "prepend domain-search" "prepend domain-search \"default.svc.$DNS_DOMAIN\",\"svc.$DNS_DOMAIN\",\"$DNS_DOMAIN\";"
        updateline /etc/dhcp/dhclient.conf "prepend domain-name-servers" "prepend domain-name-servers $DNS_IP;"

        # If we are using /etc/init.d/networking, restart it
        if [[ $(systemctl is-active networking 2>&1) == "active" ]]; then
            systemctl restart networking
        elif [[ $(systemctl is-active systemd-networkd 2>&1) == "active" ]]; then
            systemctl restart systemd-networkd
        else
            echo "WARNING: You have to restart your networking daemon for DNS changes to take effect and flush changes to /etc/resolv.conf"
        fi
        RESOLVCONF_UPDATED=1
    fi
    if [[ -f /etc/resolvconf.conf ]]; then

        # Write the DNS options to the file
        updateline /etc/resolvconf.conf "search_domains" "search_domains=\"default.svc.$DNS_DOMAIN svc.$DNS_DOMAIN $DNS_DOMAIN\""
        updateline /etc/resolvconf.conf "name_servers" "name_servers=$DNS_IP;"

        # Update resolv.conf 
        resolvconf -u

        RESOLVCONF_UPDATED=1
    if [[ ${RESOLVCONF_UPDATED} != 1 ]]; then
        cat <<-EOF
		WARNING: You have to include these statements in your /etc/resolv.conf file if you want Kubernetes DNS to work on the host machine, not only in pods
		/etc/resolv.conf
		--------------------
		nameserver $DNS_IP
		search default.svc.$DNS_DOMAIN svc.$DNS_DOMAIN $DNS_DOMAIN
		--------------------
		EOF
    fi
}
