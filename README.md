# Android so loader vita ports

## Description

- Welcome to Vitaports, your comprehensive resource for porting Android games to the PlayStation Vita platform. Whether you're a seasoned developer or just starting out, Vitaports offers the tools, guidelines, and community support you need to bring your favorite Android titles to the Vita. 

## Project Status
- ![Progress](https://img.shields.io/badge/Progress-24%25-brightgreen)
- ![Last Update](https://img.shields.io/badge/Last_Update-January_2025-blue)

### Features:
- [x] Apk checker
- [X] License 
- [ ] Workspace installation (in progress sh slighly works)
- [ ] How to test the workspapce (coming soon)
- [ ] How to start a port (not well implemented right now)
- [ ] Very simple so file to port (coming soon) 
 
# Index:

### [1. rocroverss apk port checker](#section1)
### [2. Workspace installation](#section2)
### [3. Rinnegatamante basic rules](#section3)
### [4. How to start a port](#section4)
### [5. Code port examples](#section5)
### [6. FAQ](#section6)
### [7. License](#section7)
### [8. Build Instructions (For Developers)](#section8)

<a name="section1"></a>

## rocroverss apk port checker:

The APK Port Checker helps to determine whether a specific APK is a candidate for porting to the PS Vita. It checks if essential rules are followed, as defined in [Rinnegatamante’s Android2Vita-Candidate-Ports-List](https://github.com/Rinnegatamante/Android2Vita-Candidate-Ports-List).


Usage guide:

1) Download apk tool from https://apktool.org/
2) Ensure you have Python installed (version 3.12 or above).
3) Run the script apk_port_validator.py.
4) Select the APK you want to check along with the APK tool.
5) Press the "Extract APK" button.
6) Press "Check" to validate the APK.

> **_NOTE:_** False positives/negatives may occur, so each case must be manually inspected. Another checker is avaliable by [withLogic](https://github.com/withLogic/vitaApkCheck)

Common Issues:
- APK Decompilation Fails: Ensure apktool is up-to-date and that the APK is not corrupted.
- Python Version Conflicts: Make sure you are using Python 3.12 or newer.
- False Positives: Occasionally, some APKs will be flagged incorrectly. Always verify the output manually.

<a name="section2"></a>

## Workspace installation

  A pre-configured workspace installer .sh script is available for Linux, but it has known bugs and is not recommended. However, a future virtual machine (VM) or improved .sh script is planned, which will include and install all the necessary tools, such as the gl33ntwine port template, VitaSDK with softfp, and vitaGL.
  
  1) The first step is to installl [vitasdk with softfp](https://github.com/vitasdk-softfp)
     (similar installation to vitasdk):
  2) Install [Vitagl](https://github.com/Rinnegatamante/vitaGL)
  3) Compile a sample/ port to test that it is working.
      > **_NOTE:_** Test that your workspace is functioning by compiling a port
      > (e.g., "Baba is You"). Be ready to tweak compilation options.
      > Other might work but use one that it's kind of new and simple.
  4)  Clone the [gl33ntwine Port template](https://github.com/v-atamanenko/soloader-boilerplate)
  5) Edit the CMAkelists.txt to make it suit your port.
  6) Prepare Build Directory:(this is where the vpk is going to be built):
  ```
    mkidr build
    cd build
  ```
   
   7) Build the Project:
   ```
    cmake ..
    make
   ```
  If successful, you should have a working port ready for testing on the PS Vita.

Common Issues:
- VitaSDK Installation Fails: Verify dependencies and ensure you're following the correct softfp setup.
- Compilation Errors: Ensure CMakeLists.txt matches your environment and the game’s requirements.
  
Debugging Tips:
- Use the vitaGL logging feature to trace OpenGL calls and check for missing symbols.
- Enable verbose output in cmake for detailed error tracking:
 ```
   cmake -DCMAKE_VERBOSE_MAKEFILE=ON ..
 ```

 Other interesting links:
- VitaSDK: https://github.com/vitasdk
- VitaSDK precompiled: https://github.com/vitasdk/buildscripts/releases
- Vitagl precompiled: https://github.com/Rinnegatamante/vitaGL/tree/legacy_precompiled_ffp

<a name="section3"></a>

## Rinnegatamante basic rules:

GTA: SA is referenced (is it really such? Quite sure no one of us references that repo directly anymore since years) probably cause it was the first Android port. The repo itself should not be used as reference for two main reasons:
1) has a lot of game specifics patches
2) It's fairly outdated (quite sure even the so_utils version it uses is outdated with it lacking stuffs like SO_CONTINUE or LDMIA patches).
3) For the documentation, no. Long story short:
   if you've solid C knowledge and basic RE capabilities, you should be able to figure out how the thing works on your own (or in general asking few sensed/well-proposed/targeted questions, so not stuffs like "how do i port gamerino.apk to vita?"). Usually you grab an existing port and start from that as base after clearing it from any game specific patch and jni impl. There are two major skeletons you can use, the ones using FalsoJNI (any gl33ntwine repo, Soulcalibur, Jet Car Stunts 2) and the more barebone ones using raw so_utils (any other Android port as far as I'm aware).
   
The whole idea around the "so loader" is:

1) You grab so files (which are ELFs) from the apk and load them using so_utils.
2) During the loading process, you resolve its imports with native versions of said functions (eg: you resolve OpenGL symbols with vitaGL or PVR_PSP2 ones).
3) During the loading process, you also apply any game specific patch (eg: skipping license checks, skipping broken code on Vita, etc)
4) You analyze the .dex file to know how the game actually jumps into C code (entrypoint) and use same entrypoint in your port.
5) You launch the app you created and proceed into implementing any JNI method (through FalsoJNI or through raw JNI reimpl.) and any specific game patch required until everything works. FalsoJNI: https://github.com/v-atamanenko/FalsoJNI

## DEX Files:
- DEX files are bytecode files that are used by the Android Runtime (ART) or the older Dalvik Virtual Machine (DVM) to execute code written in Java or Kotlin.
- When you write an Android application in Java or Kotlin, your source code is compiled into bytecode. This bytecode is then translated into DEX format during the build process.
- DEX files contain the compiled bytecode of your Android application's classes, interfaces, and methods. They are stored in the /dex directory within the APK file.
- DEX files are platform-independent and can run on any device that supports Android.

## .so Files:
- .so files, also known as shared object files or native libraries, contain compiled native code that is specific to a particular CPU architecture (e.g., ARM, x86, x86_64).
- These files are typically written in C or C++ and are used when you need to include native code in your Android application for performance reasons or when interacting with system-level features that are not accessible through the Android SDK.
- Unlike DEX files, .so files are platform-dependent. You need to compile them separately for each target architecture that you want to support.
- .so files are usually stored in the /lib directory within the APK file, with subdirectories for each CPU architecture (e.g., /lib/armeabi-v7a, /lib/arm64-v8a, /lib/x86, etc.).




<a name="section4"></a>

## How to start a port:

1) Understanding Android App Functionality:
To begin, it's essential to grasp the workings of an Android application. (Which other internal functions may vary depending on ythe specific android app)
![Lifetime of an android app](https://raw.githubusercontent.com/Rocroverss/vitasoguide/main/img/lifecycle_of%20andoird_apps.png)

2) Inspecting the Dex File
Examine the Dex file to identify the methods it contains. Analyze these methods to determine:
- Which native functions they call.
- The order of these calls.
- The arguments passed to these functions.
For this process, it is recommended to use tools like Ghidra or IDA Pro to better understand the behavior of the file.

3) Translate to vitagl: https://github.com/Rinnegatamante/vitaGL/blob/master/source/vitaGL.h
  During this phase, you need to inject your custom function into the workflow. The general approach includes:

 Patching a JMP Instruction:
- Redirect the original function (OG function) to your custom function.
- If only one function calls the target, you can patch it directly.
- If multiple functions call it, you’ll need a more dynamic approach, such as the method used in so_loader.
 
 Dynamic Hooking Process:
- Inside the target function, patch a JMP to your custom function.
- Perform your desired operations in the patched function.

If you want to execute the original function:
- Temporarily "unpatch" the function by restoring its original bytes.
- Execute the original function.
- Re-patch the function after it executes.

EXMPLES:
Example that rinnegatamante explained: 
Hooking with so_loader
- Here’s how hooking is implemented in so_loader:
```c
h.addr = addr; // Address of the original function to hook.
h.patch_instr[0] = 0xf000f8df; // LDR PC, [PC] - Load the address of the next instruction.
h.patch_instr[1] = dst;        // The address of the custom function to redirect execution to.

// Save the original instructions from the target address.
kuKernelCpuUnrestrictedMemcpy(&h.orig_instr, (void *)addr, sizeof(h.orig_instr));

// Overwrite the target address with the patch instructions (redirect to custom function).
kuKernelCpuUnrestrictedMemcpy((void *)addr, h.patch_instr, sizeof(h.patch_instr));
```

The following macro, provided by Rinnegatamante in so_util.h, demonstrates how to temporarily unpatch, execute, and re-patch the original function:

```c
#define SO_CONTINUE(type, h, ...) ({ \
    kuKernelCpuUnrestrictedMemcpy((void *)h.addr, h.orig_instr, sizeof(h.orig_instr)); \
    /* Restore the original instructions to temporarily unpatch the function. */ \
    kuKernelFlushCaches((void *)h.addr, sizeof(h.orig_instr)); \
    /* Flush the cache to ensure the CPU sees the original instructions. */ \
    type r = h.thumb_addr ? ((type(*)())h.thumb_addr)(__VA_ARGS__) : ((type(*)())h.addr)(__VA_ARGS__); \
    /* Execute the original function (restored to its unpatched state). */ \
    kuKernelCpuUnrestrictedMemcpy((void *)h.addr, h.patch_instr, sizeof(h.patch_instr)); \
    /* Reapply the patch to hook the function again after execution. */ \
    kuKernelFlushCaches((void *)h.addr, sizeof(h.patch_instr)); \
    /* Flush the cache to ensure the CPU sees the updated patch instructions. */ \
    r; /* Return the result of the original function call. */ \
})
```

4) Understand how the so_loader works to be able to port games:

  PS Vita SO Loader: load and execute .so (shared object) files, which are typically not natively supported by the PS Vita. 
   - Kernel/User Bridges (kubridge) to escalate privileges.
   - File and Memory Utilities (fios, so_util) to manage file I/O and dynamic library management.
   - Patching Mechanisms (patch.c) to modify the system or work around the restrictions imposed by Sony's PS Vita firmware.

  lib folder:
   - falso_jni: JNI stands for Java Native Interface, which is a framework that allows Java code to call or be called by native applications (e.g., C/C++). In the context of the PS Vita, this is related to handling Java interactions with native libraries.
   - Fios: I/O system libraries, which handle the reading, writing, and manipulation of files. Custom implementation or patch related to file access on the Vita.
   - kubridge: "kubridge" it stands for "kernel user bridge," which is a mechanism to bridge user-level operations to kernel-level functions. On the PS Vita, this could be used to exploit kernel-level privileges to load .so files or homebrew applications (not sure right now).
   - libc_bridge: This folder contains libraries and functions related to bridging the standard C library (libc) to the PS Vita environment.
   - sha1: A folder dealing with SHA-1 hashing, which is often used for verifying the integrity of files or data. 
   - so_util: Utilities for handling .so (shared object) files. This folder contains code to help with loading and managing these files on the PS Vita.
  
  source/loader folder:
   - reimpl: Likely short for "reimplementation," this folder contains reimplemented versions of key functions or libraries to run shared libraries or homebrew more smoothly on the PS Vita.
   - utils: A common name for a folder containing utility scripts or helper functions. These can handle various auxiliary tasks for the SO loader (e.g., managing memory, file paths, debugging).
   - dynlib.c: A C file dealing with "dynamic libraries." This script contains the core logic for handling .so files, including how they are loaded and linked during runtime.
   - java.c: A C file is involved in handling Java-specific functionality. If the PS Vita environment requires interaction with Java components (e.g., through JNI), this file would manage those calls or interactions.
   - main.c: This is usually the entry point of a C program. It is responsible for initializing the SO loader, setting up the environment, and handling overall control flow (key element of the loader).
   - patch.c: A C file that could contain patches or modifications to the PS Vita system, enabling it to load and run non-native libraries or bypass certain security mechanisms. (e.g, skip a broken cinematic).


5) Get back to the rinnegatamates basic rules.

## Troubleshooting Common Issues during a psvita port.
Undefined References (e.g., FMOD)
- Issue: Missing or incompatible .so files.
- Solution: Ensure correct stub files are used. For example, rename FMOD Studio API files to match the required format.

Graphics Errors (e.g., GL_INVALID_ENUM)
- Issue: These errors often arise during OpenGL calls.
- Solution: Most errors are harmless unless they explicitly cause crashes or rendering issues.

Shader Format
- Question: How to determine the shader format?
- Answer: Android games typically use GLSL shaders.

Error 0x8010113D during VPK installation
- If you encounter error 0x8010113D while installing a VPK for your PS Vita application, it may be related to an issue with the LiveArea assets. Specifically, ensure that all images in the sce_sys folder (such as icons and backgrounds) are in 8-bit color depth. Incorrect image formats can cause installation failures.
- Cause: Issues with LiveArea assets (e.g., incorrect image formats).
- Fix: Ensure images in sce_sys are in 8-bit color depth.

<a name="section5"></a>

## Code port examples:

### Example of porting a slice of code (fix for a port that made rinnegatamante):
```c
// VitaGL Wrapper for Android SO Loader Port

// Global variable to store the reference to the main.obb block
void *obb_blk = NULL;

// Wrapper function for calloc
void *__wrap_calloc(uint32_t nmember, uint32_t size) {
    // Forward the call to vglCalloc
    return vglCalloc(nmember, size);
}

// Wrapper function for free
void __wrap_free(void *addr) {
    // Prevent freeing the main.obb block
    if (addr != obb_blk)
        vglFree(addr);
}

// Wrapper function for malloc
void *__wrap_malloc(uint32_t size) {
    // Allocate memory using vglMalloc
    void *r = vglMalloc(size);
    
    // If allocating memory for main.obb
    if (size > 150 * 1024 * 1024) {
        // If allocation failed, pass the reference taken the first time
        if (!r)
            return obb_blk;
        
        // Store a reference to the main.obb block to prevent erroneous copies
        obb_blk = r;
    }
    
    // Return the allocated memory address
    return r;
}
```
This code is a set of wrapper functions for memory allocation and deallocation (malloc, calloc, free) in the context of a VitaGL wrapper for an Android SO Loader port. Let's break down what each function does:
1) void *__wrap_calloc(uint32_t nmember, uint32_t size): This function wraps around the calloc function. It forwards the call to vglCalloc and returns whatever vglCalloc returns.
2) void __wrap_free(void *addr): This function wraps around the free function. It checks if the memory address being freed is not equal to obb_blk. If it's not equal, meaning it's not the main.obb block, it proceeds to free the memory using vglFree.
3) void *__wrap_malloc(uint32_t size): This function wraps around the malloc function. It first allocates memory using vglMalloc and stores the result in r. Then it checks if the size of the memory being allocated is greater than 150MB (150 * 1024 * 1024 bytes). If it is, it checks if r is NULL, which would indicate a failed allocation. If it's not NULL, it assigns r to obb_blk, effectively storing a reference to the main.obb block to prevent erroneous copying. If r is NULL, it returns obb_blk, which presumably is the previously stored reference to the main.obb block. Otherwise, it returns r, which contains the allocated memory address.
4) To port a game you need to translate/wrap its opengl to vitagl for example:
   void __wrap_free(void *addr) on opengl is going to be void vglFree(void *addr) on vitagl 

### Another porting block example:

The Vita and some Android phones both use the same CPU architecture, so it's possible to run code designed for Android directly on the Vita. However, there are differences in how they handle executable files and interact with the operating system. Android is similar to Linux, while the Vita has its own unique system loosely based on BSD.

When porting from Android to the Vita, the main task is to create a version of the Android-specific functions for the Vita. For example, let's take the "open()" function, which is used in Android to open files:

```c
int open(const char* pathname, int flags, mode_t mode);
```

On the Vita, there's no direct equivalent to "open()", but there is a similar function called "sceIoOpen":

```c
SceUID sceIoOpen(const char *file, int flags, SceMode mode);
```

To make the Android code work on the Vita, you'd need to create your own version of "open()" that translates it into a call to "sceIoOpen". Here's a simplified example:

```c
int open(const char* pathname, int flags, mode_t mode) {
     SceMode vmode = 0;
     if(IS_BIT_SET(mode, O_RDONLY))
           vmode |= SCE_O_RDONLY;
     if(IS_BIT_SET(mode, O_WRONLY))
           vmode |= SCE_O_WRONLY;
     if(IS_BIT_SET(mode, O_RDWR))
           vmode |= SCE_O_RDWR;

    return sceioOpen(pathname, flags, vmode);

}
```
However, this isn't perfect. It doesn't handle all the flags properly, and it lacks error handling. In Linux, "open()" returns -1 if there's an error and updates the "errno" variable with an error code. But on the Vita, it returns the actual error code directly, which is always negative for errors and non-negative for success.

<a name="section6"></a>

## FAQ:

**1) Can I port X game to psvita?**

- Well there are some ways to port games to psvita, but unfortunately this guide is focused on android games that are compatible with .so loader. To check if the apk is a candidate use the port checker. After figure it out to port it propertly.

**2) Can someone port X game to psvita?**

- Check the apk port checker and after open an [issue](https://github.com/Rinnegatamante/Android2Vita-Candidate-Ports-List/issues), possibly if a developer it's interested it could be ported.

**3) Wouldn't it be easier to develop an overarching "vita porter" than to pick/ choose at individual games?**

- No, that's not the case. Some games on the Vita were able to be transferred because they utilize a specific game engine that has already been adapted for the Vita, thus making the process of porting them feasible and straightforward. However, not all games employ the same game engine, and it's entirely conceivable that the engine may not have been adapted for the Vita at all. Porting processes are unique to each game because, even if the game engine has been adapted, there are numerous adjustments that need to be made, and these adjustments can't be easily automated.

**4) How can I learn how to port?**

- There is no porting tutorials as each game has it's own things to be wrapped. You can learn by reading online, forums, discord servers as well as checking on github how people have ported games.

 ** 5) Can I contribute?

- Of course, open a pull request and it will be checked.
- 
<a name="section7"></a>

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


<a name="section8"></a>

## Build Instructions (For Developers)

In order to build the loader, you'll need a [vitasdk](https://github.com/vitasdk) build fully compiled with softfp usage.  
You can find a precompiled version here: https://github.com/vitasdk/buildscripts/actions/runs/1102643776.  
Additionally, you'll need these libraries to be compiled as well with `-mfloat-abi=softfp` added to their CFLAGS:

- [SDL2_vitagl](https://github.com/Northfear/SDL/tree/vitagl)

- [libmathneon](https://github.com/Rinnegatamante/math-neon)

  - ```bash
    make install
    ```

- [vitaShaRK](https://github.com/Rinnegatamante/vitaShaRK)

  - ```bash
    make install
    ```

- [kubridge](https://github.com/TheOfficialFloW/kubridge)

  - ```bash
    mkdir build && cd build
    cmake .. && make install
    ```

- [vitaGL](https://github.com/Rinnegatamante/vitaGL)

  - ````bash
    make SOFTFP_ABI=1 HAVE_GLSL_SUPPORT=1 NO_DEBUG=1 install
    ````

After all these requirements are met, you can compile the loader with the following commands:

```bash
mkdir build && cd build
cmake .. && make
```

