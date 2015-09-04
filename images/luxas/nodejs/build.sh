#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

docker build -t build/nodejs .

# eventually remove some of these

../../../utils/strip-image/strip-docker-image \
	-i build/nodejs \
	-p node \
	-t luxas/nodejs \
	-f /etc/passwd \
	-f /etc/group \
	-f '/lib/*/libnss*' \
	-f /bin/ls \
	-f /bin/cat \
	-f /bin/sh \
	-f /bin/mkdir \
	-f /bin/ps \
	-f /var/run 