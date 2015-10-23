# First invoked by sdcard/write
mountpartitions(){
	# Partition the sd card
	case $MACHINENAME in
		rpi|rpi-2|parallella)
			generalformat 100;; # Make 100 MB fat partition for the RPi
		cubietruck)
			cubieformat;; # Mount the cubie
		*)
			exit;;
	esac
}

# Invoked by sdcard/write
initos(){
	case $MACHINENAME in
		rpi|rpi-2|parallella)
			generaldownload;;
		cubietruck)
			cubiedownload;;
		*)
			exit;;
	esac
}


## ------------------------- PARTITION AND DOWNLOAD THE OS --------------------------------

# Format the SD Card with two partitions, boot and root. Boot is $1 MB big.
# This makes the root partition as big as the sd card minus boot
generalformat(){
	# Here we "press" the keys in order, commanding fdisk to make a partition
	echo "Now $SDCARD is going to be partitioned"
	fdisk $SDCARD <<EOF
o
p
n
p
1

+${1}M
t
c
n
p
2


w
EOF

	# Require mkfs.vfat
	require mkfs.vfat dosfstools

	# Make boot filesystem
	mkfs.vfat $PARTITION1 

	# Mount partition 1 to boot, for editing
	mount $PARTITION1 $BOOT

	# Make root filesystem, answer y to if we want to overwrite the ext4 partition
	mkfs.ext4 $PARTITION2 <<EOF
y
EOF

	# Mount partition 2 to root, for editing
	mount $PARTITION2 $ROOT
}


# Download the OS, and redirect the tar warnings to the log
generaldownload(){
	# Download
	curl -sSL -k http://archlinuxarm.org/os/ArchLinuxARM-${MACHINENAME}-latest.tar.gz | tar -xz -C $ROOT >> $LOGFILE

	sync

	# Move /boot to separate partition
	mv $ROOT/boot/* $BOOT
}



# Cubietruck guide: http://archlinuxarm.org/platforms/armv7/allwinner/cubietruck
# All the commands copied from there
cubieformat(){
	fdisk $SDCARD <<EOF
o
p
n
p
1
2048

w
EOF

	mkfs.ext4 $PARTITION2 <<EOF
y
EOF
	# Mount partition 2 to root, for editing
	mount $PARTITION2 $ROOT
}

cubiedownload(){
	curl -sSL -k http://archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz | tar -xz -C $ROOT >> $LOGFILE

	sync

	wget http://archlinuxarm.org/os/sunxi/boot/cubietruck/u-boot-sunxi-with-spl.bin

	dd if=u-boot-sunxi-with-spl.bin of=$SDCARD bs=1024 seek=8

	wget http://archlinuxarm.org/os/sunxi/boot/cubietruck/boot.scr -O $ROOT/boot/boot.scr
}