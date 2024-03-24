#!/bin/bash

set -e

tpl /root/.aws/credentials.tpl >/root/.aws/credentials
tpl /root/.aws/config.tpl >/root/.aws/config
chmod 600 /root/.aws/*

dotnet VideoProjectCore6.dll

