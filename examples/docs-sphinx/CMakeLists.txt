cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

# -------------------------------------
# Include all features by including the main entrypoint
include("../../Index.cmake")

# -------------------------------------
# Define the project
project(ExampleSphinxDocs VERSION 1.0.0)

# -------------------------------------
# Initialize the project (bare-minimum setup)
loco_initialize_project()

# cmake-format: off
# -------------------------------------
# Create a simple library with some docstrings :)
loco_create_target(
    ZooCpp SHARED
    SOURCES
        ${CMAKE_SOURCE_DIR}/source/animal.cpp
    INCLUDE_DIRECTORIES
        ${CMAKE_SOURCE_DIR}/include
)
# cmake-format: on

# cmake-format: off
# -------------------------------------
# Initialize the documentation (doxygen + sphinx + breathe)
loco_setup_cppdocs_sphinx(ZooCpp
    SPHINX_FILE_IN ${CMAKE_SOURCE_DIR}/docs/conf.py.in
    SPHINX_OUTPUT_DIR ${CMAKE_BINARY_DIR}/docs/Sphinx/)
# cmake-format: on
