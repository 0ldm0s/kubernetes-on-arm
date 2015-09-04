domiddleware(){

	cd "$( dirname "${BASH_SOURCE[0]}" )"

	# First, do the common things
	source luxcloud-common.sh
	docommon

	# Copy over the k8s master script
	cp $FILES/k8s-minion.sh $LUXDIR

	# And rename it to k8s for calling by luxcloud
	mv $LUXDIR/k8s-minion.sh $LUXDIR/k8s.sh

	# Specify role
	echo -e "ROLE=\"MINION\" \n" >> $LUXDIR/config.sh
}