import os
import subprocess
import re
import sys
import tkinter as tk
from tkinter import filedialog

class ApkToolGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("APK Decompiler")

        self.label = tk.Label(root, text="APK Decompiler", anchor='w')
        self.label.grid(row=0, column=0, sticky='w', padx=10, pady=5)

        self.path_entry = tk.Entry(root)
        self.path_entry.grid(row=1, column=0, padx=10, pady=5, sticky='w')

        self.browse_apktool_button = tk.Button(root, text="Browse apktool.jar", command=self.browse_apktool)
        self.browse_apktool_button.grid(row=1, column=1, padx=10, pady=5, sticky='w')

        self.browse_button = tk.Button(root, text="Browse APK", command=self.browse_apk)
        self.browse_button.grid(row=1, column=2, padx=10, pady=5, sticky='w')

        self.extract_button = tk.Button(root, text="Extract APK", command=self.extract_apk)
        self.extract_button.grid(row=2, column=0, padx=10, pady=5, sticky='w')

        self.check_button = tk.Button(root, text="Check", command=self.check_gles_version)
        self.check_button.grid(row=2, column=1, padx=10, pady=5, sticky='w')

        self.error_label = tk.Label(root, text="", fg="red")
        self.error_label.grid(row=3, column=0, padx=10, pady=5, sticky='w')

        self.console_text = tk.Label(root, text="", height=10, width=50, anchor='w', justify='left', fg="green")
        self.console_text.grid(row=4, column=0, padx=10, pady=5, sticky='w')

        self.apktool_path = ""

    def browse_apktool(self):
        apktool_path = filedialog.askopenfilename(filetypes=[("APKTool files", "apktool.jar")])
        if apktool_path:
            self.apktool_path = apktool_path
            self.show_message(f"APKTool selected: {apktool_path}")

    def browse_apk(self):
        file_path = filedialog.askopenfilename(filetypes=[("APK files", "*.apk")])
        self.path_entry.delete(0, tk.END)
        self.path_entry.insert(0, file_path)

    def extract_apk(self):
        apk_file = self.path_entry.get()
        if apk_file:
            self.console_text.config(text="")  # Clear console text
            output_folder = self.decompile_apk(apk_file)
            if output_folder:
                self.show_message(f"APK decompiled successfully. Output folder: {output_folder}")
            else:
                self.show_error("APK decompilation failed.")
        else:
            self.show_error("Please select an APK file.")

    def decompile_apk(self, apk_file):
        try:
            if not self.apktool_path:
                self.show_error("Please select apktool.jar first.")
                return None

            apk_name = os.path.splitext(os.path.basename(apk_file))[0]
            output_folder = f"decompiled_{apk_name}_apk"
            cmd = ["java", "-jar", self.apktool_path, "d", apk_file, "-o", output_folder]

            if sys.platform.startswith('win'):
                # On Windows, hide the console window
                startupinfo = subprocess.STARTUPINFO()
                startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
                process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin=subprocess.PIPE, startupinfo=startupinfo, text=True)
            else:
                # On non-Windows systems, use stdout=subprocess.PIPE to capture the output
                process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            while True:
                line = process.stdout.readline()
                if not line:
                    break
                current_text = self.console_text.cget("text")
                self.console_text.config(text=current_text + line)
                self.root.update_idletasks()

            process.wait()

            if process.returncode == 0:
                return output_folder
            else:
                return None

        except subprocess.CalledProcessError as e:
            print("Error decompiling APK:", e)
            return None

    def check_gles_version(self):
        output_text = self.console_text.cget("text")
        if not output_text:
            self.show_error("No output available. Please extract APK first.")
            return

        # Extracting the output folder path from the console text
        output_folder_line = output_text.split("\n")[-2]  # Assuming the output folder path is the second-to-last line
        output_folder = output_folder_line.split(":")[-1].strip()

        manifest_path = os.path.join(output_folder, "AndroidManifest.xml")

        # Check ARM architecture
        lib_folder_path_armeabi = os.path.join(output_folder, "lib", "armeabi")
        lib_folder_path_armeabiv7a = os.path.join(output_folder, "lib", "armeabi-v7a")

        if os.path.exists(lib_folder_path_armeabi) or os.path.exists(lib_folder_path_armeabiv7a):
            self.show_message("ARMv6 or ARMv7 executable is present.")
        else:
            self.show_message("IMPOSIBLE PORT: No ARMv6 or ARMv7 executable found.")
            return

        try:
            with open(manifest_path, "r", encoding="utf-8") as manifest_file:
                manifest_content = manifest_file.read()

                # Check GLES version
                if 'android:glEsVersion="0x00010000"' in manifest_content:
                    self.show_message("GLES 1.0 is supported.")
                elif 'android:glEsVersion="0x00020000"' in manifest_content:
                    self.show_message("GLES 2.0 is supported.")
                elif 'android:glEsVersion="0x00030000"' in manifest_content:
                    self.show_message("GLES 3.0 is supported.")
                else:
                    self.show_message("Unknown or unsupported GLES version.")

                # Check for libgdx.so or libunity.so
                libgdx_path = os.path.join(output_folder, "lib", "libgdx.so")
                libunity_path = os.path.join(output_folder, "lib", "libunity.so")

                if os.path.exists(libgdx_path) or os.path.exists(libunity_path):
                    self.show_message("IMPOSIBLE PORT: libgdx.so or libunity.so found.")
                    return

                # Check FMOD files
                fmod_files = ["libfmod.so", "libfmodevent.so", "libfmodex.so", "libfmodstudio.so"]
                for fmod_file in fmod_files:
                    fmod_path_armeabi = os.path.join(lib_folder_path_armeabi, fmod_file)
                    fmod_path_armeabiv7a = os.path.join(lib_folder_path_armeabiv7a, fmod_file)

                    if os.path.exists(fmod_path_armeabi) or os.path.exists(fmod_path_armeabiv7a):
                        if fmod_file == "libfmod.so" or fmod_file == "libfmodstudio.so":
                            self.show_message("POSSIBLE PORT: FMOD files found.")
                            return
                        else:
                            self.show_message("IMPOSIBLE PORT: Unsupported FMOD file found.")
                            return

                # Check for Kotlin folder
                kotlin_folder_path = os.path.join(output_folder, "kotlin")
                if os.path.exists(kotlin_folder_path):
                    self.show_message("IMPOSIBLE PORT: Kotlin folder found.")
                    return

                # Additional check for GLES version 3.0
                if 'android:glEsVersion="0x00030000"' in manifest_content:
                    self.show_message("ALLMOST IMPOSIBLE: GLES 3.0 is supported.")
                else:
                    self.show_message("POSSIBLE PORT: No additional limitations found.")

        except Exception as e:
            self.show_error(f"Error reading manifest file: {e}")

    def show_error(self, message):
        self.error_label.config(text=message, fg="red")
        # Clear console text when showing an error
        self.console_text.config(text="")

    def show_message(self, message):
        self.error_label.config(text=message, fg="green")
        current_text = self.console_text.cget("text")
        self.console_text.config(text=current_text + message + "\n")
        self.root.update_idletasks()

if __name__ == "__main__":
    root = tk.Tk()
    gui = ApkToolGUI(root)
    root.mainloop()
