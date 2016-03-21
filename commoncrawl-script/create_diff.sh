#!/bin/bash
# This script can only be run when the copy_from_s3.sh script
# was already started, has created the storage account, downloaded and ungipped
# the wet.paths file and has written downloaded files already into
# the downloadedfiles.txt
# This script subtracts all files that where already downloaded/moved
# from the complete list and stores the result in a new filed named rest.paths
# Additionally it splits the rest into chunks of 8000 lines.
# These files than can be used as new source for moving files from S3 to Azure.

FOLDER="$1"
PARTS="$1/downloadedfiles.txt"
ALL="$1/wet.paths"
REST="$1/rest.paths"
rm $REST

while read p; do
  SEGMENT_ID=$(echo $p | cut -d \/ -f 5)
	FILENAME=$(echo $p | cut -d \/ -f 7)
	FILE_ID="$SEGMENT_ID"_"$FILENAME"
  if ! grep -q  $FILE_ID $PARTS; then
    echo $p >> $REST
  else
    echo "Already downloaded: $FILE_ID"
  fi
done < $ALL

CWD=$(pwd)
cd $FOLDER
split -a 4 -l 8000 rest.paths
cd $CWD

echo "DONE"
