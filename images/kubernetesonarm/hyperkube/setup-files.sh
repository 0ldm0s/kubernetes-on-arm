#!/bin/bash

# Copyright 2015 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

create_token() {
  echo $(cat /dev/urandom | base64 | tr -d "=+/" | dd bs=32 count=1 2> /dev/null)
}

echo "admin,admin,admin" > /data/basic_auth.csv
CERT_DIR=/data /make-ca-cert.sh $(hostname -i)

echo "$(create_token),admin,admin" >> /data/known_tokens.csv
echo "$(create_token),kubelet,kubelet" >> /data/known_tokens.csv
echo "$(create_token),kube_proxy,kube_proxy" >> /data/known_tokens.csv

while true; do
	sleep 3600
done