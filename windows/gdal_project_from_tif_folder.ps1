# NOA-Beyond
# Short Description:
# Takes an input folder and an output folder and optionally:
# All .tif under input folder are projected using EPSG:3857, and stored under output folder, adding the prefix "projected_"
# before each file name.
# e.g. of usage: .\gdal_project_from_tif_folder.ps1 "C:\path\of\input\directory" "C:\path\of\output\directory"
# Please note that this will not work as expected if:
# 1) GDAL is not installed in the working environment
# 2) TIfs do not have the proper extension (.tif)
# Of course, you can intoduce any other appropriate gdalwarp parameter

param (
    [string]$InputDir,
    [string]$OutputDir
)

# Check if GDAL is installed
if (-not (Get-Command gdalwarp -ErrorAction SilentlyContinue)) {
    Write-Error "GDAL is not installed or not in your system's PATH."
    exit 1
}

# Check if correct number of arguments are passed
if ((-not $InputDir -or -not $OutputDir) -or ($InputDir -is [int] -or $OutputDir -is [int])){
    Write-Error "`n`nMissing arguments: `nUsage: .\gdal_project_from_tif_folder.ps1 [.\path\to\input\directory\] [.\path\to\output\directory\]"
    exit 1
}

# Get list of all .tif files in the input directory
$InputFiles = Get-ChildItem -Path $InputDir -Filter *.tif | Select-Object -ExpandProperty FullName

# Check if any .tif files are found
if (-not $InputFiles) {
    Write-Error "No '.tif' files found in the input directory. Are you sure they have the correct extension (.tif) ?"
    exit 1
}

# Create directory if it does not exist
if (-not $OutputDir -PathType Container){
    New-Item -ItemType Directory -Force -Path $OutputDir
}

# Run gdalwarp command
foreach ($f in $InputFiles){
    $OutputFileName = Split-Path $f -leaf
    $OutputFileName = "projected_" + $OutputFileName
    $outfile = Join-Path -Path $OutputDir -ChildPath $OutputFileName
    & gdalwarp --config GDAL_CACHEMAX 4000 -wm 4000 -multi -wo NUM_THREADS=ALL_CPUS -t_srs EPSG:3857 -dstnodata 0 -nosrcalpha $f $outfile
}

if ($LASTEXITCODE -eq 0) {
    Write-Output "Warped all tif files to $OutputFile"
    Write-Output "All TIFF files have been processed."
} else {
    Write-Error "An error occurred during the warping process."
    exit $LASTEXITCODE
}
