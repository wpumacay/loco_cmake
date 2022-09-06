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

option(FIND_USE_SYSTEM_PACKAGE
       "Whether or not to give priority to system-wide package search" OFF)

# cmake-format: off
loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE ${FIND_USE_SYSTEM_PACKAGE}
  PACKAGE_NAME spdlog
  LIBRARY_NAME spdlog
  GIT_REPO https://github.com/gabime/spdlog.git
  GIT_TAG v1.9.2
  TARGETS spdlog::spdlog
  BUILD_ARGS
    -DSPDLOG_BUILD_SHARED=OFF
    -DSPDLOG_BUILD_EXAMPLE=OFF
    -DSPDLOG_BUILD_EXAMPLE_HO=OFF
    -DSPDLOG_BUILD_TESTS=OFF
    -DSPDLOG_BUILD_TESTS_HO=OFF
    -DSPDLOG_BUILD_BENCH=OFF
  EXCLUDE_FROM_ALL)

loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE ${FIND_USE_SYSTEM_PACKAGE}
  PACKAGE_NAME pybind11
  LIBRARY_NAME pybind11
  GIT_REPO https://github.com/RobotLocomotion/pybind11.git
  GIT_TAG drake
  TARGETS pybind11::headers
  BUILD_ARGS
    -DPYBIND11_TEST=OFF
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

loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE ${FIND_USE_SYSTEM_PACKAGE}
  PACKAGE_NAME Catch2
  LIBRARY_NAME catch2
  GIT_REPO https://github.com/catchorg/Catch2.git
  GIT_TAG v2.x
  TARGETS Catch2::Catch2
  BUILD_ARGS
    -DCATCH_INSTALL_DOCS=OFF
    -DCATCH_INSTALL_EXTRAS=OFF
    -DCATCH_DEVELOPMENT_BUILD=OFF
  EXCLUDE_FROM_ALL)

loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE ${FIND_USE_SYSTEM_PACKAGE}
  PACKAGE_NAME assimp
  LIBRARY_NAME assimp
  GIT_REPO https://github.com/assimp/assimp.git
  GIT_TAG master
  TARGETS assimp::assimp
  BUILD_ARGS
    -DBUILD_SHARED_LIBS=OFF
    -DASSIMP_BUILD_FRAMEWORK=OFF
    -DASSIMP_DOUBLE_PRECISION=OFF
    -DASSIMP_BUILD_ASSIMP_TOOLS=OFF
    -DASSIMP_BUILD_SAMPLES=OFF
    -DASSIMP_BUILD_TESTS=OFF
    -DASSIMP_INSTALL=OFF
    -DASSIMP_HUNTER_ENABLED=OFF
    -DASSIMP_INJECT_DEBUG_POSTFIX=OFF
  EXCLUDE_FROM_ALL)

loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE FALSE
  LIBRARY_NAME loco_utils
  GIT_REPO https://github.com/wpumacay/loco_utils.git
  GIT_TAG dev
  TARGETS loco::utils
  BUILD_ARGS
    -DLOCOUTILS_BUILD_PYTHON_BINDINGS=ON
    -DLOCOUTILS_BUILD_EXAMPLES=OFF
    -DLOCOUTILS_BUILD_DOCS=OFF
  EXCLUDE_FROM_ALL)

loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE FALSE
  LIBRARY_NAME loco_math
  GIT_REPO https://github.com/wpumacay/loco_math.git
  GIT_TAG dev
  TARGETS loco::math loco::math_py_helpers
  BUILD_ARGS
    -DLOCOMATH_BUILD_PYTHON_BINDINGS=ON
    -DLOCOMATH_BUILD_EXAMPLES=OFF
    -DLOCOMATH_BUILD_TESTS=OFF
    -DLOCOMATH_BUILD_DOCS=OFF
  EXCLUDE_FROM_ALL)

# cmake-format: on

# -------------------------------------
# Show some info of the this project
loco_print_project_info()
