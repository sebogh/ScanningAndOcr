#!/bin/bash

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
${SCRIPT_DIR}/scan-and-ocr.sh --adf $*
