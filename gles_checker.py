import os
import subprocess
import re
import sys

APKTOOL_PATH = "apktool.jar"

def decompile_apk(apk_file):
    try:
        apk_name = os.path.splitext(os.path.basename(apk_file))[0]
        output_folder = f"decompiled_{apk_name}_apk"
        subprocess.run(["java", "-jar", APKTOOL_PATH, "d", apk_file, "-o", output_folder], check=True)
        return output_folder
    except subprocess.CalledProcessError as e:
        print("Error decompiling APK:", e)
        return None

def get_gles_version(manifest_path):
    try:
        with open(manifest_path, "r", encoding="utf-8") as manifest_file:
            manifest_content = manifest_file.read()
            match = re.search(r'android:glEsVersion="(\d+\.\d+)"', manifest_content)
            if match:
                return match.group(1)
    except Exception as e:
        print("Error reading manifest file:", e)
    return None

if len(sys.argv) != 2:
    print("Usage: python script.py path/to/your/app.apk")
    sys.exit(1)

APK_FILE = sys.argv[1]

output_folder = decompile_apk(APK_FILE)

if output_folder:
    manifest_path = os.path.join(output_folder, "AndroidManifest.xml")
    gles_version = get_gles_version(manifest_path)
    
    if gles_version:
        print(f"GLES Version: {gles_version}")
    else:
        print("GLES Version not found in the AndroidManifest.xml")
else:
    print("APK decompilation failed.")
