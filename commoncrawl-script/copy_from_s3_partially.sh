#!/bin/bash
# Script to transfer data from S3 to Azure Blob Storage
# Usage : run the script with AWS_FOLDER as a parameter e,g: ./commoncrawler.sh CC-MAIN-2014-15
#AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_ACCESS_KEY must be exported upfront
#The script firstly downloads "wet.paths" file which contains links to actual crawl data, \
#then downloads data on each link , uploads to azure blob storage and then deletes from local. \
#It also keeps track of downloaded files to avoid dublication by adding file names to "downloadfiles.txt"

#export AZURE_STORAGE_ACCOUNT=commoncrawl2014
#export AZURE_STORAGE_ACCESS_KEY=PUDaGx044L0XJs5tSNYl8BRWPSHFUx2nVKW3sCHjipYFFBfy2Jdy9XRUcNI13JmRcTy7nGIDtaPL+OfGPMcQ6w==

if [ "x$AZURE_STORAGE_ACCOUNT" = "x" ]; then
  echo "AZURE_STORAGE_ACCOUNT missing!"
  exit 1
fi

if [ "x$AZURE_STORAGE_ACCESS_KEY" = "x" ]; then
  echo "AZURE_STORAGE_ACCESS_KEY missing!"
  exit 1
fi

# export PART="xaaaa"
PART="$2"
if [ "x$PART" = "x" ]; then
  echo "PART (2nd parameter) is missing!"
  exit 1
fi

# export AWS_FOLDER="CC-MAIN-2014-15"
AWS_FOLDER="$1"
AWS_HOST="https://aws-publicdatasets.s3.amazonaws.com"
AWS_URL="$AWS_HOST/common-crawl/crawl-data/$AWS_FOLDER"
if [ "x$AWS_FOLDER" = "x" ]; then
  echo "AWS_FOLDER (1st parameter) is missing!"
  exit 1
fi

CONTAINER_NAME=${AWS_FOLDER,,}
#echo "Creating the container on Azure..."
#azure storage container create $CONTAINER_NAME
echo "Starting downloading links"
FOLDER_NAME="$HOME/$AZURE_STORAGE_ACCOUNT/$AWS_FOLDER"
mkdir -pv $FOLDER_NAME

PART_DOWNLOAD_FILE="$FOLDER_NAME/downloadedfiles_$PART.txt"
touch $PART_DOWNLOAD_FILE

cd $FOLDER_NAME
#if [ ! -f "wet.paths" ]; then
#	wget "$AWS_URL/wet.paths.gz"
#	gunzip *.gz
#fi

while read p; do
  echo "Downloading $p"
  SEGMENT_ID=$(echo $p | cut -d \/ -f 5)
  FILENAME=$(echo $p | cut -d \/ -f 7)
  FILE_ID="$SEGMENT_ID"_"$FILENAME"
  if ! grep -q  $FILE_ID $PART_DOWNLOAD_FILE; then
    time wget -c -nv $AWS_HOST/$p
    echo "Uploading the image..."
    mv $FILENAME $FILE_ID
    time  azure storage blob upload $FILE_ID $CONTAINER_NAME
    rm $FILE_ID
    echo $FILE_ID >> $PART_DOWNLOAD_FILE
  else
    echo "$FILE_ID already downloaded"
  fi
done < $PART

echo "Done"

