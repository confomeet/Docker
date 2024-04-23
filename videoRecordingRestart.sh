#1/bin/bash
pwd=$(pwd)
PROJECT_DIR="/opt/jitsidocker"
echo ${pwd}
cd $PROJECT_DIR
VIDEO_RECORDING_FILE_PATH=$(find $PROJECT_DIR -name VideoRecording)
cd $VIDEO_RECORDING_FILE_PATH
sudo docker compose -f jibri.yml restart
echo $VIDEO_RECORDING_FILE_PATH
echo "**********************************"clear
