#!/bin/bash

PDF=$1
TMP_PDF=`mktemp`
TMP_TIFF=`mktemp --suffix=".tiff"`

echo "convert -density 300 $PDF -alpha Off -depth 8 $TMP_TIFF && tesseract $TMP_TIFF $TMP_PDF -l deu pdf && cp $TMP_PDF $PDF"
convert -density 300 $PDF -alpha Off -depth 8 $TMP_TIFF && tesseract $TMP_TIFF $TMP_PDF -l deu pdf && cp "${TMP_PDF}.pdf" $PDF
