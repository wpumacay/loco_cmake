cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

# -------------------------------------
# Include all features by including the main entrypoint
include("../../Index.cmake")

# -------------------------------------
# Define the project
project(ExampleDoxygenDocs VERSION 1.0.0)

# -------------------------------------
# Initialize the project (bare-minimum setup)
loco_initialize_project()

# cmake-format: off
# -------------------------------------
# Create a simple library with some docstrings :)
loco_create_target(
    GeometricUtils SHARED
    SOURCES
        ${CMAKE_SOURCE_DIR}/impl/types_impl.hpp
        ${CMAKE_SOURCE_DIR}/impl/helpers2d_impl.hpp
        ${CMAKE_SOURCE_DIR}/impl/helpers3d_impl.hpp
        ${CMAKE_SOURCE_DIR}/src/types.cpp
        ${CMAKE_SOURCE_DIR}/src/helpers2d.cpp
        ${CMAKE_SOURCE_DIR}/src/helpers3d.cpp
    INCLUDE_DIRECTORIES
        ${CMAKE_SOURCE_DIR}/inc
)
# cmake-format: on
