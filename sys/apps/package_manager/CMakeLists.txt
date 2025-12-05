cmake_minimum_required(VERSION 3.20)
project(HultrixThirdParty NONE)

include(ExternalProject)

# =========================================================
# 1. CONTROL CENTER (Global Configuration)
# =========================================================
# Your C program passes these in via command line
set(TARGET_ARCH "x64" CACHE STRING "Target Architecture (x64, arm64)")
set(TARGET_OS "linux" CACHE STRING "Target OS (linux, windows, android)")
set(BUILD_TYPE "Release" CACHE STRING "Build Type")

# Create the "Package" of settings to pass down to every port
# This ensures every lib is built with the EXACT same flags.
set(GLOBAL_CMAKE_ARGS
    "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
    "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
    # If you have a toolchain file, add it here:
    # "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_CURRENT_SOURCE_DIR}/toolchains/${TARGET_OS}-${TARGET_ARCH}.cmake"
)

message(STATUS ">>> Building Dependencies for ${TARGET_OS} (${TARGET_ARCH}) <<<")

# =========================================================
# 2. THE PORT LOADER
# =========================================================
# Define options for every port you have
option(ENABLE_BOOST "Build Boost" OFF)
# ... add options for all your folders

# Include the ports if enabled. 
# add_subdirectory makes variables like GLOBAL_CMAKE_ARGS visible inside the port.

if(ENABLE_BOOST)
    message(STATUS " + Enabling Port: boost")
    add_subdirectory(ports/boost)
endif()
