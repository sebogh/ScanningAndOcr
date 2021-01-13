#!/bin/bash

DEVICE='hpaio:/net/hp_laserjet_pro_mfp_m521dw?ip=192.168.178.42&queue=false'

# compute some paths
BASE=$(mktemp)
TMP_TIFF=${BASE}-tmp.tiff
TMP_PDF=${BASE}-tmp.pdf
OUTPUT_PDF=${BASE}.pdf

#colors (see: https://stackoverflow.com/a/5947802)
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# parse command line (see: https://stackoverflow.com/a/13359121)
for i in "$@"
do
    case $i in
	--adf)
	    SOURCE="--source=ADF" # scan multiple pages single side using the ADF
	    shift
	    ;;
	--dup)
	    SOURCE="--source=DUP" # scan multiple pages duplicate side using the ADF
	    shift
	    ;;
	--dry)
	    DRY="true" # dry run
	    shift
	    ;;
	--wait)
	    WAIT="true" # wait for user input on failure
	    shift
	    ;;
	*)
	    ;;
    esac
done


# check return code and exit (potentially waiting for user confirmation)
function checkRC {
  if [[ $1 != 0 ]]
  then
    if [ "$WAIT" = "true" ] ; then
    	read -p 'Press any key...'
    fi
    exit $1
  fi
}

# execute command (if not dry)
function doit {
  echo "$1"
  if [ "$DRY" != "true" ] ; then
    $1
    checkRC $?
  fi
}

# scan -> tiff
echo -e "${GREEN}######### scan -> tiff ############${NC}"
doit "scanimage -d ${DEVICE} --format=tiff -x 210 -y 297 --resolution=300 ${SOURCE}> ${TMP_TIFF}"

# tiff -> pdf
echo -e "${GREEN}######### tiff -> pdf ############${NC}"
doit "convert ${TMP_TIFF} ${TMP_PDF}"

# ocr pdf -> pdf
echo -e "${GREEN}######### ocr ############${NC}"
doit "ocrmypdf -l deu -d --deskew --clean $* ${TMP_PDF} ${OUTPUT_PDF}"

# view
echo -e "${GREEN}######### opening ############${NC}"
doit "nohup /usr/bin/evince ${OUTPUT_PDF} >/dev/null 2>/dev/null"

echo -e "${GREEN}created $OUTPUT_PDF${NC}"


