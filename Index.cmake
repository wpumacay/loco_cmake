# ~~~
# Entrypoint for including the CMake helper functions and macros provided by
# this repository. This project is based heavily on the `ign-cmake` project,
# found at https://github.com/ignitionrobotics/ign-cmake
# ~~~

# -------------------------------------
# Use `more modern` CMake features
cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

# -------------------------------------
# Make sure we don't include this twice
include_guard()

# -------------------------------------
# We need these for some of our functions|macros to work :x
enable_language(C)
enable_language(CXX)
include(FetchContent)
include(GNUInstallDirs)

# -------------------------------------
# Set some cached global variables we'll need over the project
set(LOCO_CMAKE_ROOT_FOLDER
    "${CMAKE_CURRENT_LIST_DIR}"
    CACHE STRING "Root folder path for Loco-CMake project")
set(LOCO_CMAKE_MODULES_FOLDER
    "${CMAKE_CURRENT_LIST_DIR}/cmake"
    CACHE STRING "Modules folder path for Loco-CMake project")

# -------------------------------------
# Include helper modules provided by this project
include("${CMAKE_CURRENT_LIST_DIR}/cmake/Utilities.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/CheckSIMD.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/SetupProject.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/SetupTarget.cmake")

# -------------------------------------
# On success, just show our project mascot
message("|=========================================================|")
message("|                    LOCO-CMAKE HELPERS                   |")
message("|=========================================================|")
message(
  "
        .-\"-.
       /|6 6|\\
      {/(_0_)\\}
       _/ ^ \\_
      (/ /^\\ \\)-'
       \"\"' '\"\"")
