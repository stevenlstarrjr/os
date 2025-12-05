cmake_minimum_required(VERSION 3.20)

include(ExternalProject)

# =========================================================
# 1. SETUP DIRECTORY STRUCTURE (The "Holy Trinity")
# =========================================================
# We define these explicitly so we know exactly where things go.
# All of these live inside the BUILD TREE (e.g., build/ports/boost/...)
set(PORT_NAME "boost")
set(PORT_VERSION "1.83.0")
set(PKG_FILENAME "${PORT_NAME}-${PORT_VERSION}-${TARGET_OS}-${TARGET_ARCH}.zip")

set(MY_SRC     "${CMAKE_CURRENT_BINARY_DIR}/src")
set(MY_BUILD   "${CMAKE_CURRENT_BINARY_DIR}/build")
set(MY_INSTALL "${CMAKE_CURRENT_BINARY_DIR}/install")

# =========================================================
# 2. THE BUILD RECIPE
# =========================================================
# We assume parent passed variables like TARGET_ARCH and BUILD_TYPE

# Handle Boost's weird architecture naming
set(BOOST_ADDR_MODEL "64")
if("${TARGET_ARCH}" STREQUAL "x86")
    set(BOOST_ADDR_MODEL "32")
endif()

ExternalProject_Add(${PORT_NAME}_pkg
    # --- DOWNLOAD to /src ---
    GIT_REPOSITORY https://github.com/boostorg/boost.git
    GIT_TAG "boost-${PORT_VERSION}"
    GIT_SHALLOW TRUE
    SOURCE_DIR "${MY_SRC}"
    
    # --- CONFIGURE/BUILD in /build ---
    # Boost builds inside the source tree, so we map BINARY_DIR to SRC
    # For standard CMake libs, you would keep them separate.
    BUILD_IN_SOURCE 1 
    
    # --- INSTALL to /install ---
    INSTALL_DIR "${MY_INSTALL}"

    # Configure
    CONFIGURE_COMMAND ./bootstrap.sh --prefix=<INSTALL_DIR>
    
    # Build & Install (b2 writes directly to our isolated install dir)
    BUILD_COMMAND ./b2 install 
        --prefix=<INSTALL_DIR> 
        address-model=${BOOST_ADDR_MODEL} 
        variant=${BUILD_TYPE} 
        link=static 
        threading=multi 
        -j8
    
    # Disable default CMake install (b2 did it)
    INSTALL_COMMAND ""
)

# =========================================================
# 3. THE PACKAGING STEP
# =========================================================
# This runs automatically AFTER the install step finishes.

ExternalProject_Add_Step(${PORT_NAME}_pkg package_step
    # Create the zip file in the directory ABOVE install (build/ports/boost/)
    COMMAND ${CMAKE_COMMAND} -E tar cfv "../${PKG_FILENAME}" --format=zip .
    
    # We run this command INSIDE the install folder, so the zip 
    # doesn't contain the folder "install/", just the contents (include/, lib/)
    WORKING_DIRECTORY "${MY_INSTALL}"
    
    # Chain this step to run after 'install'
    DEPENDEES install
    
    # Nice log message
    COMMENT ">>> PACKAGING: Creating ${PKG_FILENAME} from ${MY_INSTALL}"
)

# =========================================================
# 4. EXPORT VARIABLES
# =========================================================
# Tell the Root CMake where the zip file and install dir are
set(BOOST_INSTALL_DIR "${MY_INSTALL}" PARENT_SCOPE)
set(BOOST_PACKAGE_PATH "${CMAKE_CURRENT_BINARY_DIR}/${PKG_FILENAME}" PARENT_SCOPE)
