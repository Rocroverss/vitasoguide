import os
import subprocess
import shutil

# Path to the decompiled APK directory
APK_DIR = "decompiled_apk"

# Path to the PS Vita SDK's utilities directory
VITA_SDK_UTILS_DIR = "path/to/psvita/sdk/utils"

# Output VPK file name
OUTPUT_VPK = "output.vpk"

# Check if the VITA_SDK_UTILS_DIR exists
if not os.path.exists(VITA_SDK_UTILS_DIR):
    print("PS Vita SDK utilities directory not found. Please provide the correct path.")
    exit(1)

# Check if the decompiled APK directory exists
if not os.path.exists(APK_DIR):
    print("Decompiled APK directory not found. Please provide the correct path.")
    exit(1)

# Create a temporary directory for the VPK package
TMP_DIR = "tmp_vpk"
if os.path.exists(TMP_DIR):
    shutil.rmtree(TMP_DIR)
os.mkdir(TMP_DIR)

try:
    # Copy necessary files and directories from the decompiled APK
    shutil.copytree(os.path.join(APK_DIR, "assets"), os.path.join(TMP_DIR, "sce_sys", "livearea", "contents"))
    shutil.copytree(os.path.join(APK_DIR, "res"), os.path.join(TMP_DIR, "res"))

    # Generate the param.sfo file (metadata) - You may need to customize this
    with open(os.path.join(TMP_DIR, "sce_sys", "param.sfo"), "w", encoding="utf-8") as param_sfo:
        param_sfo.write("""ATTRIBUTE=512
CONTENT_ID=MyApp0001
STITLE=My App
TITLE=My App
PUBTOOLINFO=0x00000001

# Customize these fields as needed
APP_VER=01.00
CATEGORY=GN

""")
    
    # Create the VPK package using the VITA_SDK_UTILS_DIR's vpk.exe utility
    vpk_tool = os.path.join(VITA_SDK_UTILS_DIR, "vpk.exe")
    subprocess.run([vpk_tool, OUTPUT_VPK, "."], cwd=TMP_DIR, check=True)

    print(f"VPK file '{OUTPUT_VPK}' created successfully.")
except Exception as e:
    print(f"Error: {e}")

# Clean up temporary directory
shutil.rmtree(TMP_DIR)

