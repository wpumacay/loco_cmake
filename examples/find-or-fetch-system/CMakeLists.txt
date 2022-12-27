cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

include("../../Index.cmake")

project(ExampleFindOrFetchSystem VERSION 1.0.0)

loco_initialize_project()

# cmake-format: off
# -------------------------------------
loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE TRUE
  PACKAGE_NAME mujoco
  LIBRARY_NAME mujoco
  GIT_REPO https://github.com/deepmind/mujoco.git
  GIT_TAG 2.3.1
  TARGETS mujoco::mujoco
  EXCLUDE_FROM_ALL)

if(NOT TARGET mujoco::mujoco)
  message(FATAL_ERROR "Couldn't import target mujoco::mujoco")
endif()

get_target_property(mujoco_target_type mujoco::mujoco TYPE)
get_target_property(mujoco_inc_dirs mujoco::mujoco INCLUDE_DIRECTORIES)
get_target_property(mujoco_link_libs mujoco::mujoco LINK_LIBRARIES)

message(STATUS "mujoco_target_type: ${mujoco_target_type}")
message(STATUS "mujoco_inc_dirs: ${mujoco_inc_dirs}")
message(STATUS "mujoco_link_libs: ${mujoco_link_libs}")
# -------------------------------------
loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE TRUE
  PACKAGE_NAME Bullet
  LIBRARY_NAME bullet
  GIT_REPO https://github.com/bulletphysics/bullet3.git
  GIT_TAG 3.24
  TARGETS LinearMath BulletCollision BulletDynamics
  EXCLUDE_FROM_ALL)

message(STATUS "bullet_include_dirs: ${BULLET_INCLUDE_DIRS}")
message(STATUS "bullet_libraries: ${BULLET_LIBRARIES}")
# -------------------------------------
loco_find_or_fetch_dependency(
  USE_SYSTEM_PACKAGE TRUE
  PACKAGE_NAME DART
  LIBRARY_NAME dart
  GIT_REPO https://github.com/dartsim/dart.git
  GIT_TAG v6.12.2
  TARGETS dart dart-collision-bullet dart-collision-ode
  EXCLUDE_FROM_ALL)

if(NOT TARGET dart)
  message(FATAL_ERROR "Couldn't import target dart")
endif()

message(STATUS "dart_include_dirs: ${DART_INCLUDE_DIRS}")
message(STATUS "dart_libraries: ${DART_LIBRARIES}")
message(STATUS "dart_version: ${DART_VERSION}")

# cmake-format: on

loco_print_project_info()
