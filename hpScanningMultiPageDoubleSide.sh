#!/bin/bash

# try to find this scripts directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# parse command line (see: https://stackoverflow.com/a/13359121)
for i in "$@"
do
    case $i in
	--wait)
	    WOF=true # whether to wait if child some-how fails
	    shift
	    ;;
	*)
	    
	    ;;
    esac
done


# execute scan-and-ocr.sh with the correct parameters 
${SCRIPT_DIR}/scan-and-ocr.sh --adf --dup
rc=$?

# wait on failure if desired
if [ "$WOF" = "true" ] ; then
    if [[ $rc != 0 ]]; then
	read -p 'Press any key...'
    fi
fi
