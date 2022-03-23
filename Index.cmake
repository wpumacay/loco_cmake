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

# Include helper modules provided by this project
include("${CMAKE_CURRENT_LIST_DIR}/cmake/Utilities.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/CheckSIMD.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/SetupCompiler.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/SetupProject.cmake")

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
