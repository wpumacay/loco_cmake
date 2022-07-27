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
loco_setup_cppdocs(ZooCpp
    DOXYGEN_FILE_IN ${CMAKE_SOURCE_DIR}/docs/Doxyfile.in
    DOXYGEN_OUTPUT_DIR ${CMAKE_BINARY_DIR}/docs/Doxygen
    DOXYGEN_GENERATE_HTML FALSE
    DOXYGEN_GENERATE_LATEX FALSE
    DOXYGEN_GENERATE_XML TRUE
    DOXYGEN_QUIET TRUE
    SPHINX_FILE_IN ${CMAKE_SOURCE_DIR}/docs/conf.py.in
    SPHINX_OUTPUT_DIR ${CMAKE_BINARY_DIR}/docs/Sphinx
    SPHINX_BREATHE_PROJECT ZooCpp
    SPHINX_DOXYGEN_XML_OUTDIR ${CMAKE_BINARY_DIR}/docs/Doxygen/xml)
# cmake-format: on
