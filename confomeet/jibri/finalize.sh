#!/bin/bash
RECORDINGS_DIR=$1
echo "The value of my domain is : $XMPP_DOMAIN"
pwd=$(pwd)
echo "${pwd}"
echo "${RECORDINGS_DIR}"
VIDEO_FILE_PATH=$(find $RECORDINGS_DIR -name *.mp4)
echo "${VIDEO_FILE_PATH}"
VIDEO_FILE_NAME=${VIDEO_FILE_PATH:36}
echo "${VIDEO_FILE_NAME}"
VIDEO_FOLDER_NAME=${VIDEO_FILE_PATH:19}
FINAL_VIDEO_FOLDER_NAME=${VIDEO_FOLDER_NAME%/*}
echo "${FINAL_VIDEO_FOLDER_NAME}"
mysize=$(du -h "$VIDEO_FILE_PATH")
fileSize=${mysize%/config*}
echo "${fileSize}"
echo "***"
generate_post_request_body()
{
  cat <<-EOF
         {
         "recordingfileName":'$VIDEO_FILE_NAME',
         "fileSize":'$fileSize',
         "filePath":'$VIDEO_FILE_PATH'
         }
EOF
        }
curl -i \
-H "Accept: application/json" \
-H "Content-Type:application/json" \
-X POST --data "$(generate_post_request_body)" http://$XMPP_DOMAIN/meet/api/v1/Recording/AddVideoRecording
