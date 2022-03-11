# ~~~
# Commonly used helper functions and macros along various repositories I'm
# currently working on
# ~~~

# Helper logging function, similar to `message`, with additional info regarding
# the current project (in the scope in which it's called)
function(RbMessage var_message)
  set(oneValueArgs LOG_LEVEL)
  cmake_parse_arguments(RB_PRINT "" "${oneValueArgs}" "" ${ARGN})

  # Use a dummy name in case in a non-project scope
  if(NOT PROJECT_NAME)
    set(PROJECT_NAME "")
  endif()

  # Use STATUS as default log-level, unless given by the user
  if(NOT RB_PRINT_LOG_LEVEL)
    set(RB_PRINT_LOG_LEVEL "STATUS")
  endif()

  message(${RB_PRINT_LOG_LEVEL} "[${PROJECT_NAME}] >>> ${var_message}")
endfunction()

# Helper function used to summarize all settings defined on a given target
function(RbPrintTargetInfo param_target)
  if(NOT TARGET ${param_target})
    RbMessage("Must give a valid target to grab info from")
    return()
  endif()

  get_target_property(var_target_type ${param_target} TYPE)
  if(var_target_type MATCHES "INTERFACE_LIBRARY")
    get_target_property(var_compile_features ${param_target}
                        INTERFACE_COMPILE_FEATURES)
    get_target_property(var_compile_options ${param_target}
                        INTERFACE_COMPILE_OPTIONS)
    get_target_property(var_compile_definitions ${param_target}
                        INTERFACE_COMPILE_DEFINITIONS)
  elseif(var_target_type MATCHES "EXECUTABLE|LIBRARY")
    get_target_property(var_compile_features ${param_target} COMPILE_FEATURES)
    get_target_property(var_compile_options ${param_target} COMPILE_OPTIONS)
    get_target_property(var_compile_definitions ${param_target}
                        COMPILE_DEFINITIONS)
  endif()

  message("Target [${param_target}] information ------------------------------")
  message("Compile features             : ${var_compile_features}")
  message("Compile options              : ${var_compile_options}")
  message("Compile definitions          : ${var_compile_definitions}")
  message("-------------------------------------------------------------------")
endfunction()

# Helper function used to summarize all settings setup by CMake on this project
function(RbPrintGeneralInfo)
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
