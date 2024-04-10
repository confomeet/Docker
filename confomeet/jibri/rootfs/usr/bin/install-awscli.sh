#!/bin/bash

set -o pipefail -xeu

dpkgArch="$(dpkg --print-architecture)"
case "${dpkgArch##*-}" in
    "amd64") AWSCLI_ARCH=x86_64 ;;
    "x86_64") AWSCLI_ARCH=x86_64 ;;
    "arm64") AWSCLI_ARCH=aarch64 ;;
    "aarch64") AWSCLI_ARCH=aarch64 ;;
    *) echo "Unsupported architecture for AWS CLI dpkgArch=$dpkgArch"; exit 1 ;;
esac

wget "https://awscli.amazonaws.com/awscli-exe-linux-$AWSCLI_ARCH.zip" -qO "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp/awscliv2
/tmp/awscliv2/aws/install
rm -rf /tmp/awscliv2*

aws --version
