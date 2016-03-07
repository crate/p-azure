#!/bin/bash -x

while [[ $# > 1 ]]; do
  key="$1"

  case $key in
    -p|--pattern)
      PATTERN="$2"
      shift
    ;;
    *)
      # unknown option
    ;;
  esac
  shift
done

if [ -z "$PATTERN" ]; then
    echo "Pattern for matching containers names is not provoded!";
    exit 0;
fi

docker kill $(docker ps -a -f "name=$PATTERN" | awk '{print $1}')
docker rm $(docker ps -a -f "name=$PATTERN" | awk '{print $1}')