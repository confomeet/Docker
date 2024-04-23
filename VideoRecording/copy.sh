#!/bin/bash
RECORDINGS_DIR="/jibri"
VIDEO_FILE_PATH=$(find $RECORDINGS_DIR -name recordings)
VIDEO_FILE_PATH_NAME=${VIDEO_FILE_PATH:2}
echo "${VIDEO_FILE_PATH}"
ls -al ${VIDEO_FILE_PATH}
mkdir -p /archive
DEST="/archive"
for VIDEO_PATH in $(find $VIDEO_FILE_PATH -name '*.mp4')
do
VIDEO_FILE_NAME=${VIDEO_PATH:35}
VIDEO_FOLDER_NAME=${VIDEO_PATH:18}
FINAL_VIDEO_FOLDER_NAME=${VIDEO_FOLDER_NAME%/*}
echo "${VIDEO_FILE_NAME}"
echo "${FINAL_VIDEO_FOLDER_NAME}"
md5=`sudo md5sum ${VIDEO_PATH}`
md5=${md5%% *} # remove the first space and everything after it
echo ${md5}
cp $VIDEO_PATH $DEST
TARGET_FILE_NAME=$(find $DEST -name $VIDEO_FILE_NAME)
md25=`sudo md5sum ${TARGET_FILE_NAME}`
md25="${md25%% *}" # remove the first space and everything after it
echo ${md25}
if [ "$md5" = "$md25" ]
then
echo "$FINAL_VIDEO_FOLDER_NAME"
    rm -rf $VIDEO_FILE_PATH/$FINAL_VIDEO_FOLDER_NAME
    echo "Files have the same content"
echo "**********************************"
else
    echo "Files do NOT have the same content"
echo "**********************************"
fi
done