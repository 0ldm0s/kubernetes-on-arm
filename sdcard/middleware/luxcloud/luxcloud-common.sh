
# Setup variables
BINDIR=$ROOT/usr/local/bin
LUXDIR=$BINDIR/luxcloud

docommon(){

	REQUIRED_FILES="install_lux.sh k8s-master.sh k8s-minion.sh lux.sh shorties.sh"

	for FILE in $REQUIRED_FILES
	do
		if [[ ! -f $FILES/$FILE ]]; then
			echo "Error: Middleware luxcloud requires the following file: $FILE. Use a machine or os that provides those files"
			exit 1;
		fi
	done

	# Make the directory for the scripts
	mkdir -p $LUXDIR

	# Copy install.sh to the luxcloud dir
	cp $FILES/install_lux.sh $LUXDIR/install.sh

	# And the wrapper to the bin dir
	cp $FILES/lux.sh $BINDIR/lux

	# Populate config.sh
	cat > $LUXDIR/config.sh <<EOF
SD_CARD_BUILD_DATE="$(date +%d%m%y)"
NEXT_STEP=0
HOSTNAME="$MIDDLEWARE_PARAM"
EOF

	# Allow ssh connections by root to this machine
	echo "PermitRootLogin yes" >> $ROOT/etc/ssh/sshd_config

	# Make everything executable
	chmod +x $LUXDIR/*
	chmod +x $BINDIR/lux

	# Make shortcuts
	cp $FILES/shorties.sh $ROOT/etc/profile.d/
}