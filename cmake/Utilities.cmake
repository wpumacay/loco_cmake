# -------------------------------------
# Make sure we don't include this twice
include_guard()

# -------------------------------------
# References:
#
# * CppBestPractices CMake helpers: https://github.com/aminya/project_options
# * https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_CPPCHECK.html

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
#     [DISCARD_UNLESS <discard_flag>])
#
# Fetches and configures a dependency from a given GIT repository. This assumes
# that the given project uses CMake as build system generator (i.e. has a root
# CMakeLists.txt file which gets invoked by add_subdirectory internally)
# ~~~
macro(loco_configure_git_dependency)
  set(options) # Not using options for this macro
  set(one_value_args TARGET REPO TAG BUILD_TYPE DISCARD_UNLESS)
  set(multi_value_args DEPENDS_ON)
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
          BUILD_ALWAYS OFF)
    # cmake-format: on

    # ---------------------------------
    # Process the GIT repo (i.e. add_subdirectory)
    if(git_dep_DEPENDS_ON)
      FetchContent_MakeAvailable(${git_dep_TARGET} ${git_dep_DEPENDS_ON})
    else()
      FetchContent_MakeAvailable(${git_dep_TARGET})
    endif()

  endif()
endmacro()

# ~~~
# loco_find_or_fetch_dependency(
#       [USE_SYSTEM_PACKAGE <on|off>]
#       [PACKAGE_NAME <name>]
#       [LIBRARY_NAME <name>]
#       [GIT_REPO <repo>]
#       [GIT_TAG <tag|branch|commit-hash>]
#       [TARGETS <targets>]
#       [PATCH_COMMAND <commands>]
#       [EXCLUDE_FROM_ALL])
#
# Finds the required dependency locally (via find_package) or fetchs it from its
# main git repository (if applicable). Throws a FATAL_ERROR if none of the
# options were possible to complete. Notice that USE_SYSTEM_PACKAGE will hint
# for a search of what the installed package provides, but won't check for the
# required targets, as these are not exported when installed. For example, the
# package for MuJoCo exposes an imported target when installed, whereas the one
# for Bullet only exposes some variables for the include directories and the
# appropriate libraries to link to (no targets)
#
# Note
# ----
# There's is a restriction with LIBRARY_NAME. As it uses the FetchContent API
# from CMake, it expects the name of the target to be **all lowercase**.
# ~~~
macro(loco_find_or_fetch_dependency)
  if(NOT FetchContent)
    include(FetchContent)
  endif()

  set(options "EXCLUDE_FROM_ALL")
  set(one_value_args "USE_SYSTEM_PACKAGE" "PACKAGE_NAME" "LIBRARY_NAME"
                     "GIT_REPO" "GIT_TAG" "GIT_PROGRESS" "GIT_SHALLOW")
  set(multi_value_args "TARGETS" "PATCH_COMMAND")

  cmake_parse_arguments(args "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # By default show the progress of the clone stage
  loco_validate_with_default(args_GIT_PROGRESS TRUE)
  loco_validate_with_default(args_GIT_SHALLOW FALSE)

  # -----------------------------------
  # Make sure the user provides the list of expected targets
  if(NOT args_TARGETS)
    loco_message("FindOrFetch: TARGETS must be specified" LOG_LEVEL FATAL_ERROR)
  endif()

  # -----------------------------------
  # Check if we already have all targets requested. If so, we might be trying to
  # add this package twice, so it's already loaded :)
  set(targets_found TRUE)
  message("FindOrFetch: checking for targets in package ${args_PACKAGE_NAME}")
  foreach(target IN LISTS args_TARGETS)
    message(CHECK_START "FindOrFetch: checking for target ${target}")
    if(NOT TARGET ${target})
      message(CHECK_FAIL "target `${target}` not defined")
      set(targets_found FALSE)
      break()
    endif()
    message(CHECK_PASS "target `${target}` defined")
  endforeach()

  # -----------------------------------
  # If required targets are not found, use either `find_package` or
  # `FetchContent` to get them. Notice that we're assumming that the user knows
  # which version of the package he wants, and has already installed it properly
  # if he's using the USE_SYSTEM_PACKAGE option.
  if(NOT targets_found)
    if(${args_USE_SYSTEM_PACKAGE})
      message(
        CHECK_START
        "FindOrFetch: finding `${args_PACKAGE_NAME}` in system packages...")
      # Call find_package, and if fail, just let the user know that he has to
      # either install the package it his system or use from-repo
      find_package(${args_PACKAGE_NAME} REQUIRED)
      message(CHECK_PASS "FindOrFetch: found `${args_PACKAGE_NAME}` in system")
    else()
      message(
        CHECK_START
        "FindOrFetch: using FetchContent to retrieve `${args_LIBRARY_NAME}`")
      # Force FetchContent to show the progress of the git-clone command
      # cmake-lint: disable=C0103
      set(FETCHCONTENT_QUIET
          FALSE
          CACHE INTERNAL "Show git-progress" FORCE)

      # cmake-format: off
      FetchContent_Declare(
        ${args_LIBRARY_NAME}
        GIT_REPOSITORY ${args_GIT_REPO}
        GIT_TAG ${args_GIT_TAG}
        GIT_PROGRESS ${args_GIT_PROGRESS}
        GIT_SHALLOW ${args_GIT_SHALLOW}
        PATCH_COMMAND ${args_PATCH_COMMAND})
      # cmake-format: on

      if(${args_EXCLUDE_FROM_ALL})
        FetchContent_GetProperties(${args_LIBRARY_NAME})
        if(NOT ${args_LIBRARY_NAME}_POPULATED)
          FetchContent_Populate(${args_LIBRARY_NAME})
          add_subdirectory(${${args_LIBRARY_NAME}_SOURCE_DIR}
                           ${${args_LIBRARY_NAME}_BINARY_DIR} EXCLUDE_FROM_ALL)
        endif()
      else()
        FetchContent_MakeAvailable(${args_LIBRARY_NAME})
      endif()
      message(CHECK_PASS "Done")
    endif()
    # Make sure we have the required targets defined (only if not using system
    # packages, as these tend not to expose targets, but variables instead)
    if(NOT ${args_USE_SYSTEM_PACKAGE})
      foreach(target IN LISTS args_TARGETS)
        if(NOT TARGET ${target})
          loco_message("Target ${target} is required, but wasn't setup"
                       LOG_LEVEL WARNING)
        endif()
      endforeach()
    endif()
  else()
    loco_message("Found all required targets for ${args_PACKAGE_NAME}"
                 LOG_LEVEL STATUS)
  endif()
endmacro()

# ~~~
# loco_setup_clang_tidy(
#     [CONFIG_FILE <config-file>]
#     [FIX <fix>]
#     [FIX_ERRORS <fix-errors>]
#     [FORMAT_STYLE <format-style>]
#     [QUIET <quiet>]
#     [CHECKS <checks-list...>]
#     [WARNINGS_AS_ERRORS <warnings-as-errors-list...]
#     [EXTRA_ARGS <extra-args-list...>])
# ~~~
macro(loco_setup_clang_tidy)
  set(options)
  set(one_value_args "CONFIG_FILE" "FIX" "FIX_ERRORS" "FORMAT_STYLE" "QUIET")
  set(multi_value_args "CHECKS" "WARNINGS_AS_ERRORS" "EXTRA_ARGS")
  cmake_parse_arguments(clang_tidy "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # -----------------------------------
  # Sanity check (find the clang-tidy executable)
  find_program(clang_tidy_program clang-tidy)
  if(clang_tidy_program)
    loco_message("[clang-tidy] found at ${clang_tidy_program}" STATUS)

    # -----------------------------------
    # Define default values in case the user didn't provide them. For all valid
    # options check use `clang-tidy --help` in your terminal of choice :)
    loco_validate_with_default(clang_tidy_CONFIG_FILE "")
    loco_validate_with_default(clang_tidy_FIX FALSE)
    loco_validate_with_default(clang_tidy_FIX_ERRORS FALSE)
    loco_validate_with_default(clang_tidy_FORMAT_STYLE "none")
    loco_validate_with_default(clang_tidy_QUIET FALSE)
    loco_validate_with_default(clang_tidy_CHECKS "")
    loco_validate_with_default(clang_tidy_WARNINGS_AS_ERRORS "")
    loco_validate_with_default(clang_tidy_EXTRA_ARGS "")

    # cmake-format: off
    # -----------------------------------
    # Tell CMake to use clang-tidy with the given configuration
    set(CMAKE_CXX_CLANG_TIDY
        ${clang_tidy_program}
        --format-style=${clang_tidy_FORMAT_STYLE})
    # cmake-format: on

    # ---------------------------------
    # Add --config-file="" if given by the user
    if(NOT ${clang_tidy_CONFIG_FILE} STREQUAL "")
      list(APPEND CMAKE_CXX_CLANG_TIDY --config-file=${clang_tidy_CONFIG_FILE})
    endif()

    # ---------------------------------
    # Add --fix if given by the user
    if(clang_tidy_FIX)
      list(APPEND CMAKE_CXX_CLANG_TIDY --fix)
    endif()

    # ---------------------------------
    # Add --fix-errors if given by the user
    if(clang_tidy_FIX_ERRORS)
      list(APPEND CMAKE_CXX_CLANG_TIDY --fix-errors)
    endif()

    # ---------------------------------
    # Add --quiet if given by the user
    if(clang_tidy_QUIET)
      list(APPEND CMAKE_CXX_CLANG_TIDY --quiet)
    endif()

    # ---------------------------------
    # Add --checks="LIST OF CHECKS" if given by the user
    if(NOT "${clang_tidy_CHECKS}" STREQUAL "")
      list(APPEND CMAKE_CXX_CLANG_TIDY "${clang_tidy_CHECKS}")
    endif()

    # ---------------------------------
    # Add --warnings-as-errors="LIST OF WARNINGS" if given by the user
    if(NOT "${clang_tidy_WARNINGS_AS_ERRORS}" STREQUAL "")
      list(APPEND CMAKE_CXX_CLANG_TIDY "${clang_tidy_WARNINGS_AS_ERRORS}")
    endif()

    # ---------------------------------
    # Add all extra-arguments given by the user
    if(NOT "${clang_tidy_EXTRA_ARGS}" STREQUAL "")
      list(APPEND CMAKE_CXX_CLANG_TIDY "${clang_tidy_EXTRA_ARGS}")
    endif()

    # -----------------------------------
    # Print the whole line representing the command
    loco_message("[clang-tidy]: ${CMAKE_CXX_CLANG_TIDY}")
  else()
    loco_message("[clang-tidy] could not be found :(" WARNING)
  endif()

endmacro()

# ~~~
# loco_setup_cpplint(
#     [QUIET <quiet>]
#     [COUNTING <counting>]
#     [VERBOSITY <verbosity-level>]
#     [LINE_LENGTH <line-length>]
#     [EXCLUDES <excludes-list...>]
#     [FILTERS <filters-list...>]
#     [EXTRA_ARGS <extra-args-list...>])
# ~~~
macro(loco_setup_cpplint)
  set(options)
  set(one_value_args "QUIET" "COUNTING" "VERBOSITY" "LINE_LENGTH")
  set(multi_value_args "EXCLUDES" "FILTERS" "EXTRA_ARGS")
  cmake_parse_arguments(cpplint "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # -----------------------------------
  # Sanity check (find the cpplint executable)
  find_program(cpplint_program cpplint)
  if(cpplint_program)
    loco_message("[cpplint] found at ${cpplint_program}" STATUS)

    # -----------------------------------
    # Define default values in case the user didn't provide them. For all valid
    # options check use `cpplint --help` in your terminal of choice :)
    loco_validate_with_default(cpplint_QUIET TRUE)
    loco_validate_with_default(cpplint_COUNTING "total")
    loco_validate_with_default(cpplint_VERBOSITY 0)
    loco_validate_with_default(cpplint_LINE_LENGTH 80)
    loco_validate_with_default(cpplint_EXCLUDES "")
    loco_validate_with_default(cpplint_FILTERS "")
    loco_validate_with_default(cpplint_EXTRA_ARGS "")

    # cmake-format: off
    # -----------------------------------
    # Tell CMake to use cpplint with the given configuration
    set(CMAKE_CXX_CPPLINT
        ${cpplint_program}
        --counting=${cpplint_COUNTING}
        --verbose=${cpplint_VERBOSITY}
        --linelength=${cpplint_LINE_LENGTH})
    # cmake-format: on

    # -----------------------------------
    # If quiet is given, don't complain for warnings
    if(cpplint_QUIET)
      list(APPEND CMAKE_CXX_CPPLINT --quiet)
    endif()

    # -----------------------------------
    # Add --exclude=cpplint_EXCLUDES[i] for i in num-excludes
    if(NOT "${cpplint_EXCLUDES}" STREQUAL "")
      foreach(exclude_path IN LISTS cpplint_EXCLUDES)
        list(APPEND CMAKE_CXX_CPPLINT --exclude=${exclude_path})
      endforeach()
    endif()

    # ---------------------------------
    # Add --filter=cpplint_FILTERS[i] for i in num-filters
    if(NOT "${cpplint_FILTERS}" STREQUAL "")
      foreach(filter IN LISTS cpplint_FILTERS)
        list(APPEND CMAKE_CXX_CPPLINT --filter=${filter})
      endforeach()
    endif()

    # ---------------------------------
    # Add all extra-arguments given by the user
    if(NOT "${cpplint_EXTRA_ARGS}" STREQUAL "")
      list(APPEND CMAKE_CXX_CPPLINT "${cpplint_EXTRA_ARGS}")
    endif()

    # -----------------------------------
    # Print the whole line representing the command
    loco_message("[cpplint]: ${CMAKE_CXX_CPPLINT}")
  else()
    loco_message("[cpplint] could not be found :(" WARNING)
  endif()

endmacro()

# ~~~
# loco_setup_cppcheck(
#     [TEMPLATE <template>]
#     [CXX_STANDARD <cxx-standard>]
#     [WARNINGS_AS_ERRORS <warnings-as-errors>]
#     [EXTRA_ARGS <extra-args...>])
# ~~~
macro(loco_setup_cppcheck)
  set(options)
  set(one_value_args "TEMPLATE" "CXX_STANDARD" "WARNINGS_AS_ERRORS")
  set(multi_value_args "EXTRA_ARGS")
  cmake_parse_arguments(cppcheck "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # -----------------------------------
  # Sanity check (find the cppcheck executable)
  find_program(cppcheck_program cppcheck)
  if(cppcheck_program)
    loco_message("[cppcheck] found at ${cppcheck_program}" STATUS)

    # -----------------------------------
    # Define default values if the user doesn't provide them
    if(CMAKE_GENERATOR MATCHES ".*Visual Studio.*")
      set(cppcheck_TEMPLATE "vs")
    else()
      loco_validate_with_default(cppcheck_TEMPLATE "gcc")
    endif()
    if(NOT CMAKE_CXX_STANDARD)
      loco_validate_with_default(cppcheck_CXX_STANDARD "c++11")
    else()
      loco_validate_with_default(cppcheck_CXX_STANDARD
                                 "c++${CMAKE_CXX_STANDARD}")
    endif()
    loco_validate_with_default(cppcheck_WARNINGS_AS_ERRORS FALSE)
    loco_validate_with_default(cppcheck_EXTRA_ARGS "")

    # cmake-format: off
    # -----------------------------------
    # Tell CMake to use cppcheck (and pass extra-args if given)
    set(CMAKE_CXX_CPPCHECK
        ${cppcheck_program}
        --template=${cppcheck_TEMPLATE}
        --std=${cppcheck_CXX_STANDARD}
        --enable=style,performance,warning,portability
        --inline-suppr
        --suppress=internalAstError
        --suppress=unmatchedSuppression
        --inconclusive)
    # cmake-format: on

    # -----------------------------------
    # Add any extra arguments if given by the user :)
    if(NOT "${cppcheck_EXTRA_ARGS}" STREQUAL "")
      list(APPEND CMAKE_CXX_CPPCHECK "${cppcheck_EXTRA_ARGS}")
    endif()

    # -----------------------------------
    # Treat warnings as errors if the users says so
    if(cppcheck_WARNINGS_AS_ERRORS)
      list(APPEND CMAKE_CXX_CPPCHECK --error-exitcode=2)
    endif()

    # -----------------------------------
    # Print the whole line representing the command
    loco_message("[cppcheck]: ${CMAKE_CXX_CPPCHECK}")
  else()
    loco_message("[cppcheck] could not be found :(" WARNING)
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
  # Check if the given target is of type INTERFACE or not. If so, continue using
  # the prefix as expected only if the property "allows it" (otherwise, return)
  get_target_property(target_type ${target} TYPE)
  if((target_type MATCHES "INTERFACE_LIBRARY")
     AND (NOT print_ALLOWS_INTERFACE_PREFIX))
    return()
  endif()

  # If the target is non-interface, then we won't be using the INTERFACE prefix
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
