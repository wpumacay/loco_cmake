cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

# -------------------------------------
# Include all features by including the main entrypoint
include("../../Index.cmake")

# -------------------------------------
# Define the project
project(ExampleTarget VERSION 1.0.0)

# -------------------------------------
# Initialize the project (bare-minimum setup)
loco_initialize_project()

# -------------------------------------
# Checking a simple target of type INTERFACE
add_library(target_interface_lib INTERFACE)
loco_setup_target(target_interface_lib WARNINGS_AS_ERRORS TRUE)
loco_print_target_properties(target_interface_lib)

# cmake-format: off
# -------------------------------------
# Checking a simple target of type SHARED
add_library(target_shared_lib SHARED)
loco_setup_target(
  target_shared_lib
  SOURCES "${CMAKE_SOURCE_DIR}/src/sample.cc"
  INCLUDE_DIRECTORIES "${CMAKE_SOURCE_DIR}/inc"
  WARNINGS_AS_ERRORS FALSE
  TARGET_DEPENDENCIES target_interface_lib)
loco_print_target_properties(target_shared_lib)
# cmake-format: on

# -------------------------------------
# Checking a simple target of type executable
add_executable(target_executable)
loco_setup_target(
  target_executable SOURCES "${CMAKE_SOURCE_DIR}/src/sample_main.cc"
  TARGET_DEPENDENCIES target_shared_lib)
loco_print_target_properties(target_executable)

# -------------------------------------
# Show some info of the this project
loco_print_project_info()
