# NOA-Beyond
# Short Description:
# Takes an input folder, an output folder and a target resolution:
# All .tif under input folder are merged into one composite (mosaic)
# with an e.g. 2x2 meters resolution. Then, this mosaic is stored as "mosaic.tif" in the output folder.
# e.g. of usage: gdal_warp_all_under_folder_COG_windows.bat C:\temp\data C:\temp\data\output 5
# (execute script for all .tif under data folder, output mosaic.tif under output folder, using a resolution of 5x5 meters per pixel)
# Please note that this will not work as expected if:
# 1) GDAL is not installed in the working environment
# 2) Tifs are in different projection
# 3) Tifs are in different resolution
# Of course, you can intoduce any other appropriate gdalwarp parameter

param (
    [string]$InputDir,
    [string]$OutputDir,
    [string]$Resolution
)

# Check if GDAL is installed
if (-not (Get-Command gdalwarp -ErrorAction SilentlyContinue)) {
    Write-Error "GDAL is not installed or not in your system's PATH."
    exit 1
}

# Check if correct number of arguments are passed
if (-not $InputDir -or -not $OutputDir -or -not $Resolution) {
    Write-Error "`n`nMissing arguments: `nUsage: gdal_mosaic_from_tif_folder.ps1 [/path/to/input/directory] [/path/to/output/directory] [resolution in meters (e.g. 2 for 2mx2m pixel size)]"
    exit 1
}

# Get list of all .tif files in the input directory
$InputFiles = Get-ChildItem -Path $InputDir -Filter *.tif | Select-Object -ExpandProperty FullName

# Check if any .tif files are found
if (-not $InputFiles) {
    Write-Error "No TIFF files found in the input directory."
    exit 1
}

# Set output file path
$OutputFile = Join-Path -Path $OutputDir -ChildPath "mosaic.tif"

# Run gdalwarp command
& gdalwarp --config GDAL_CACHEMAX 4000 -wm 4000 -multi -wo NUM_THREADS=ALL_CPUS -of COG -tr $Resolution $Resolution $InputFiles $OutputFile

if ($LASTEXITCODE -eq 0) {
    Write-Output "Warped all TIFF files to $OutputFile"
    Write-Output "All TIFF files have been processed."
} else {
    Write-Error "An error occurred during the warping process."
    exit $LASTEXITCODE
}