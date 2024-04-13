#!/bin/bash

exit_with_error()
{
	echo "Cannot upload file to S3 storage. $1"
	exit 1
}

if [ ! -f "$HOME/.aws/credentials" ]
then
	exit_with_error "AWS Credentials file not found"
fi

if [ ! -f "$HOME/.aws/config" ]
then
	exit_with_error "AWS config file not found"
fi

if [ -z "$CONFOMEET_S3_BUCKET" ]; then
	exit_with_error "CONFOMEET_S3_BUCKET unset"
fi

if [ -z "CONFOMEET_S3_URL" ]; then
	exit_with_error "CONFOMEET_S3_URL is unset"
fi

RECORDINGS_DIR=$1
VIDEO_FILE_PATH=$(find $RECORDINGS_DIR -name *.mp4)
VIDEO_FILE_NAME=$(basename $VIDEO_FILE_PATH)
FILE_SIZE=$(du -b "$VIDEO_FILE_PATH" | cut -f1)
PRETTY_FILE_SIZE=$(du -h "$VIDEO_FILE_PATH" | cut -f1)
MEETING_ID=$(cut -d'_' -f1 <<< $VIDEO_FILE_NAME)
echo "Uploading recording at ${VIDEO_FILE_PATH} of ${PRETTY_FILE_SIZE} to s3://${CONFOMEET_S3_BUCKET}/${VIDEO_FILE_NAME}"
aws --endpoint-url="$CONFOMEET_S3_URL" s3 cp "$VIDEO_FILE_PATH" "s3://${CONFOMEET_S3_BUCKET}/${VIDEO_FILE_NAME}"

if [ ! "0" -eq "$?" ]; then
	echo "Uploading file to S3 storage failed"
	exit 1
fi

generate_post_request_body()
{
	cat <<-EOF
		{
			"meetingId": $MEETING_ID,
			"fileName": "$VIDEO_FILE_NAME",
			"fileSize": $FILE_SIZE,
			"bucket": "$CONFOMEET_S3_BUCKET",
			"key": "$VIDEO_FILE_NAME"
		}
	EOF
}

curl \
	-i \
	-H "Accept: application/json" \
	-H "Content-Type: application/json" \
	-X POST \
	--data "$(generate_post_request_body)" \
	"http://$XMPP_DOMAIN/meet/api/v1/Recording/AddS3VideoRecording"

if [ "0" -eq "$?" ]; then
	echo "Removing '$VIDEO_FILE_PATH' it is uploaded to S3 and backend is notified"
	rm "$VIDEO_FILE_PATH"
fi

