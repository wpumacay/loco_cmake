# -------------------------------------
# Make sure we don't include this twice
include_guard()

# ~~~
# loco_message(<param_message>
#       [LOG_LEVEL <log-level>])
#
# Printing helper used internally (keeps track of the current project scope)
# ~~~
macro(loco_message param_message)
  set(options)
  set(one_value_args "LOG_LEVEL")
  set(multi_value_args)
  cmake_parse_arguments(loco_msg "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # Use a dummy name in case no local project-scope has been set
  if(NOT PROJECT_NAME)
    set(PROJECT_NAME "")
  endif()

  # Use STATUS as default log-level, unless otherwise given by the user
  if(NOT loco_msg_LOG_LEVEL)
    set(loco_msg_LOG_LEVEL "STATUS")
  endif()

  message(${loco_msg_LOG_LEVEL} "[${PROJECT_NAME}] >>> ${param_message}")
endmacro()

# ~~~
# loco_configure_git_dependency(
#     [TARGET <target-name>]
#     [REPO] <git-repo>
#     [TAG] <tag|branch|commit-hash>
#     [BUILD_TYPE <build-type>]
#     [DISCARD_UNLESS <discard_flag>]
#     [BUILD_ARGS <extra-args>...])
#
# Fetches and configures a dependency from a given GIT repository. This assumes
# that the given project uses CMake as build system generator (i.e. has a root
# CMakeLists.txt file which gets invoked by add_subdirectory internally)
# ~~~
macro(loco_configure_git_dependency)
  set(options) # Not using options for this macro
  set(one_value_args TARGET REPO TAG BUILD_TYPE DISCARD_UNLESS)
  set(multi_value_args BUILD_ARGS)
  cmake_parse_arguments(git_dep "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # -----------------------------------
  # Check if the user passed the DISCARD_UNLESS argument (if not, set to TRUE)
  if(NOT DEFINED git_dep_DISCARD_UNLESS)
    set(git_dep_DISCARD_UNLESS TRUE)
  endif()

  # -----------------------------------
  # Process the request, unless the user wanted to discard it
  if(${git_dep_DISCARD_UNLESS})

    # -----------------------------------
    # Force FetchContent to show the progress of the git-clone command
    # cmake-lint: disable=C0103
    # cmake-format: off
    set(FETCHCONTENT_QUIET FALSE CACHE INTERNAL "Show git-progress" FORCE)

    # -----------------------------------
    # Request at `configure time` the given GIT repository using FetchContent
    FetchContent_Declare(
          ${git_dep_TARGET}
          GIT_REPOSITORY ${git_dep_REPO}
          GIT_TAG ${git_dep_TAG}
          GIT_PROGRESS TRUE
          GIT_SHALLOW TRUE
          USES_TERMINAL_DOWNLOAD TRUE
          PREFIX "${CMAKE_SOURCE_DIR}/third_party/${git_dep_TARGET}"
          DOWNLOAD_DIR "${CMAKE_SOURCE_DIR}/third_party/${git_dep_TARGET}"
          SOURCE_DIR "${CMAKE_SOURCE_DIR}/third_party/${git_dep_TARGET}/source"
          BINARY_DIR "${CMAKE_BINARY_DIR}/third_party/${git_dep_TARGET}/build"
          STAMP_DIR "${CMAKE_BINARY_DIR}/third_party/${git_dep_TARGET}/stamp"
          TMP_DIR "${CMAKE_BINARY_DIR}/third_party/${git_dep_TARGET}/tmp"
          CMAKE_ARGS -DCMAKE_BUILD_TYPE=${git_dep_BUILD_TYPE}
                     -DCMAKE_GENERATOR=${CMAKE_GENERATOR}
                     -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
                     -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
                     -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
                     -DCMAKE_INSTALL_INCLUDEDIR=${CMAKE_INSTALL_INCLUDEDIR}
                     -DCMAKE_INSTALL_LIBDIR=${CMAKE_INSTALL_LIBDIR}
                     -DCMAKE_INSTALL_DOCDIR=${CMAKE_INSTALL_DOCDIR}
                     -DCMAKE_INSTALL_BINDIR=${CMAKE_INSTALL_BINDIR}
                     -DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}
                     ${git_dep_BUILD_ARGS}
          BUILD_ALWAYS OFF)
    # cmake-format: on

    # ---------------------------------
    # Process the GIT repo (i.e. add_subdirectory)
    FetchContent_MakeAvailable(${git_dep_TARGET})
  endif()
endmacro()

# ~~~
# loco_setup_example(
#       [TARGET <target-name>]
#       [SOURCES <sources-list>...]
#       [INCLUDE_DIRECTORIES <include-dirs-list>...]
#       [TARGET_DEPENDENCIES <dependencies-list>...])
#
# Creates an executable target called `TARGET` with given `SOURCES`, and setup
# to use `TARGET_DEPENDENCIES` as targets to depend on
# ~~~
macro(loco_setup_example)
  set(options)
  set(one_value_args "TARGET")
  set(multi_value_args "SOURCES" "INCLUDE_DIRECTORIES" "TARGET_DEPENDENCIES")
  cmake_parse_arguments(example "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  if(NOT DEFINED example_TARGET)
    loco_message("Argument `TARGET` is required for setting up an example"
                 LOG_LEVEL WARNING)
    return()
  endif()

  if(NOT DEFINED example_SOURCES)
    loco_message("Argument `SOURCE is required for setting up an example"
                 LOG_LEVEL WARNING)
    return()
  endif()

  add_executable(${example_TARGET})
  target_sources(${example_TARGET} PRIVATE ${example_SOURCES})
  if(DEFINED example_INCLUDE_DIRECTORIES)
    target_include_directories(${example_TARGET}
                               PRIVATE ${example_INCLUDE_DIRECTORIES})
  endif()
  if(DEFINED example_TARGET_DEPENDENCIES)
    target_link_libraries(${example_TARGET}
                          PRIVATE ${example_TARGET_DEPENDENCIES})
  endif()
endmacro()

# ~~~
# loco_setup_single_file_example(<filepath>
#       [INCLUDE_DIRECTORIES <include-dirs-list>...]
#       [TARGET_DEPENDENCIES <dependencies-list>...])
#
# Creates a simple target for a single-file example (given by `filepath`) that
# might depend on some given list of targets (given by `TARGET_DEPENDENCIES`)
# ~~~
macro(loco_setup_single_file_example filepath)
  set(options)
  set(one_value_args)
  set(multi_value_args "INCLUDE_DIRECTORIES" "TARGET_DEPENDENCIES")
  cmake_parse_arguments(sf_example "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # -----------------------------------
  # Sanity check: make sure the targets we depend on exists
  if(DEFINED TARGET_DEPENDENCIES)
    foreach(target_dep ${sf_example_TARGET_DEPENDENCIES})
      if(NOT TARGET ${target_dep})
        loco_message("Tried configuring example [${filepath}] with dependency
          [${target_dep}], which doesn't exists" LOG_LEVEL WARNING)
        return()
      endif()
    endforeach()
  endif()

  # cmake-format: off
  # -----------------------------------
  # Create the target for our example
  get_filename_component(target_name ${filepath} NAME_WLE)
  loco_setup_example(
    TARGET ${target_name}
    SOURCES ${filepath}
    INCLUDE_DIRECTORIES ${sf_example_INCLUDE_DIRECTORIES}
    TARGET_DEPENDENCIES ${sf_example_TARGET_DEPENDENCIES})
  # cmake-format: on
endmacro()

# ~~~
# loco_validate_with_default(<variable> <default-value>)
#
# Checks if the given variable is defined. If not, set to given default value
# ~~~
macro(loco_validate_with_default variable default_value)
  if(NOT DEFINED ${variable})
    loco_message(
      "Undefined variable [${variable}]. Setting default: [${default_value}]"
      LOG_LEVEL TRACE)
    set(${variable} ${default_value})
  endif()
endmacro()

# ~~~
# loco_print_target_properties(<param_target>
#               [VERBOSE <verbose>])
#
# Prints to stdout the properties/settings of the given target
# ~~~
function(loco_print_target_properties target)
  if(NOT TARGET ${target})
    loco_message("Must give a valid target to grab info from" LOG_LEVEL WARNING)
    return()
  endif()

  set(options "VERBOSE")
  set(one_value_args)
  set(multi_value_args)
  cmake_parse_arguments(print "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  loco_validate_with_default(print_VERBOSE FALSE)

  # -----------------------------------
  # Print the information we could gather from the given target For a list of
  # available target properties, see section #properties-on-targets below:
  # https://cmake.org/cmake/help/latest/manual/cmake-properties.7.html
  message("Target [${target}] information ------------------------------")
  _loco_print_target_property(${target} PROPERTY CXX_STANDARD
                              ALLOWS_INTERFACE_PREFIX FALSE)
  _loco_print_target_property(${target} PROPERTY CXX_EXTENSIONS
                              ALLOWS_INTERFACE_PREFIX FALSE)
  _loco_print_target_property(${target} PROPERTY COMPILE_FEATURES
                              ALLOWS_INTERFACE_PREFIX TRUE)
  _loco_print_target_property(${target} PROPERTY COMPILE_OPTIONS
                              ALLOWS_INTERFACE_PREFIX TRUE)
  _loco_print_target_property(${target} PROPERTY COMPILE_DEFINITIONS
                              ALLOWS_INTERFACE_PREFIX TRUE)
  _loco_print_target_property(${target} PROPERTY INCLUDE_DIRECTORIES
                              ALLOWS_INTERFACE_PREFIX TRUE)
  _loco_print_target_property(${target} PROPERTY LINK_LIBRARIES
                              ALLOWS_INTERFACE_PREFIX TRUE)
  message("-------------------------------------------------------------------")
endfunction()

# ~~~
# _loco_print_target_property(<target>
#       [PROPERTY <property>]
#       [ALLOWS_INTERFACE_PREFIX <prefix>])
#
#
# ~~~
function(_loco_print_target_property target)
  if(NOT TARGET ${target})
    loco_message("Input [${target}] is not a valid target" LOG_LEVEL WARNING)
    return()
  endif()

  set(options)
  set(one_value_args "PROPERTY" "ALLOWS_INTERFACE_PREFIX")
  set(multi_value_args)
  cmake_parse_arguments(print "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  if(NOT DEFINED print_PROPERTY)
    loco_message("Dit not give a property for the request on target [${target}]"
                 LOG_LEVEL WARNING)
    return()
  endif()

  # -----------------------------------
  # If no USE_INTERFACE_PREFIX given, assume it's not required
  loco_validate_with_default(print_ALLOWS_INTERFACE_PREFIX FALSE)

  # -----------------------------------
  # Check if the given target is of type INTERFACE or not. If so, use the prefix
  # as expected, otherwise force the ALLOWS_INTERFACE_PREFIX to false
  get_target_property(target_type ${target} TYPE)
  if(NOT target_type MATCHES "INTERFACE_LIBRARY")
    set(print_ALLOWS_INTERFACE_PREFIX FALSE)
  endif()

  # -----------------------------------
  # Build prefix for our requested property (if re)
  if(print_ALLOWS_INTERFACE_PREFIX)
    set(property_prefix "INTERFACE_")
  else()
    set(property_prefix "")
  endif()

  # -----------------------------------
  # Query for the given target property and validate it to empty if not found
  get_target_property(target_property ${target}
                      "${property_prefix}${print_PROPERTY}")
  if(NOT target_property)
    set(target_property "")
  endif()

  # -----------------------------------
  # Print the appropriate message :D
  loco_message("${target}::${print_PROPERTY} > ${target_property}")
endfunction()

# ~~~
# loco_print_project_info()
#
# Prints to stdout the properties of the current project
# ~~~
function(loco_print_project_info)

  # -----------------------------------
  # Print various CMake settings from the configuration of the current project

  message("CMake settings information ----------------------------------------")
  message("Current project              : ${PROJECT_NAME}")
  message("Current project version      : ${PROJECT_VERSION}")
  message("Build-type                   : ${CMAKE_BUILD_TYPE}")
  message("Generator                    : ${CMAKE_GENERATOR}")
  message("C-compiler                   : ${CMAKE_C_COMPILER}")
  message("C++-compiler                 : ${CMAKE_CXX_COMPILER}")
  message("C-flags                      : ${CMAKE_C_FLAGS}")
  message("C++-flags                    : ${CMAKE_CXX_FLAGS}")
  message("Build-RPATH                  : ${CMAKE_BUILD_RPATH}")
  message("Module-path                  : ${CMAKE_MODULE_PATH}")
  message("Prefix-path                  : ${CMAKE_PREFIX_PATH}")
  message("Library-output-directory     : ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
  message("Archive-output-directory     : ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}")
  message("Runtime-output-directory     : ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
  message("Install prefix               : ${CMAKE_INSTALL_PREFIX}")
  message("Install include-directory    : ${CMAKE_INSTALL_INCLUDEDIR}")
  message("Install library-directory    : ${CMAKE_INSTALL_LIBDIR}")
  message("Install binary-directory     : ${CMAKE_INSTALL_BINDIR}")
  message("Install docs-directory       : ${CMAKE_INSTALL_DOCDIR}")
  message("Position-independent-code    : ${CMAKE_POSITION_INDEPENDENT_CODE}")
  message("Export-compile-commands      : ${CMAKE_EXPORT_COMPILE_COMMANDS}")
  IF(MSVC)
    message("Visual Studio version        : ${MSVC_VERSION}")
  endif()

  # -----------------------------------
  # Notify the user whether this is a ROOT or a CHILD project
  string(TOUPPER "${PROJECT_NAME}" proj_name_upper)
  if(DEFINED ${proj_name_upper}_IS_ROOT_PROJECT)
    message(
      "Is root project              : ${${proj_name_upper}_IS_ROOT_PROJECT}")
  endif()
  # -----------------------------------
  message("-------------------------------------------------------------------")
endfunction()

# ~~~
# loco_print_host_info()
#
# Prints to stdout the information of the current host
# ~~~
macro(loco_print_host_info)

  # -------------------------------------
  # Grab all information possible from cmake_host_system_info and show it to the
  # user (might help debugging platform-specific issues in the future)

  cmake_host_system_information(RESULT os_name QUERY OS_NAME)
  cmake_host_system_information(RESULT os_release QUERY OS_RELEASE)
  cmake_host_system_information(RESULT os_version QUERY OS_VERSION)
  cmake_host_system_information(RESULT os_platform QUERY OS_PLATFORM)
  cmake_host_system_information(RESULT cpu_num_logical_cores
                                QUERY NUMBER_OF_LOGICAL_CORES)
  cmake_host_system_information(RESULT cpu_num_physical_cores
                                QUERY NUMBER_OF_PHYSICAL_CORES)
  cmake_host_system_information(RESULT cpu_is_64bit QUERY IS_64BIT)
  cmake_host_system_information(RESULT cpu_processor_id
                                QUERY PROCESSOR_SERIAL_NUMBER)
  cmake_host_system_information(RESULT cpu_processor_name QUERY PROCESSOR_NAME)
  cmake_host_system_information(RESULT cpu_processor_description
                                QUERY PROCESSOR_DESCRIPTION)
  cmake_host_system_information(RESULT total_physical_memory
                                QUERY TOTAL_PHYSICAL_MEMORY)
  cmake_host_system_information(RESULT available_physical_memory
                                QUERY AVAILABLE_PHYSICAL_MEMORY)

  message("Host properties ---------------------------------------------------")
  message("OS name                      : ${os_name}")
  message("OS sub-type                  : ${os_release}")
  message("OS build-id                  : ${os_version}")
  message("OS platform                  : ${os_platform}")
  message("Number of logical cores      : ${cpu_num_logical_cores}")
  message("Number of physical cores     : ${cpu_num_physical_cores}")
  message("Is 64-bit                    : ${cpu_is_64bit}")
  message("Processor's serial number    : ${cpu_processor_id}")
  message("Processor's name             : ${cpu_processor_name}")
  message("Processor's description      : ${cpu_processor_description}")
  message("Total physical memory(MB)    : ${total_physical_memory}")
  message("Available physical memory(MB): ${available_physical_memory}")
  message("-------------------------------------------------------------------")
endmacro()
