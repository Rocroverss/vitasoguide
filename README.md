# vitaports
 vitaports_basics:
- Welcome to Vitaports, your comprehensive resource for porting Android games to the PlayStation Vita platform. Whether you're a seasoned developer or just starting out, Vitaports offers the tools, guidelines, and community support you need to bring your favorite Android titles to the Vita.
 
 ## Index:

 
  ## Table of Contents
- [Section 1](#section1)
- [Section 2](#section2)

## Section 1
<a name="section1"></a>

Content of Section 1

## Section 2
<a name="section2"></a>

Content of Section 2

  
# rocroverss apk port checker:

This python scripts check if these rules are followed: https://github.com/Rinnegatamante/Android2Vita-Candidate-Ports-List

Usage guide:

1) Download apk tool: https://apktool.org/
2) have python installed (3.12 in my case).
3) Execute the apk_port_validator.py.
4) Locate the apk and the apk tool.
5) Press on extract apk.
6) Press on check (each case can be a different scenario false positive/negative might occur).

# gl33ntwine port template:
- Port template: https://github.com/v-atamanenko/soloader-boilerplate

# VitaSDK
- VitaSDK: https://github.com/vitasdk
- VitaSDK precompiled: https://github.com/vitasdk/buildscripts/releases

# Vitagl
- Vitagl: https://github.com/Rinnegatamante/vitaGL
- Vitagl precompiled: https://github.com/Rinnegatamante/vitaGL/tree/legacy_precompiled_ffp

# Rinnegatamante basic rules:

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

# How to start a port:

1) Understanding Android App Functionality:
To begin, it's essential to grasp the workings of an Android application.
![Lifetime of an android app](https://raw.githubusercontent.com/Rocroverss/vitasoguide/main/img/lifecycle_of%20andoird_apps.png)
2) Inspecting the Dex File:
 - Next, examine the Dex file to identify the methods it contains. Analyze these methods to determine which native functions they call, their order, and the arguments passed
3) Translate to vitagl: https://github.com/Rinnegatamante/vitaGL/blob/master/source/vitaGL.h
4) Get back to the rinnegatamates basic rules.

# Build Instructions (For Developers)

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

# Example of porting a slice of code (fix for a port that made rinnegatamante):
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

# Another porting block example:
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


# FAQ:
**1) Can I port X game to psvita?**

- Well there are some ways to port games to psvita, but unfortunately this guide is focused on android games that are compatible with .so loader. To check if the apk is a candidate use the port checker. After figure it out to port it propertly.

**2) Can someone port X game to psvita?**

- Check the apk port checker and after open an [issue](https://github.com/Rinnegatamante/Android2Vita-Candidate-Ports-List/issues), possibly if a developer it's interested it could be ported.

**3) Wouldn't it be easier to develop an overarching "vita porter" than to pick/ choose at individual games?**

- No, that's not the case. Some games on the Vita were able to be transferred because they utilize a specific game engine that has already been adapted for the Vita, thus making the process of porting them feasible and straightforward. However, not all games employ the same game engine, and it's entirely conceivable that the engine may not have been adapted for the Vita at all. Porting processes are unique to each game because, even if the game engine has been adapted, there are numerous adjustments that need to be made, and these adjustments can't be easily automated.

**4) How can I learn how to port?**

- There is no porting tutorials as each game has it's own things to be wrapped. You can learn by reading online, forums, discord servers as well as checking on github how people have ported games. 


