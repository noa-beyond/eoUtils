import os
import sys
import re
from pathlib import Path

def reproject_vrt_mosaic(input_path, source, target):
    pattern = re.compile(r"("+source+")(.*)\\.tif")
    for root, dirs, files in os.walk(input_path):
        for that_dir in dirs:
            if "original" not in that_dir:
                found = False
                for item in os.listdir(os.path.join(root, that_dir)):
                    if pattern.match(item) and "reprojected" not in item and "original" not in item:
                        print(item)
                        original_dir = Path(root, that_dir, "original")
                        if not os.path.exists(str(original_dir)):
                            original_dir.mkdir(parents=True, exist_ok=True)
                        file_path = str(Path(root, that_dir, item))
                        f_output = file_path + "_reprojected.tif"
                        cmd = f"gdalwarp --config GDAL_CACHEMAX 9000 -wm 80% -co COMPRESS=DEFLATE -s_srs '+proj=utm +zone={source} +datum=WGS84 +units=m +no_defs ' -t_srs '+proj=utm +zone={target} +datum=WGS84 +units=m +no_defs ' {file_path} {f_output}"
                        os.system(cmd)
                        cmd_1 = f"mv {file_path} {str(original_dir)}"
                        os.system(cmd_1)
                        found = True
                if found:
                    print("Done reprojecting and moving, going to vrt creation")
                    mosaic_name = root.split("/")[-2] + "_" + root.split("/")[-1] + "_" + that_dir.strip("/")
                    merge_path = str(Path(root, that_dir, mosaic_name + "_merged.vrt"))
                    tif_path = os.path.join(root, that_dir)
                    cmd_3 = f"gdalbuildvrt {merge_path} {tif_path}/*.tif"
                    os.system(cmd_3)
                    print("Done")
                    print("Building mosaic...")
                    cmd_4 = f"gdal_translate -of COG -co NUM_THREADS=ALL_CPUS -co COMPRESS=LERC_DEFLATE -co QUALITY=25 -co BIGTIFF=YES {merge_path} {tif_path}/{mosaic_name}_median_mosaic_LERC.tif"
                    print("Done")
                    os.system(cmd_4)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python reproject.py <parent_folder> <source_UTM> <target_UTM>")
    else:
        input_path = sys.argv[1]
        source = sys.argv[2]
        target = sys.argv[3]
        reproject_vrt_mosaic(input_path, source, target)
