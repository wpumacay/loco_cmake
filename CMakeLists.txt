# ~~~
# Entrypoint for including the CMake helper functions and macros provided by
# this repository. This project is based heavily on the `ign-cmake` project,
# found at https://github.com/ignitionrobotics/ign-cmake
# ~~~
cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

# ==============================================================================
# Initialize the project
# ==============================================================================
project(
  LocoCmake
  VERSION 0.0.0
  DESCRIPTION "A set of CMake helpers that I commonly use in various projects"
  HOMEPAGE_URL "https://github.com/wpumacay/loco_cmake")

# -------------------------------------
# Set the path where our helper modules are located (right next to this folder)
set(LOCO_CMAKE_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}/cmake")

# -------------------------------------
# Make sure to tell CMake to include our helper modules
list(APPEND CMAKE_MODULE_PATH "${LOCO_CMAKE_CMAKE_DIR}")

# Include helper modules provided by this project
include(LocoUtils)
include(LocoSetCompilerFlags)
include(LocoCheckSIMD)
include(LocoConfigureProject)

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
