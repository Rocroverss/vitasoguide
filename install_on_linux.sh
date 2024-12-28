#!/bin/bash

# Define helper function for logging errors
log_error() {
  echo "ERROR: $1"
  exit 1
}

# Check if required dependencies are installed
echo "Checking required dependencies..."
required_packages=("git" "cmake" "python3" "curl" "make" "gcc" "g++")

for package in "${required_packages[@]}"; do
  if ! command -v "$package" &>/dev/null; then
    log_error "Required package '$package' is not installed. Please install it first."
  fi
done

# Define GitHub repository URLs (public repositories)
VITASDK_REPO="https://github.com/vitasdk-softfp/vdpm"
VITAGL_REPO="https://github.com/Rinnegatamante/vitaGL.git"
GL33NTWINE_REPO="https://github.com/v-atamanenko/soloader-boilerplate.git"

# Define the target include directory
INCLUDE_DIR="/usr/local/vitasdk/arm-vita-eabi/include"

# Function to clone a repo using HTTPS (for public repositories)
clone_repo() {
  local repo_url=$1
  local destination=$2
  if git clone "$repo_url" "$destination"; then
    echo "Successfully cloned $repo_url into $destination"
  else
    log_error "Failed to clone $repo_url"
  fi
}

# Function to install CMake if missing
install_cmake() {
  echo "Checking for CMake installation..."
  if ! command -v cmake &>/dev/null; then
    echo "CMake not found. Installing CMake..."
    
    # Attempt to install via package manager
    if command -v apt &>/dev/null; then
      sudo apt update && sudo apt install -y cmake || log_error "Failed to install CMake using apt."
    elif command -v yum &>/dev/null; then
      sudo yum install -y cmake || log_error "Failed to install CMake using yum."
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y cmake || log_error "Failed to install CMake using dnf."
    elif command -v brew &>/dev/null; then
      brew install cmake || log_error "Failed to install CMake using Homebrew."
    else
      log_error "No supported package manager found. Please install CMake manually."
    fi
  else
    echo "CMake is already installed."
  fi
}

install_VitaSDK(){
  echo "Installing VitaSDK with softfp..."
  if [ ! -d "$HOME/vitasdk" ]; then
    echo "Cloning VitaSDK..."
    clone_repo "$VITASDK_REPO" "$HOME/vitasdk-installer"
    cd "$HOME/vitasdk-installer" || log_error "Failed to enter VitaSDK directory."
    ./bootstrap-vitasdk.sh || log_error "VitaSDK bootstrap failed."
    ./install-all.sh || log_error "VitaSDK installation failed."
    source ~/.bashrc
  else
    echo "VitaSDK already installed."
  fi

  # Install vitasdk packages
  if [ ! -d "/usr/local/vitasdk/vitasdk-packages" ]; then
    echo "Cloning VitaSDK packages..."
    git clone https://github.com/vitasdk/packages.git /usr/local/vitasdk/vitasdk-packages 
  fi

  #cd /usr/local/vitasdk/vitasdk-packages || log_error "Failed to enter VitaSDK packages directory."
  #./install_or_build.sh || log_error "VitaSDK packages installation failed."
}


# Function to copy files with checks
copy_files() {
  SRC_DIR="$1"
  DEST_DIR="$2"
  LIB_NAME="$3"

  if [ -d "$SRC_DIR" ]; then
    echo "Copying $LIB_NAME libs from $SRC_DIR to $DEST_DIR..."
    cp -r "$SRC_DIR"/* "$DEST_DIR"/
    echo "$LIB_NAME libs copied successfully!"
  else
    echo "Warning: $SRC_DIR does not exist. Skipping $LIB_NAME libs."
  fi
}

install_vitaGL_REQUIRED_LIBS() {
# Step 1.5: Install vitashark
echo "Installing vitashark..."
cd /usr/local/vitasdk || log_error "Failed to navigate to /usr/local/vitasdk."

# Clone vitashark repository
if [ ! -d "/usr/local/vitasdk/vitaShaRK" ]; then
  echo "Cloning vitaShaRK..."
  git clone https://github.com/Rinnegatamante/vitaShaRK.git
  git clone https://github.com/Rinnegatamante/vitaShaRK.git "/usr/local/vitasdk/arm-vita-eabi/include/vitaShaRK" || log_error "Failed to clone vitaShaRK repository."
else
  echo "vitaShaRK is already cloned."
fi

# Clone SceShaccCgExt repository
if [ ! -d "/usr/local/vitasdk/SceShaccCgExt" ]; then
  echo "Cloning SceShaccCgExt..."
  git clone https://github.com/bythos14/SceShaccCgExt.git "/usr/local/vitasdk/arm-vita-eabi/include/SceShaccCgExt" || log_error "Failed to clone SceShaccCgExt repository."
else
  echo "SceShaccCgExt is already cloned."
fi
# Clone math-neon repository
if [ ! -d "/usr/local/vitasdk/SceShaccCgExt" ]; then
  echo "Cloning math-neon..."
  git clone https://github.com/andrepuschmann/math-neon.git "/usr/local/vitasdk/arm-vita-eabi/include/math-neon" || log_error "Failed to clone math-neon repository."
else
  echo "math-neon is already cloned."
fi

# Copy vitaShaRK libraries
copy_files "$INCLUDE_DIR/vitaShaRK/source" "$INCLUDE_DIR" "vitaShaRK"

# Copy SceShaccCgExt libraries
copy_files "$INCLUDE_DIR/SceShaccCgExt/include" "$INCLUDE_DIR" "SceShaccCgExt (include)"
copy_files "$INCLUDE_DIR/SceShaccCgExt/src" "$INCLUDE_DIR" "SceShaccCgExt (src)"

# Copy math-neon libraries
copy_files "$INCLUDE_DIR/math-neon/src" "$INCLUDE_DIR" "math-neon"
echo "All libraries processed."
}

install_vitagl(){
# Step 2: Install VitaGL
echo "Installing VitaGL..."
if [ ! -d "/usr/local/vitasdk/arm-vita-eabi" ]; then
  log_error "VitaSDK installation is incomplete. Please check the installation process."
fi

# Check if VitaGL is already installed
if [ ! -d "$VITASDK/arm-vita-eabi/include/vitaGL" ]; then
  echo "VitaGL not found. Cloning the repository..."
  # Clone VitaGL repository
  clone_repo "$VITAGL_REPO" "$VITASDK/arm-vita-eabi/include/vitaGL" || log_error "Failed to clone VitaGL repository."

  # Navigate to the VitaGL directory
  cd "$VITASDK/arm-vita-eabi/include/vitaGL" || log_error "Failed to enter VitaGL directory."

  # Install required libraries (function needs to be defined elsewhere)
  echo "Installing VitaGL required libs..."
  install_vitaGL_REQUIRED_LIBS || log_error "Failed to install required libraries for VitaGL."

  # Build VitaGL
  echo "Building VitaGL..."
  cd "$VITASDK/arm-vita-eabi/include/vitaGL" || log_error "Failed to enter VitaGL directory."
  echo "Current directory: $(pwd)"  # Debugging step
  ls -l  # Check if the Makefile exists
  make || log_error "VitaGL compilation failed."


  # Copy the built library to the VitaSDK lib folder
  echo "Installing VitaGL library..."
  if [ -f "libvitaGL.a" ]; then
    cp libvitaGL.a "$VITASDK/arm-vita-eabi/lib/" || log_error "Failed to copy VitaGL library."

    # Copy headers
    echo "Installing VitaGL headers..."
    cp -r $VITASDK/arm-vita-eabi/include/vitaGL/source/* $VITASDK/arm-vita-eabi/include/ || log_error "Failed to copy VitaGL headers."
    cp -r $VITASDK/arm-vita-eabi/include/vitaGL/source/utils/* $VITASDK/arm-vita-eabi/include/ || log_error "Failed to copy VitaGL headers."
    cp -r $VITASDK/arm-vita-eabi/include/vitaGL/source/shaders/* $VITASDK/arm-vita-eabi/include/ || log_error "Failed to copy VitaGL headers."
    cp -r $VITASDK/arm-vita-eabi/include/vitaGL/source/shaders/texture_combiners/* $VITASDK/arm-vita-eabi/include/ || log_error "Failed to copy VitaGL headers."

    echo "VitaGL installed successfully!"
  else
    log_error "VitaGL compilation failed. 'libvitaGL.a' not found."
  fi
else
  echo "VitaGL is already installed."
fi
}


install_rest() {
# Step 3: Clone the gl33ntwine Port Template
echo "Cloning gl33ntwine port template..."
cd "$HOME" || log_error "Failed to navigate to home directory."
clone_repo "$GL33NTWINE_REPO" "$HOME/gl33ntwine"  # Cloning using HTTPS for public repo

cd gl33ntwine || log_error "Failed to enter gl33ntwine directory."

# Step 4: Edit CMAkelists.txt (Automate if possible, or ask user to configure)
echo "Editing CMAkelists.txt... (you may need to manually tweak the configuration)"
echo "Ensure the CMAkelists.txt is set up according to your port's requirements."

# Automatically set basic variables if the CMAkelists.txt is in a known state
sed -i 's/PROJECT_NAME "project_name"/PROJECT_NAME "Baba is You"/' CMAkelists.txt || log_error "Failed to modify CMAkelists.txt."

# Step 5: Prepare Build Directory
echo "Preparing build directory..."
mkdir -p build
cd build || log_error "Failed to navigate to build directory."

# Step 6: Build the Project
echo "Building the project..."
cmake .. -DCMAKE_TOOLCHAIN_FILE="$VITASDK/share/vita.toolchain.cmake" || log_error "CMake configuration failed."

# Optionally enable verbose output for debugging
echo "Running make with verbose output..."
make VERBOSE=1 || log_error "Compilation failed. Check the output for errors."

# Step 7: Verify successful build
if [ ! -f "eboot.bin" ]; then
  log_error "Build failed. No 'eboot.bin' found in the build directory."
else
  echo "Build successful! You can now test your port on the PS Vita."
fi

# Step 8: Test the port on your PS Vita (use FTP to transfer)
echo "Testing on PS Vita..."
echo "You should now transfer 'eboot.bin' and the necessary files to your PS Vita using FTP."
echo "Run the following commands to upload and launch the app on your PS Vita:"
echo "1. Upload eboot.bin via FTP: curl -T eboot.bin ftp://<psvita_ip>:1337/ux0:/app/<title_id>/"
echo "2. Launch the app: echo launch <title_id> | nc <psvita_ip> 1338"

# Common Issues and Debugging Tips:
echo "Common issues and debugging tips:"
echo "1. VitaSDK installation fails: Ensure dependencies are installed and you're using the correct softfp setup."
echo "2. Compilation errors: Make sure CMAkelists.txt is correctly set up and matches your environment."
echo "3. Use the VitaGL logging feature to trace OpenGL calls if you're having issues with graphics."
echo "4. Enable verbose output in cmake for detailed error tracking: cmake -DCMAKE_VERBOSE_MAKEFILE=ON .."

echo "Done!"
}

test_VitaSDK() {
  echo "Testing VitaSDK installation..."
  temp_dir=$(mktemp -d)
  echo "Compiling a simple test project in $temp_dir..."
  cat <<EOL > "$temp_dir/main.c"
#include <stdio.h>
int main() {
    printf("Hello from VitaSDK!\n");
    return 0;
}
EOL
  arm-vita-eabi-gcc "$temp_dir/main.c" -o "$temp_dir/main.elf" &>/dev/null
  if [ -f "$temp_dir/main.elf" ]; then
    echo "VitaSDK is installed and working correctly!"
    rm -rf "$temp_dir"
  else
    log_error "VitaSDK test failed. Ensure the SDK is properly installed."
  fi
}

test_vitagl() {
  echo "Testing VitaGL installation..."
  sleep 5
  if [ -f "$VITASDK/arm-vita-eabi/lib/libvitaGL.a" ]; then
    echo "Compiling a sample project using VitaGL..."
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    # Updated sample project
    cat <<EOL > "$temp_dir/main.c"
// Drawing a rotating cube with VBO
#include <vitaGL.h>
#include <math.h>

// Helper macro to get offset in a VBO for an element without having compilation warnings
#define BUF_OFFS(i) ((void*)(i))

float colors[] = {1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0}; // Colors for a face
float vertices_front[] = {-0.5f, -0.5f, -0.5f, 0.5f, -0.5f, -0.5f, -0.5f, 0.5f, -0.5f, 0.5f, 0.5f, -0.5f}; // Front Face
float vertices_back[] = {-0.5f, -0.5f, 0.5f, 0.5f, -0.5f, 0.5f, -0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f}; // Back Face
float vertices_left[] = {-0.5f, -0.5f, -0.5f, -0.5f, 0.5f, -0.5f, -0.5f, -0.5f, 0.5f, -0.5f, 0.5f, 0.5f}; // Left Face
float vertices_right[] = {0.5f, -0.5f, -0.5f, 0.5f, 0.5f, -0.5f, 0.5f, -0.5f, 0.5f, 0.5f, 0.5f, 0.5f}; // Right Face
float vertices_top[] = {-0.5f, -0.5f, -0.5f, 0.5f, -0.5f, -0.5f, -0.5f, -0.5f, 0.5f, 0.5f, -0.5f, 0.5f}; // Top Face
float vertices_bottom[] = {-0.5f, 0.5f, -0.5f, 0.5f, 0.5f, -0.5f, -0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f}; // Bottom Face

// Buffers used for EBO and VBO
GLuint buffers[2];

uint16_t indices[] = {
	 0, 1, 2, 1, 2, 3, // Front
	 4, 5, 6, 5, 6, 7, // Back
	 8, 9,10, 9,10,11, // Left
	12,13,14,13,14,15, // Right
	16,17,18,17,18,19, // Top
	20,21,22,21,22,23  // Bottom
};

int main(){
	// Initializing graphics device
	vglInit(0x80000);

	// Enabling V-Sync
	vglWaitVblankStart(GL_TRUE);
	
	// Creating VBO data with vertices + colors
	float vbo[12*12];
	memcpy(&vbo[12*0], &vertices_front[0], sizeof(float) * 12);
	memcpy(&vbo[12*1], &vertices_back[0], sizeof(float) * 12);
	memcpy(&vbo[12*2], &vertices_left[0], sizeof(float) * 12);
	memcpy(&vbo[12*3], &vertices_right[0], sizeof(float) * 12);
	memcpy(&vbo[12*4], &vertices_top[0], sizeof(float) * 12);
	memcpy(&vbo[12*5], &vertices_bottom[0], sizeof(float) * 12);
	memcpy(&vbo[12*6], &colors[0], sizeof(float) * 12);
	memcpy(&vbo[12*7], &colors[0], sizeof(float) * 12);
	memcpy(&vbo[12*8], &colors[0], sizeof(float) * 12);
	memcpy(&vbo[12*9], &colors[0], sizeof(float) * 12);
	memcpy(&vbo[12*10], &colors[0], sizeof(float) * 12);
	memcpy(&vbo[12*11], &colors[0], sizeof(float) * 12);
	
	// Creating two buffers for colors, vertices and indices
	glGenBuffers(2, buffers);
	
	// Setting up VBO
	glBindBuffer(GL_ARRAY_BUFFER, buffers[0]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * 12 * 12, vbo, GL_STATIC_DRAW);
	
	// Setting up EBO
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(uint16_t) * 6 * 6, indices, GL_STATIC_DRAW);
	
	// Setting clear color
	glClearColor (0.0f, 0.0f, 0.0f, 0.0f);
	
	// Initializing mvp matrix with a perspective full screen matrix
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(90.0f, 960.f/544.0f, 0.01f, 100.0f);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glTranslatef(0.0f, 0.0f, -3.0f); // Centering the cube

	// Enabling depth test
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LESS);
	
	// Main loop
	for (;;) {
		// Clear color and depth buffers
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		
		// Drawing our cube with VBO
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_COLOR_ARRAY);
		glVertexPointer(3, GL_FLOAT, 0, BUF_OFFS(0));
		glColorPointer(3, GL_FLOAT, 0, BUF_OFFS(12*6*sizeof(float)));
		glRotatef(1.0f, 0.0f, 0.0f, 1.0f); // Rotating cube at each frame by 1 on axis x and axis w
		glRotatef(0.5f, 0.0f, 1.0f, 0.0f); // Rotating cube at each frame by 0.5 on axis x and 1.0 on axis z
		glDrawElements(GL_TRIANGLES, 6*6, GL_UNSIGNED_SHORT, BUF_OFFS(0));
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
		
		// Performing buffer swap
		vglSwapBuffers(GL_FALSE);
	}

	// Terminating graphics device	
	vglEnd();
}
EOL

    # Updated sample project
    cat <<EOL > "$temp_dir/makefile"
TITLEID     := VGLVBORCB
TARGET		:= vbo_rotating_cube
SOURCES		:= .
			
INCLUDES	:= include

LIBS = -lvitaGL -lc -lSceCommonDialog_stub -lm -lSceGxm_stub -lSceDisplay_stub -lSceAppMgr_stub -lmathneon \
	-lvitashark -lSceShaccCgExt -ltaihen_stub -lSceShaccCg_stub -lSceKernelDmacMgr_stub

CFILES   := $(foreach dir,$(SOURCES), $(wildcard $(dir)/*.c))
CPPFILES   := $(foreach dir,$(SOURCES), $(wildcard $(dir)/*.cpp))
BINFILES := $(foreach dir,$(DATA), $(wildcard $(dir)/*.bin))
OBJS     := $(addsuffix .o,$(BINFILES)) $(CFILES:.c=.o) $(CPPFILES:.cpp=.o) 

PREFIX  = arm-vita-eabi
CC      = $(PREFIX)-gcc
CXX      = $(PREFIX)-g++
CFLAGS  = -g -Wl,-q -O2 -ftree-vectorize
CXXFLAGS  = $(CFLAGS) -fno-exceptions -std=gnu++11 -fpermissive
ASFLAGS = $(CFLAGS)

all: $(TARGET).vpk

$(TARGET).vpk: eboot.bin
	vita-mksfoex -s TITLE_ID=$(TITLEID) "$(TARGET)" param.sfo
	vita-pack-vpk -s param.sfo -b eboot.bin $@

eboot.bin: $(TARGET).velf
	vita-make-fself -s $< eboot.bin	
	
%.velf: %.elf
	vita-elf-create $< $@
	
$(TARGET).elf: $(OBJS)
	$(CC) $(CFLAGS) $^ $(LIBS) -o $@
	
clean:
	@rm -rf *.velf *.elf *.vpk $(OBJS) param.sfo eboot.bin
EOL

    # Compile the sample project
    #arm-vita-eabi-gcc "$temp_dir/main.c" -o "$temp_dir/main.elf" -lvitaGL -lSceDisplay -lSceCtrl
    make || log_error "Compilation failed. Check the output for errors."
    if [ -f "$temp_dir/main.elf" ]; then
      echo "VitaGL is installed and working correctly!"
    else
      log_error "VitaGL test failed. Ensure VitaGL is properly installed."
    fi
  else
    log_error "VitaGL is not installed. Install it first."
  fi
}

install_cmake
install_VitaSDK
test_VitaSDK
install_vitagl
test_vitagl
#install_rest
