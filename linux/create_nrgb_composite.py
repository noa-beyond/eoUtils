"""
NOA-Beyond

Simple, GDAL dependent, script, which creates NRGB composites from NRGB Sentinel 2 Bands.
Needs quality refactoring (folder checks, filenames, correct messages etc)
"""

import sys
import os
import re
from pathlib import Path
import glob


def main(input_path):
    for root, dirs, _ in os.walk(Path(input_path).absolute(), topdown=True):
        for directory in dirs:
            date_set = set()
            for file in os.listdir(Path(root, directory)):
                if file.endswith(".tif") and "composite" not in file:
                    date = ""
                    if file.split("_")[0].startswith("T") and "dif" not in file:
                        # T35LNC_20240615_dif_20240718_B03.tif
                        date = file.split("_")[-4] + "_dif_" + file.split("_")[-2]
                    elif file.split("_")[0].startswith("T") and "dif" in file:
                        if "TOTAL" in file:
                            # T35LNC_20240615_dif_20240718_B03.tif
                            date = file.split("_")[-5] + "_dif_" + "TOTAL"
                        else:
                            # T35LNC_20240615_dif_20240718_B03.tif
                            date = file.split("_")[-4] + "_dif_" + file.split("_")[-2]
                    else:
                        # histomatch_clipped_T35LND_20231103T081111_B03_10m.tif
                        # reference_clipped_T35LND_20231014T080901_B02_10m.tif
                        date = file.split("_")[-3]
                    date_set.add(date)
            print(f"Dir: {directory}, dates: {date_set}")
            for single_date in date_set:
                tiffs = glob.glob(root + "/" + directory + "/" + f"*{single_date}*")
                print(tiffs)
                pattern = r"B02|B03|B04|B08"
                cmd = (
                    f'gdalbuildvrt -separate {root}/{directory}/composite_{single_date}.vrt '
                    f'{re.sub(pattern, "B04", tiffs[0])} {re.sub(pattern, "B03", tiffs[0])} '
                    f'{re.sub(pattern, "B02", tiffs[0])} {re.sub(pattern, "B08", tiffs[0])}'
                )
                os.system(cmd)
                cmd = (
                    f"gdal_translate {root}/{directory}/composite_{single_date}.vrt "
                    f"{root}/{directory}/composite_{single_date}.tif"
                )
                os.system(cmd)
                cmd = f"rm {root}/{directory}/composite_{single_date}.vrt"
                os.system(cmd)


if __name__ == "__main__":

    if len(sys.argv) != 2:
        print("Usage: python create_nrgb_composite.py <path_to_traverse_topdown>")
    else:
        raster_path = sys.argv[1]
        main(raster_path)
