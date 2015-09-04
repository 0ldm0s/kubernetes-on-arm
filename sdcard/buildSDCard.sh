#!/bin/bash
# buildSDCard.sh [disc] [machine] [distro] [middleware] [middleware-parameter]
# buildSDCard.sh /dev/sdb rpi archlinux -qm luxcloud-master -p pimaster 

# Catch errors
trap 'exit' ERR

########################## SECURITY CHECKS ##############################

# Root is required
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

# At least three arguments should be present
if [ $# < 3 ]; then
	echo "You must specify at least three arguments."
	usage
	exit 1
fi

# Require fdisk to be installed
require fdisk fdisk

# Check that it really is a disk
if [[ -z $(fdisk -l | grep "$1") ]] 
then
	echo "The disc $1 doesn't exist. Compare with 'fdisk -l'"
	exit 1
fi

########################## USAGE ##############################

usage(){
	cat <<EOF
Welcome to buildSDCard!

Required arguments:

./buildSDCard.sh [disc or sd card] [machine] [os]

Additional options:
	-q: Quiet or non-interactive. Do not ask the user for anything
	-m: A middleware to use for copying files to the sd card
	-p: A middleware parameter. Middleware-specific

EOF
}

########################## OPTIONS ##############################

# /dev/sdb, /dev/sdb1, /dev/sdb2
SDCARD=$1
PARTITION1=${1}1
PARTITION2=${1}2

# A tmp dir to store things in, a boot partition and the root filesystem
TMPDIR=/tmp/writesdcard
BOOT=$TMPDIR/boot
ROOT=$TMPDIR/root
FILES=$TMPDIR/files

# Read optional parameters
MIDDLEWARE=
MIDDLEWARE_PARAM=
QUIET=0
while getopts "qm:p:s:" opt; do
	case $opt in
		q) 
			QUIET=1;;
		m)
			MIDDLEWARE=$OPTARG;;
		p)
			MIDDLEWARE_PARAM=$OPTARG;;
	esac
done


if [[ $QUIET == 0 ]]; then

	# Security check
	read -p "You are going to lose all your data on $1. Continue? [Y/n]" answer

	case $answer in 
	  	[yY]* ) 
			echo "OK. Continuing...";;

		* ) 
			echo "Quitting..."
	      	exit 1;;
	esac
fi

########################## SOURCE FILES ##############################

# Make some temp directories
mkdir -p $TMPDIR $BOOT $ROOT $FILES

MACHINENAME=$2
OSNAME=$3

# The files to source
MACHINES=(./machine/*/$MACHINENAME.sh)
OSES=(./os/*/$OSNAME.sh)
MIDDLEWARES=(./middleware/*/$MIDDLEWARE.sh)

if [[ (${#MACHINES[@]} != 1 || ${#OSES[@]} != 1 || ${#MIDDLEWARES[@]} > 1) && ( -f ${MACHINES[0]} && -f ${OSES[0]} ]]; then
	echo "In ./machine/ and ./os/ (and eventually ./middleware/), all .sh files should have unique names"
	exit 1
fi

# Source machine and os
source ${MACHINES[0]}
source ${OSES[0]}


# MACHINE must provide:
# mountpartitions()
# unmountpartitions()


# OS must provide:
# initos()


# MIDDLEWARE must provide:
# copyfiles()

# Mount them
mountpartitions

# Download a tar file and extract it, requires $MACHINENAME
initos

# Copy over all files to the temp files directory
cp $(dirname ${MACHINES[0]})/files/* $FILES
cp $(dirname ${OSES[0]})/files/* $FILES

# If the middleware exists
if [[ -f ${MIDDLEWARES[0]} ]]; then

	cp $(dirname ${MIDDLEWARES[0]})/files/* $FILES
	source ${MIDDLEWARES[0]}
	copyfiles
fi

# Unmount the temp filesystem
unmountpartitions

# Remove the temp filesystem
rm -r $TMPDIR


# Install a package 
require()
{
	BINARY=$1
	PACKAGE=$2

	# If which didn't find the binary, install it
	if [[ $(which $BINARY) == *"which: "* ]]
	then
		# Is pacman present?
		if [[ $(which pacman) != *"which: "* ]]
		then
			pacman -S $PACKAGE --noconfirm
			# Is apt-get present?
		elif [[ $(which apt-get) != *"which: "* ]]
		then
			apt-get install -y $PACKAGE
		else
			echo "The required package $PACKAGE with the binary $BINARY isn't present now. Install it."
			exit 1
		fi
	fi
}