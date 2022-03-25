# -------------------------------------
# Make sure we don't include this twice
include_guard()

# ~~~
# loco_initialize_project(
#           [CXX_STANDARD <standard>]
#           [BUILD_TYPE <build-type>])
#
# Configures the base settings of the current project being processed. We'll
# check if this is the ROOT project. If so, we then proceed with the full setup;
# otherwise, just a partial setup will be applied for this CHILD project
# ~~~
function(loco_initialize_project)
  # cmake-lint: disable=R0915
  set(options)
  set(one_value_args "CXX_STANDARD" "BUILD_TYPE")
  set(multi_value_args)
  cmake_parse_arguments(loco_init "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # -----------------------------------
  # Must be within at least one project (CMake call to project() command)
  if(NOT PROJECT_NAME)
    loco_message("Must call within a project scope" LOG_LEVEL WARNING)
    return()
  endif()

  # -----------------------------------
  # Notify the user we're currently configuring the first project from the stack
  loco_message("We're currently initializing project [${PROJECT_NAME}]")

  # -----------------------------------
  # Make sure to allow only out-of-source builds
  if(CMAKE_BINARY_DIR STREQUAL CMAKE_SOURCE_DIR)
    loco_message("Must only use out-of-source builds" LOG_LEVEL FATAL_ERROR)
  endif()

  # ----------------------------------------------------------------------------
  # Store for convenience the project name in UPPERCASE
  string(TOUPPER "${PROJECT_NAME}" project_name_upper)

  # Store the string '[PROJECT_NAME]_IS_ROOT_PROJECT' as variable name to be
  # later exported for the developer to check (variable acts as a "pointer")
  string(TOUPPER "${PROJECT_NAME}_IS_ROOT_PROJECT" project_is_root_var_name)

  # Check if we're the ROOT project
  # cmake-format: off
  if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set(project_is_root TRUE) # used here locally
    set(${project_is_root_var_name} TRUE PARENT_SCOPE) # exposed to the dev.
    loco_message("Project [${PROJECT_NAME}] is a ROOT project")
  else()
    set(project_is_root FALSE) # used here locally
    set(${project_is_root_var_name} FALSE PARENT_SCOPE) # exposed to the dev.
    loco_message("Project [${PROJECT_NAME}] is a CHILD project")
  endif()
  # cmake-format: on
  # ----------------------------------------------------------------------------

  # ----------------------------------------------------------------------------
  # Make the following setup only if we're a ROOT project

  # cmake-format: off
  if(project_is_root)
    # Make sure we're using one of the compilers we currently support
    _loco_check_compiler()

    # If not set yet, setup the CXX_STANDARD to be used (c++11, c++14, etc.)
    if(NOT CMAKE_CXX_STANDARD)
      loco_validate_with_default(loco_init_CXX_STANDARD 11)
      set(CMAKE_CXX_STANDARD ${loco_init_CXX_STANDARD} CACHE STRING
            "The C++ standard to be used (and children projects)" FORCE)
      # Set possible options for the cxx-standard
      set_property(CACHE CMAKE_CXX_STANDARD
                   PROPERTY STRINGS 11 14 17 20)
    endif()

    # Make sure we keep ourselves to the standard selected (e.g. c++11)
    set(CMAKE_CXX_EXTENSIONS OFF CACHE BOOL
            "Build using no CXX extensions. Keep to the given standard" FORCE)

    # Use default build-type if no build-type has been given yet
    if(NOT CMAKE_BUILD_TYPE)
      loco_validate_with_default(loco_init_BUILD_TYPE "RelWithDebInfo")
      set(CMAKE_BUILD_TYPE ${loco_init_BUILD_TYPE} CACHE STRING
            "Build-type: Debug | Release | RelWithDebInfo | MinSizeRel" FORCE)
      # Set possible options for the build-type
      set_property(CACHE CMAKE_BUILD_TYPE
                   PROPERTY STRINGS "Debug"
                                    "Release"
                                    "MinSizeRel"
                                    "RelWithDebInfo")
      loco_message("By default, set project build-type to ${CMAKE_BUILD_TYPE}")
    endif()

    # Create the compile_commands.json when configuring the project, as it is
    # required by various static-analysis tools (e.g. clangd)
    if(NOT CMAKE_EXPORT_COMPILE_COMMANDS)
      set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL
            "Create compile_commands.json for static-analyzers to use " FORCE)
      loco_message("Exporting compile_commands.json for static-analyzers")
    endif()

    # Generate Position Independent Code (-fPIC), as bindings will need this
    if(NOT CMAKE_POSITION_INDEPENDENT_CODE)
      set(CMAKE_POSITION_INDEPENDENT_CODE ON CACHE BOOL
            "Make use of Position Independen Code generation (-fPIC)" FORCE)
      loco_message("Enabling -fPIC (Position Independent Code generation)")
    endif()

    # If not given, send all Runtime Output Artifacts to the `lib` folder. For
    # further reference on runtime artifacts see the following documentation:
    # https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html, on
    # section `runtime-output-artifacts`
    if(NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY)
      set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE STRING
            "Path where to place runtime objects (.exe, .dll, etc.)" FORCE)
      loco_message("Sending runtime objects to ${CMAKE_BINARY_DIR}/bin")
    endif()

    # If not given, send all Library Output Artifacts to the `lib` folder. For
    # further reference on library artifacts see the following documentation:
    # https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html, on
    # section `library-output-artifacts`
    if(NOT CMAKE_LIBRARY_OUTPUT_DIRECTORY)
      set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib" CACHE STRING
            "Path where to place libraries (.so, static .lib)" FORCE)
      loco_message("Sending all libraries to ${CMAKE_BINARY_DIR}/lib")
    endif()

    # If not given, send all Archive Output Artifacts to the `lib` folder. For
    # further reference on archive artifacts see the following documentation:
    # https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html, on
    # section `archive-output-artifacts`
    if(NOT CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
      set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib" CACHE STRING
            "Path where to place archive libraries (export .lib)" FORCE)
    endif()

    # Make sure that if the user doesn't provide CMAKE_INSTALL_PREFIX, we then
    # use a default path for installation (relative to build)
    if(NOT CMAKE_INSTALL_PREFIX)
      set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/install CACHE STRING
            "Installation path (where to place generated artifacts" FORCE)
      set(CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_PREFIX}/include CACHE STRING
            "Installation path for include headers" FORCE)
      set(CMAKE_INSTALL_LIBDIR ${CMAKE_INSTALL_PREFIX}/lib CACHE STRING
            "Installation path for library output artifacts" FORCE)
      set(CMAKE_INSTALL_BINDIR ${CMAKE_INSTALL_PREFIX}/bin CACHE STRING
            "Installation path for executable output artifacts" FORCE)
      set(CMAKE_INSTALL_DOCDIR ${CMAKE_INSTALL_PREFIX}/doc CACHE STRING
            "Installation path for generated documentation" FORCE)
    endif()

  endif()
  # cmake-format: on
  # ----------------------------------------------------------------------------

endfunction()

# ~~~
# _loco_check_compiler()
#
# Internal helper function that sets the name of the compiler used by the whole
# project during configuration
# ~~~
function(_loco_check_compiler)
  # -----------------------------------
  # Make sure that we're inside a project configuration
  if(NOT PROJECT_NAME)
    loco_message("Must have project in the current scope" LOG_LEVEL WARNING)
    return()
  endif()

  # -----------------------------------
  # Check for the compiler (we currently just support clang, gcc and msvc)
  if(NOT CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*|.*GNU.*|.*MSVC.*")
    loco_message(
      "Compiler [${CMAKE_CXX_COMPILER_ID}] is currently not supported :("
      LOG_LEVEL FATAL_ERROR)
  else()
    loco_message("Using CXX compiler [${CMAKE_CXX_COMPILER_ID}]")
  endif()

endfunction()
