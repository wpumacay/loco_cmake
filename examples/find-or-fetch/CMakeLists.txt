cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

# -------------------------------------
# Include all features by including the main entrypoint
include("../../Index.cmake")

# -------------------------------------
# Define the project
project(ExampleFindOrFetch VERSION 1.0.0)

# -------------------------------------
# Initialize the project (bare-minimum setup)
loco_initialize_project()

# cmake-format: off
set(SPDLOG_BUILD_SHARED OFF CACHE BOOL "" FORCE)
set(SPDLOG_BUILD_EXAMPLE OFF CACHE BOOL "" FORCE)
set(SPDLOG_BUILD_EXAMPLE_HO OFF CACHE BOOL "" FORCE)
set(SPDLOG_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(SPDLOG_BUILD_TESTS_HO OFF CACHE BOOL "" FORCE)
set(SPDLOG_BUILD_BENCH OFF CACHE BOOL "" FORCE)

loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE FALSE
  PACKAGE_NAME spdlog
  LIBRARY_NAME spdlog
  GIT_REPO https://github.com/gabime/spdlog.git
  GIT_TAG v1.9.2
  GIT_PROGRESS FALSE
  GIT_SHALLOW FALSE
  TARGETS spdlog::spdlog
  EXCLUDE_FROM_ALL)

set(PYBIND11_TEST OFF CACHE BOOL "" FORCE)

loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE FALSE
  PACKAGE_NAME pybind11
  LIBRARY_NAME pybind11
  GIT_REPO https://github.com/RobotLocomotion/pybind11.git
  GIT_TAG drake
  GIT_PROGRESS FALSE
  GIT_SHALLOW FALSE
  TARGETS pybind11::headers
  PATCH_COMMAND
    "${GIT_EXECUTABLE}"
    "apply"
    "-q"
    "${PROJECT_SOURCE_DIR}/pybind11-fix-vs2022.patch"
    "||"
    "${CMAKE_COMMAND}"
    "-E"
    "true"
  EXCLUDE_FROM_ALL)

set(CATCH_INSTALL_DOCS OFF CACHE BOOL "" FORCE)
set(CATCH_INSTALL_EXTRAS OFF CACHE BOOL "" FORCE)
set(CATCH_DEVELOPMENT_BUILD OFF CACHE BOOL "" FORCE)

loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE FALSE
  PACKAGE_NAME Catch2
  LIBRARY_NAME catch2
  GIT_REPO https://github.com/catchorg/Catch2.git
  GIT_TAG v2.x
  GIT_PROGRESS FALSE
  GIT_SHALLOW FALSE
  TARGETS Catch2::Catch2
  EXCLUDE_FROM_ALL)

set(ASSIMP_BUILD_FRAMEWORK OFF CACHE BOOL "" FORCE)
set(ASSIMP_DOUBLE_PRECISION OFF CACHE BOOL "" FORCE)
set(ASSIMP_BUILD_ASSIMP_TOOLS OFF CACHE BOOL "" FORCE)
set(ASSIMP_BUILD_SAMPLES OFF CACHE BOOL "" FORCE)
set(ASSIMP_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(ASSIMP_INSTALL OFF CACHE BOOL "" FORCE)
set(ASSIMP_HUNTER_ENABLED OFF CACHE BOOL "" FORCE)
set(ASSIMP_INJECT_DEBUG_POSTFIX OFF CACHE BOOL "" FORCE)

loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE FALSE
  PACKAGE_NAME assimp
  LIBRARY_NAME assimp
  GIT_REPO https://github.com/assimp/assimp.git
  GIT_TAG master
  GIT_PROGRESS FALSE
  GIT_SHALLOW TRUE
  TARGETS assimp::assimp
  EXCLUDE_FROM_ALL)

set(UTILS_BUILD_PYTHON_BINDINGS ON CACHE BOOL "" FORCE)
set(UTILS_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(UTILS_BUILD_DOCS OFF CACHE BOOL "" FORCE)

loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE FALSE
  LIBRARY_NAME loco_utils
  GIT_REPO https://github.com/wpumacay/loco_utils.git
  GIT_TAG dev
  GIT_PROGRESS FALSE
  GIT_SHALLOW TRUE
  TARGETS utils::utils
  EXCLUDE_FROM_ALL)

set(MATH_BUILD_PYTHON_BINDINGS ON CACHE BOOL "" FORCE)
set(MATH_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(MATH_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(MATH_BUILD_DOCS OFF CACHE BOOL "" FORCE)

loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE FALSE
  LIBRARY_NAME loco_math
  GIT_REPO https://github.com/wpumacay/loco_math.git
  GIT_TAG dev
  GIT_PROGRESS FALSE
  GIT_SHALLOW TRUE
  TARGETS math::math math::math_py_helpers
  EXCLUDE_FROM_ALL)

# cmake-format: on

# -------------------------------------
# Show some info of the this project
loco_print_project_info()
