cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

project(ExampleUtils VERSION 1.0.0)

# -------------------------------------
# Add the root folder (in a normal project the path wouldn't be this weird)
include("../../CMakeLists.txt")

# -------------------------------------
# Use some of the functions and macros provided in the `LocoUtils.cmake` module
loco_message("This is just a simple message within the ${PROJECT_NAME} project")
loco_message("This is an info message" LOG_LEVEL INFO)
loco_message("This is a warning" LOG_LEVEL WARNING)

# -------------------------------------
# Show some info of the system and the project
loco_print_project_info()
loco_print_host_info()

# -------------------------------------
# Test an empty INTERFACE target (nothing defined, so we should expect empty)
add_library(target_interface_lib_1 INTERFACE)
loco_print_target_properties(target_interface_lib_1)

# -------------------------------------
# Test an INTERFACE target with some settings attached
add_library(target_interface_lib_2 INTERFACE)
target_compile_features(target_interface_lib_2 INTERFACE cxx_std_11)
target_compile_features(target_interface_lib_2 INTERFACE cxx_variable_templates)
if(NOT MSVC)
  target_compile_options(target_interface_lib_2 INTERFACE "-Wpedantic")
else()
  target_compile_options(target_interface_lib_2 INTERFACE "/permissive-")
endif()
target_compile_definitions(target_interface_lib_2
                           INTERFACE -DVERSION=${PROJECT_VERSION})
loco_print_target_properties(target_interface_lib_2)

# -------------------------------------
# Test a library with some dummy code
add_library(target_shared_lib_3 SHARED)
target_sources(target_shared_lib_3
               PUBLIC "${CMAKE_CURRENT_LIST_DIR}/sample_lib.cpp")
target_compile_features(target_shared_lib_3 PUBLIC cxx_std_11)
if(NOT MSVC)
  target_compile_options(target_shared_lib_3 PRIVATE "-Wpedantic")
else()
  target_compile_options(target_shared_lib_3 PRIVATE "/permissive-")
endif()
target_compile_definitions(target_shared_lib_3
                           PUBLIC -DFUNKY_SHARED_VERSION=${PROJECT_VERSION})
loco_print_target_properties(target_shared_lib_3)

# -------------------------------------
# Test an executable with some dummy code
add_executable(target_executable_4)
target_sources(target_executable_4
               PUBLIC "${CMAKE_CURRENT_LIST_DIR}/sample_exec.cpp")
target_compile_features(target_executable_4 PUBLIC cxx_std_11)
if(NOT MSVC)
  target_compile_options(target_executable_4 PRIVATE "-Wpedantic")
else()
  target_compile_options(target_executable_4 PRIVATE "/permissive-")
endif()
target_compile_definitions(target_executable_4
                           PUBLIC -DFUNKY_EXECUTABLE_VERSION=${PROJECT_VERSION})
loco_print_target_properties(target_executable_4)
