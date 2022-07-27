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
# Setup static analyzers
loco_setup_cppcheck()
loco_setup_cpplint()
loco_setup_clang_tidy()

# -------------------------------------
# Checking a simple target of type INTERFACE
loco_create_target(target_interface_lib INTERFACE WARNINGS_AS_ERRORS TRUE)
loco_print_target_properties(target_interface_lib)

# cmake-format: off
# -------------------------------------
# Checking a simple target of type SHARED
loco_create_target(
  target_shared_lib SHARED
  SOURCES "${CMAKE_SOURCE_DIR}/src/sample.cc"
  INCLUDE_DIRECTORIES "${CMAKE_SOURCE_DIR}/inc"
  WARNINGS_AS_ERRORS FALSE
  TARGET_DEPENDENCIES target_interface_lib)
loco_print_target_properties(target_shared_lib)
# cmake-format: on

# cmake-format: off
# -------------------------------------
# Checking a simple target of type executable
loco_create_target(
  target_executable EXECUTABLE
  SOURCES "${CMAKE_SOURCE_DIR}/src/sample_main.cc"
  TARGET_DEPENDENCIES target_shared_lib)
loco_print_target_properties(target_executable)
# cmake-format: on

# cmake-format: off
# -------------------------------------
# Create an example using our helper macros
loco_setup_single_file_example(
  ${CMAKE_SOURCE_DIR}/src/sample_main.cc
  INCLUDE_DIRECTORIES ${CMAKE_SOURCE_DIR}/inc
  TARGET_DEPENDENCIES target_shared_lib)
# cmake-format: on
loco_print_target_properties(sample_main)

# -------------------------------------
# Show some info of the this project
loco_print_project_info()
