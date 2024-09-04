REM NOA-Beyond
REM Short Description:
REM Takes an input folder, an output folder and a target resolution:
REM All .tif under input folder are merged into one composite (mosaic)
REM with an e.g. 2x2 meters resolution. Then, this mosaic is stored as "mosaic.tif" in the output folder.
REM e.g. of usage: gdal_warp_all_under_folder_COG_windows.bat C:\temp\data C:\temp\data\output 5
REM (execute script for all .tif under data folder, output mosaic.tif under output folder, using a resolution of 5x5 meters per pixel)
REM Please note that this will not work as expected if:
REM 1) GDAL is not installed in the working environment
REM 2) Tifs are in different projection
REM 3) Tifs are in different resolution
REM Of course, you can intoduce any other appropriate gdalwarp parameter.

@echo off

REM Check if GDAL is installed
where gdalwarp >nul 2>nul
if %errorlevel% neq 0 (
    echo GDAL is not installed or not in the system PATH. Please install GDAL and ensure it is in the PATH.
    exit /b 1
)

REM Check if the correct number of arguments are provided
if "%3"=="" (
    echo Usage: %~0 [path\to\input\directory] [path\to\output\directory] [resolution in meters (e.g. 2 for 2mx2m pixel size)]
    exit /b 1
)

REM Set input parameters
set INPUT_DIR=%~1
set OUTPUT_DIR=%~2
set RESOLUTION=%~3

REM Set output file name
set OUTPUT_FILE=%OUTPUT_DIR%\mosaic.tif

REM List of all .tif files in the input directory
set INPUT_FILES=
for %%f in (%INPUT_DIR%\*.tif) do (
    set INPUT_FILES=%INPUT_FILES% "%%f"
)

echo %INPUT_FILES%

REM Ensure delayed expansion is enabled to handle variable inside loop
setlocal enabledelayedexpansion

REM Warp everything using gdalwarp
gdalwarp --config GDAL_CACHEMAX 4000 -wm 4000 -multi -wo NUM_THREADS=ALL_CPUS -of COG -tr %RESOLUTION% %RESOLUTION% %INPUT_FILES% "%OUTPUT_FILE%"

echo Warped all TIFF files to %OUTPUT_FILE%
echo All TIFF files have been processed.

endlocal