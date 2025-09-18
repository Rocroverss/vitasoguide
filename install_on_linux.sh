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

  echo "Cloning vitaShaRK..."
  git clone https://github.com/Rinnegatamante/vitaShaRK.git "/usr/local/vitasdk/arm-vita-eabi/include/vitaShaRK" || log_error "Failed to clone vitaShaRK repository."
  echo "Cloning SceShaccCgExt..."
  git clone https://github.com/bythos14/SceShaccCgExt.git "/usr/local/vitasdk/arm-vita-eabi/include/SceShaccCgExt" || log_error "Failed to clone SceShaccCgExt repository."
  echo "Cloning math-neon..."
  git clone https://github.com/andrepuschmann/math-neon.git "/usr/local/vitasdk/arm-vita-eabi/include/math-neon" || log_error "Failed to clone math-neon repository."
  echo "Cloning math-neon-rinne..."
  git clone https://github.com/Rinnegatamante/math-neon.git "/usr/local/vitasdk/arm-vita-eabi/include/math-neon-rinne" || log_error "Failed to clone math-neon repository."
  echo "Cloning taiHEN..."
  git clone https://github.com/yifanlu/taiHEN.git "/usr/local/vitasdk/arm-vita-eabi/include/taiHEN" || log_error "Failed to clone taiHEN repository."

# Clone math-neon repository
if [ ! -d "/usr/local/vitasdk/taiHEN" ]; then
  # Navigate to the taiHEN repository
  cd "/usr/local/vitasdk/arm-vita-eabi/include/taiHEN" || log_error "Failed to navigate to taiHEN directory."
  # Copy files to destination, excluding CMakeLists.txt
  echo "Copying taiHEN contents to /usr/local/vitasdk/arm-vita-eabi/include..."
  find . -type f ! -name "CMakeLists.txt" -exec cp --parents -n {} /usr/local/vitasdk/arm-vita-eabi/include/ \;
  # Confirm completion
  echo "Contents copied successfully, existing files were preserved."
else
  echo "taiHEN is already cloned."
fi
cd /usr/local/vitasdk || log_error "Failed to navigate to /usr/local/vitasdk."

# Clone SceShaccCgExt repository
if [ ! -d "/usr/local/vitasdk/SceShaccCgExt" ]; then
  cd /usr/local/vitasdk/arm-vita-eabi/include/SceShaccCgExt
  mkdir build
  cd build 
  cmake ..
  make
  cp /usr/local/vitasdk/arm-vita-eabi/include/SceShaccCgExt/build/libSceShaccCgExt.a /usr/local/vitasdk/arm-vita-eabi/lib
else
  echo "SceShaccCgExt is already cloned."
fi
cd /usr/local/vitasdk || log_error "Failed to navigate to /usr/local/vitasdk."

# Copy SceShaccCgExt libraries
copy_files "$INCLUDE_DIR/SceShaccCgExt/include" "$INCLUDE_DIR" "SceShaccCgExt (include)"
copy_files "$INCLUDE_DIR/SceShaccCgExt/src" "$INCLUDE_DIR" "SceShaccCgExt (src)"


# Clone vitashark repository
if [ ! -d "/usr/local/vitasdk/vitaShaRK" ]; then
  cd /usr/local/vitasdk/arm-vita-eabi/include/vitaShaRK
  make VERBOSE=1
  cp /usr/local/vitasdk/arm-vita-eabi/include/vitaShaRK/libvitashark.a /usr/local/vitasdk/arm-vita-eabi/lib
else
  echo "vitaShaRK is already cloned."
fi
cd /usr/local/vitasdk || log_error "Failed to navigate to /usr/local/vitasdk."

# Copy vitaShaRK libraries
copy_files "$INCLUDE_DIR/vitaShaRK/source" "$INCLUDE_DIR" "vitaShaRK"

cd /usr/local/vitasdk || log_error "Failed to navigate to /usr/local/vitasdk."
# Download the tarball directly to the destination directory
echo "Downloading taihen.tar.gz..."
wget -O /usr/local/vitasdk/taihen.tar.gz https://github.com/yifanlu/taiHEN/releases/download/v0.11/taihen.tar.gz || log_error "Failed to download taihen.tar.gz."
# Extract the tarball in place
echo "Extracting taihen.tar.gz..."
tar -xzf /usr/local/vitasdk/taihen.tar.gz -C /usr/local/vitasdk || log_error "Failed to extract taihen.tar.gz."
# Remove the tarball after extraction
rm /usr/local/vitasdk/taihen.tar.gz
# Confirm success
echo "taihen.tar.gz downloaded and extracted successfully in /usr/local/vitasdk/arm-vita-eabi/lib."

cp /usr/local/vitasdk/lib/libtaihenForKernel_stub.a /usr/local/vitasdk/arm-vita-eabi/lib
cp /usr/local/vitasdk/lib/libtaihen_stub_weak.a /usr/local/vitasdk/arm-vita-eabi/lib
cp /usr/local/vitasdk/lib/libtaihen_stub.a /usr/local/vitasdk/arm-vita-eabi/lib
cp /usr/local/vitasdk/lib/libtaihenModuleUtils_stub.a /usr/local/vitasdk/arm-vita-eabi/lib

cd /usr/local/vitasdk/arm-vita-eabi/include/math-neon-rinne
make
cp /usr/local/vitasdk/arm-vita-eabi/include/math-neon-rinne/libmathneon.a /usr/local/vitasdk/arm-vita-eabi/lib || log_error "No file or directory"
#cp /usr/local/vitasdk/arm-vita-eabi/include/math-neon-rinne/libmathneon.a
echo "math-neon-rinne is cloppied."
cd /usr/local/vitasdk || log_error "Failed to navigate to /usr/local/vitasdk."

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
  pwd
  if [ -f "$VITASDK/arm-vita-eabi/lib/libvitaGL.a" ]; then
    echo "Compiling a sample project using VitaGL..."
    
    # Navigate to the sample project directory
    sample_dir="/usr/local/vitasdk/arm-vita-eabi/include/vitaGL/samples/rotating_cube"
    if [ ! -d "$sample_dir" ]; then
      echo "Sample project directory not found: $sample_dir"
      exit 1
    fi

    cd "$sample_dir" || exit
    make clean
    make || { echo "Compilation failed. Check the output for errors."; exit 1; }

    # Check if the VPK file was generated
    if [ -f "$sample_dir/rotating_cube.vpk" ]; then
      echo "VitaGL is installed and working correctly!"
    else
      echo "VitaGL test failed. Ensure VitaGL is properly installed."
    fi
  else
    echo "VitaGL is not installed. Install it first."
  fi
}

compile_sdl2_vitagl() {
  echo "Compiling Northfear's fork of SDL2 with VitaGL backend..."
  sleep 5

  # Navigate to a working directory
  working_dir="/usr/local/vitasdk"
  if [ ! -d "$working_dir" ]; then
    echo "Working directory not found: $working_dir"
    exit 1
  fi

  cd "$working_dir" || exit

  # Clone the SDL2 repository
  repo_url="https://github.com/Northfear/SDL.git"
  project_dir="$working_dir/SDL"
  if [ -d "$project_dir" ]; then
    echo "Repository already cloned. Pulling latest changes..."
    cd "$project_dir" || exit
    git pull || { echo "Failed to pull latest changes. Exiting."; exit 1; }
  else
    echo "Cloning repository..."
    git clone "$repo_url" || { echo "Failed to clone repository. Exiting."; exit 1; }
    cd "$project_dir" || exit
  fi

  # Checkout the VitaGL branch
  echo "Checking out the VitaGL branch..."
  git checkout vitagl || { echo "Failed to checkout 'vitagl' branch. Exiting."; exit 1; }

  # Configure and build SDL2
  build_dir="$project_dir/build"
  echo "Running CMake configuration..."
  cmake -S. -B"$build_dir" \
    -DCMAKE_TOOLCHAIN_FILE="${VITASDK}/share/vita.toolchain.cmake" \
    -DCMAKE_BUILD_TYPE=Release \
    -DVIDEO_VITA_VGL=ON || { echo "CMake configuration failed. Exiting."; exit 1; }

  echo "Building SDL2..."
  cmake --build "$build_dir" -- -j"$(nproc)" || { echo "Build failed. Exiting."; exit 1; }

  echo "Installing SDL2..."
  cmake --install "$build_dir" || { echo "Installation failed. Exiting."; exit 1; }

  echo "Northfear's SDL2 with VitaGL backend successfully compiled and installed!"
}

install_stb_library() {
  echo "Installing stb libraries..."

  # Define the destination and repository
  destination="/usr/local/vitasdk/include/stb"
  #destination="/usr/local/vitasdk/lib/stb"
  repo_url="https://github.com/nothings/stb.git"

  # Check if the destination directory exists, create it if not
  if [ ! -d "$destination" ]; then
    echo "Creating destination directory: $destination"
    mkdir -p "$destination" || { echo "Failed to create directory. Exiting."; exit 1; }
  fi

  # Navigate to a working directory for cloning
  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT

  echo "Cloning stb repository..."
  git clone "$repo_url" "$temp_dir" || { echo "Failed to clone stb repository. Exiting."; exit 1; }

  # Copy the header files to the destination
  echo "Installing stb headers to $destination..."
  cp "$temp_dir"/*.h "$destination" || { echo "Failed to copy header files. Exiting."; exit 1; }

  echo "stb libraries successfully installed to $destination"
}

install_zlib_vitasdk() {
    # Define the installation paths
    VITASDK_PREFIX="/usr/local/vitasdk/arm-vita-eabi"
    INCLUDE_DIR="${VITASDK_PREFIX}/include"
    LIB_DIR="${VITASDK_PREFIX}/lib"

    # Ensure directories exist
    mkdir -p "$INCLUDE_DIR" "$LIB_DIR"

    # Define the zlib version and source URL
    ZLIB_VERSION="1.3.1"
    ZLIB_URL="https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz"

    # Download zlib source
    echo "Downloading zlib ${ZLIB_VERSION}..."
    wget -q "$ZLIB_URL" -O "zlib-${ZLIB_VERSION}.tar.gz"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download zlib."
        return 1
    fi

    # Extract the source code
    echo "Extracting zlib..."
    tar -xf "zlib-${ZLIB_VERSION}.tar.gz"
    cd "zlib-${ZLIB_VERSION}" || return 1

    # Use vita tools for compilation
    export CC=arm-vita-eabi-gcc
    export AR=arm-vita-eabi-ar
    export RANLIB=arm-vita-eabi-ranlib
    export STRIP=arm-vita-eabi-strip

    # Build and install zlib for VitaSDK
    echo "Building and installing zlib for VitaSDK..."
    ./configure --prefix="$VITASDK_PREFIX"
    if [ $? -ne 0 ]; then
        echo "Error: Configuration failed."
        return 1
    fi

    make
    if [ $? -ne 0 ]; then
        echo "Error: Build failed."
        return 1
    fi

    make install
    if [ $? -ne 0 ]; then
        echo "Error: Installation failed."
        return 1
    fi

    # Clean up
    cd ..
    rm -rf "zlib-${ZLIB_VERSION}" "zlib-${ZLIB_VERSION}.tar.gz"

    echo "zlib installed successfully in $VITASDK_PREFIX"
}

install_opensles_vitasdk() {
    # Define paths
    VITASDK_PREFIX="/usr/local/vitasdk/arm-vita-eabi"
    INCLUDE_DIR="${VITASDK_PREFIX}/include"
    LIB_DIR="${VITASDK_PREFIX}/lib"

    # Ensure the target directories exist
    mkdir -p "$INCLUDE_DIR" "$LIB_DIR"

    # Clone the OpenSLES repository
    echo "Cloning OpenSLES repository..."
    git clone https://github.com/Rinnegatamante/opensles.git /usr/local/vitasdk/opensles 
    if [ $? -ne 0 ]; then
        echo "Error: Failed to clone OpenSLES repository."
        return 1
    fi

    # Navigate to the repository
    cd /usr/local/vitasdk/opensles || return 1

    # Build the OpenSLES library
    echo "Building OpenSLES..."
    make
    if [ $? -ne 0 ]; then
        echo "Error: Build failed."
        cd ..
        #rm -rf opensles
        return 1
    fi

    # Install the headers and library
    echo "Installing OpenSLES..."
    cp -r include/SLES "$INCLUDE_DIR"
    cp libopenSLES.a "$LIB_DIR"

    # Clean up
    cd ..
    #rm -rf opensles

    echo "OpenSLES successfully installed in $VITASDK_PREFIX"
}

test_android_port_compilation() {
  echo "Testing Android port compilation..."
  sleep 5
  
  # Navigate to the VITASDK directory
  sdk_dir="/usr/local/vitasdk/"
  if [ ! -d "$sdk_dir" ]; then
    echo "VITASDK directory not found: $sdk_dir"
    exit 1
  fi

  cd "$sdk_dir" || exit

  # Clone the repository
  repo_url="https://github.com/v-atamanenko/baba-is-you-vita.git"
  project_dir="$sdk_dir/baba-is-you-vita"
  if [ -d "$project_dir" ]; then
    echo "Repository already cloned. Pulling latest changes..."
    cd "$project_dir" || exit
    git pull || { echo "Failed to pull latest changes. Exiting."; exit 1; }
  else
    echo "Cloning repository..."
    git clone "$repo_url" || { echo "Failed to clone repository. Exiting."; exit 1; }
    cd "$project_dir" || exit
  fi
  cd "$project_dir/lib/libc_bridge"
  make || { echo "Compilation of "libSceLibcBridge_stub.a" failed. Check the output for errors."; exit 1; }
  cp "/usr/local/vitasdk/include/stb"/*.h "$project_dir/lib/stb" || { echo "Failed to copy all stb .h files. Exiting."; exit 1; } 
  # Create and navigate to the build directory
  build_dir="$project_dir/build"
  mkdir -p "$build_dir"
  cd "$build_dir" || exit

  # Run CMake and make
  echo "Running CMake..."
  cmake .. || { echo "CMake configuration failed. Exiting."; exit 1; }
  echo "Compiling project..."
  make || { echo "Compilation failed. Check the output for errors."; exit 1; }

  # Check if the VPK file was generated
  vpk_file="$build_dir/BABAISYOU.vpk"
  if [ -f "$vpk_file" ]; then
    echo "Android port compiled successfully! VPK generated: $vpk_file"
  else
    echo "Compilation failed. VPK not generated."
    exit 1
  fi
}

# Function to print the box
echo_box() {
    # Print top border
    echo -e "${GREEN}#########################################${NC}"
    # Print the message in the center
    echo -e "${GREEN}# You did it, workspace installed,       #${NC}"
    echo -e "${GREEN}# you can start porting!               #${NC}"
    # Print bottom border
    echo -e "${GREEN}#########################################${NC}"
}


install_cmake
install_VitaSDK
test_VitaSDK
install_vitagl
test_vitagl
compile_sdl2_vitagl
install_stb_library
install_zlib_vitasdk
#install_opensles_vitasdk
test_android_port_compilation
echo_box

#install_rest
