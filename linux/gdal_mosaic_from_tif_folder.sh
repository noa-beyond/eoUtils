#!/bin/bash

# NOA-Beyond
# Short Description:
# Takes an input and output folder:
# All .tif under input folder are merged into one composite (mosaic)
# with a 2x2 meters resolution. Then, this mosaic is stored as "mosaic.tif" in the output folder.
# Please note that this will not work as expected if:
# 1) Tifs are in different projection
# 2) Are in different resolution
# Also note that you can change the output resolution by tweaking the gdal command below.
# Of course, you can intoduce any other appropriate gdalwarp parameter.
# This script can be better if you define the output driver just to be sure (COG)

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 [/path/to/input/directory] [/path/to/output/directory] [resolution in meters (e.g. 2 for 2mx2m pixel size)]"
  exit 1
fi

# Directory containing the TIFF files
INPUT_DIR=$1
OUTPUT_DIR=$2
RESOLUTION=$3

# List of all .tif files in the input directory
INPUT_FILES=("$INPUT_DIR"/*.tif)
OUTPUT_FILE="$OUTPUT_DIR/mosaic.tif"

# Warp everything
gdalwarp --config GDAL_CACHEMAX 4000 -wm 4000 -multi -wo NUM_THREADS=ALL_CPUS -of COG -tr $RESOLUTION $RESOLUTION "${INPUT_FILES[@]}" "$OUTPUT_FILE"

echo "Warped all TIFF files to $OUTPUT_FILE"
echo "All TIFF files have been processed."
