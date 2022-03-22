# ~~~
# loco_initialize_project()
#
# Configures the base settings of the current project being processed. We'll
# check if this is the ROOT project. If so, we then proceed with the full setup;
# otherwise, just a partial setup will be applied for this CHILD project
# ~~~
function(loco_initialize_project)
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
    loco_message("Project ${PROJECT_NAME} is a ROOT project")
  else()
    set(project_is_root TRUE) # used here locally
    set(${project_is_root_var_name} TRUE PARENT_SCOPE) # exposed to the dev.
    loco_message("Project ${PROJECT_NAME} is a CHILD project")
  endif()
  # cmake-format: on
  # ----------------------------------------------------------------------------

  # ----------------------------------------------------------------------------
  # Make the following setup only if we're a ROOT project

  # cmake-format: off
  if(project_is_root)
    # Make sure we keep ourselves to the standard selected (e.g. c++11)
    set(CMAKE_CXX_EXTENSIONS OFF CACHE BOOL
            "Build using no CXX extensions. Keep to the given standard" FORCE)

    # Use RelWithDebInfo by default if no built-type has been given yet
    if(NOT CMAKE_BUILD_TYPE)
      set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING
            "Build-type: Debug | Release | RelWithDebInfo | MinSizeRel" FORCE)
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
  endif()
  # cmake-format: on
  # ----------------------------------------------------------------------------

endfunction()
