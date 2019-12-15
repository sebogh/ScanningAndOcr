#!/bin/bash

RESOLUTION=300
LOCATION=/tmp
DEVICE='hpaio:/net/hp_laserjet_pro_mfp_m127fw?ip=192.168.178.22&queue=false'

# compute some paths
TMP_PDF_BASE=`mktemp`
TMP_PDF=${TMP_PDF_BASE}.pdf
TMP_TIFF=`mktemp --suffix=".tiff"`
OUTPUT_BASE=${LOCATION}/scan_"`date +%Y-%m-%d-%H-%M-%S`"
OUTPUT_PDF=${OUTPUT_BASE}.pdf

#colors (see: https://stackoverflow.com/a/5947802)
GREEN='\033[0;32m'
NC='\033[0m' # No Color

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
	--adf)
	    ADF="true" # scan multiple pages single side using the ADF
	    shift
	    ;;
	*)
	    
	    ;;
    esac
done

# scan
echo -e "${GREEN}######### scan ############${NC}"
if [ "$ADF" = "true" ] ; then
    COMMAND="${SCRIPT_DIR}/my-hp-scan -d ${DEVICE} --res=$RESOLUTION --size=a4 -mgray --adf --output=$OUTPUT_PDF"
else 
    COMMAND="${SCRIPT_DIR}/my-hp-scan -d ${DEVICE} --res=$RESOLUTION --size=a4 -mgray --output=$OUTPUT_PDF"
fi
echo $COMMAND
$COMMAND
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

# ocr
echo -e "${GREEN}######### ocr ############${NC}"
COMMAND="convert -density 300 $OUTPUT_PDF -alpha Off -depth 8 $TMP_TIFF"
echo $COMMAND
$COMMAND
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
COMMAND="tesseract $TMP_TIFF $TMP_PDF_BASE -l deu pdf"
echo $COMMAND
$COMMAND
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
COMMAND="cp $TMP_PDF $OUTPUT_PDF"
echo $COMMAND
$COMMAND
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

# compress
echo -e "${GREEN}######### compress ############${NC}"
COMMAND="gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=$OUTPUT_PDF $TMP_PDF"
echo $COMMAND
$COMMAND
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

## view 
echo -e "${GREEN}######### opening ############${NC}"
nohup /usr/bin/evince ${OUTPUT_PDF} >/dev/null 2>/dev/null

echo -e "${GREEN}created $OUTPUT_PDF${NC}"

