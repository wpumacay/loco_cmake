cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

# -------------------------------------
# Include all features by including the main entrypoint
include("../../Index.cmake")

# -------------------------------------
# Define the project
project(ExampleGitDependencies VERSION 1.0.0)

# -------------------------------------
# Initialize the project (bare-minimum setup)
loco_initialize_project()

# cmake-format: off
loco_configure_git_dependency(
  TARGET spdlog
  REPO https://github.com/gabime/spdlog.git
  TAG v1.9.2
  BUILD_MODE ${CMAKE_BUILD_TYPE}
  BUILD_ARGS
    -DSPDLOG_BUILD_SHARED=OFF
    -DSPDLOG_BUILD_EXAMPLE=OFF
    -DSPDLOG_BUILD_EXAMPLE_HO=OFF
    -DSPDLOG_BUILD_TESTS=OFF
    -DSPDLOG_BUILD_TESTS_HO=OFF
    -DSPDLOG_BUILD_BENCH=OFF)

loco_configure_git_dependency(
  TARGET pybind11
  REPO https://github.com/RobotLocomotion/pybind11.git
  TAG drake
  BUILD_MODE RelWithDebInfo
  BUILD_ARGS
    -DPYBIND11_TEST=OFF)

loco_configure_git_dependency(
  TARGET LocoUtils
  REPO https://github.com/wpumacay/loco_utils.git
  TAG dev
  BUILD_MODE ${CMAKE_BUILD_TYPE}
  BUILD_ARGS
    -DLOCOUTILS_BUILD_PYTHON_BINDINGS=ON
    -DLOCOUTILS_BUILD_EXAMPLES=OFF
    -DLOCOUTILS_BUILD_DOCS=OFF
  DEPENDS_ON
    pybind11 spdlog)

loco_configure_git_dependency(
  TARGET LOcoMath
  REPO https://github.com/wpumacay/loco_math.git
  TAG dev
  BUILD_MODE ${CMAKE_BUILD_TYPE}
  BUILD_ARGS
    -DTINYMATH_BUILD_PYTHON_BINDINGS=ON
    -DTINYMATH_BUILD_EXAMPLES=OFF
    -DTINYMATH_BUILD_TESTS=OFF
    -DTINYMATH_BUILD_DOCS=OFF
  DEPENDS_ON
    pybind11)
# cmake-format: on

# -------------------------------------
# Show some info of the this project
loco_print_project_info()
