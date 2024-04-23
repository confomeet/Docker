#!/bin/bash
pwd=$(pwd)
PROJECT_DIR="/opt/jitsidocker"
DATE=$(date)
echo "restared at " ${DATE}
echo ${pwd}
cd $PROJECT_DIR
WEB_SERVER_FILE_PATH=$(find $PROJECT_DIR -name WebServer)
cd $WEB_SERVER_FILE_PATH
sudo docker compose -f web.yml restart
echo $WEB_SERVER_FILE_PATH
echo "**********************************"
