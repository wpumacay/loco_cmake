# ~~~
# Commonly used helper functions and macros along various repositories I'm
# currently working on
# ~~~

# Helper logging function, similar to `message`, with additional info regarding
# the current project (in the scope in which it's called)
function(loco_message param_message)
  set(options) # Not used in this function
  set(one_value_args "LOG_LEVEL")
  set(multi_value_args) # Not used in this function
  cmake_parse_arguments(RB_PRINT "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # Use a dummy name in case no local project-scope has been set
  if(NOT PROJECT_NAME)
    set(PROJECT_NAME "")
  endif()

  # Use STATUS as default log-level, unless otherwise given by the user
  if(NOT RB_PRINT_LOG_LEVEL)
    set(RB_PRINT_LOG_LEVEL "STATUS")
  endif()

  message(${RB_PRINT_LOG_LEVEL} "[${PROJECT_NAME}] >>> ${param_message}")
endfunction()

# Fetches and configures a dependency from a given Git repo
macro(loco_configure_git_dependency)
  set(options) # Not using options for this macro
  set(one_value_args TARGET REPO TAG BUILD_MODE DISCARD_UNLESS)
  set(multi_value_args BUILD_ARGS)
  cmake_parse_arguments(GIT_DEP "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # Check if the user passed the DISCARD_UNLESS argument (if not, set to TRUE)
  if(NOT DEFINED GIT_DEP_DISCARD_UNLESS)
    set(GIT_DEP_DISCARD_UNLESS TRUE)
  endif()

  # In case the user discard the dep. then stop (might not be required)
  if(${GIT_DEP_DISCARD_UNLESS})
    # cmake-format: off
    # cmake-lint: disable=C0103
    set(FETCHCONTENT_QUIET FALSE CACHE INTERNAL "Show git-progress" FORCE)
    FetchContent_Declare(
          ${GIT_DEP_TARGET}
          GIT_REPOSITORY ${GIT_DEP_REPO}
          GIT_TAG ${GIT_DEP_TAG}
          GIT_PROGRESS TRUE
          GIT_SHALLOW TRUE
          USES_TERMINAL_DOWNLOAD TRUE
          PREFIX "${CMAKE_SOURCE_DIR}/third_party/${GIT_DEP_TARGET}"
          DOWNLOAD_DIR "${CMAKE_SOURCE_DIR}/third_party/${GIT_DEP_TARGET}"
          SOURCE_DIR "${CMAKE_SOURCE_DIR}/third_party/${GIT_DEP_TARGET}/source"
          BINARY_DIR "${CMAKE_BINARY_DIR}/third_party/${GIT_DEP_TARGET}/build"
          STAMP_DIR "${CMAKE_BINARY_DIR}/third_party/${GIT_DEP_TARGET}/stamp"
          TMP_DIR "${CMAKE_BINARY_DIR}/third_party/${GIT_DEP_TARGET}/tmp"
          CMAKE_ARGS -DCMAKE_BUILD_TYPE=${GIT_DEP_BUILD_MODE}
                     -DCMAKE_GENERATOR=${CMAKE_GENERATOR}
                     -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
                     -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
                     -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
                     -DCMAKE_INSTALL_INCLUDEDIR=${CMAKE_INSTALL_INCLUDEDIR}
                     -DCMAKE_INSTALL_LIBDIR=${CMAKE_INSTALL_LIBDIR}
                     -DCMAKE_INSTALL_DOCDIR=${CMAKE_INSTALL_DOCDIR}
                     -DCMAKE_INSTALL_BINDIR=${CMAKE_INSTALL_BINDIR}
                     -DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}
                     ${GIT_DEP_BUILD_ARGS}
          BUILD_ALWAYS OFF)
    # cmake-format: on
    FetchContent_MakeAvailable(${GIT_DEP_TARGET})
  endif()
endmacro()

# Helper function used to summarize all settings defined on a given target
function(loco_print_target_properties param_target)
  if(NOT TARGET ${param_target})
    loco_message("Must give a valid target to grab info from")
    return()
  endif()

  get_target_property(VAR_TARGET_TYPE ${param_target} TYPE)
  if(VAR_TARGET_TYPE MATCHES "INTERFACE_LIBRARY")
    get_target_property(VAR_COMPILE_FEATURES ${param_target}
                        INTERFACE_COMPILE_FEATURES)
    get_target_property(VAR_COMPILE_OPTIONS ${param_target}
                        INTERFACE_COMPILE_OPTIONS)
    get_target_property(VAR_COMPILE_DEFINITIONS ${param_target}
                        INTERFACE_COMPILE_DEFINITIONS)
  elseif(VAR_TARGET_TYPE MATCHES "EXECUTABLE|LIBRARY")
    get_target_property(VAR_COMPILE_FEATURES ${param_target} COMPILE_FEATURES)
    get_target_property(VAR_COMPILE_OPTIONS ${param_target} COMPILE_OPTIONS)
    get_target_property(VAR_COMPILE_DEFINITIONS ${param_target}
                        COMPILE_DEFINITIONS)
  endif()

  message("Target [${param_target}] information ------------------------------")
  message("Compile features             : ${VAR_COMPILE_FEATURES}")
  message("Compile options              : ${VAR_COMPILE_OPTIONS}")
  message("Compile definitions          : ${VAR_COMPILE_DEFINITIONS}")
  message("-------------------------------------------------------------------")
endfunction()

# Helper function used to summarize all settings setup by CMake on this project
function(loco_print_project_info)

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
  message("-------------------------------------------------------------------")
endfunction()

# Helper function used to check the OS of our host system
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
