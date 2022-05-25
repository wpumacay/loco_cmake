# -------------------------------------
# Make sure we don't include this twice
include_guard()

# ~~~
# _loco_setup_doxygen(
#       [TARGET <target>]
#       [DOXYGEN_INPUT_DIR <path-doxygen-input-dir>]
#       [DOXYGEN_OUTPUT_DIR <path-doxygen-output-dir>]
#       [DOXYGEN_OUT_INDEX <path-doxygen-index>]
#       [DOXYFILE_IN <path-doxyfile-in>]
#       [DOXYFILE_OUT <path-doxyfile-out>]
#       [VERBOSE <verbose>])
#
# Configures `Doxygen` for generating docs for a given target (or custom user
# configuration given by the INPUT and OUTPUT directories). If `Doxygen` is
# found, then the cache variable LOCO_CMAKE_HAS_DOXYGEN is set to TRUE; and set
# to FALSE otherwise (can't find via `find_package(Doxygen)`)
#
# ~~~
function(_loco_setup_doxygen)
  string(TOUPPER ${PROJECT_NAME} proj_name_upper)
  set(cache_status_varname LOCO_${proj_name_upper}_HAS_DOXYGEN)
  # -----------------------------------
  # Sanity check: Make sure we have Doxygen installed in our system
  find_package(Doxygen QUIET)
  if(NOT DOXYGEN_FOUND)
    loco_message("Couldn't find 'Doxygen', which is required to generate the "
                 \ "first pass of C/C++ docs generation" LOG_LEVEL WARNING)
    _loco_cache_status_variable(
      ${cache_status_varname} FALSE
      "No Doxygen found while configuring the project '${PROJECT_NAME}'")
    return()
  endif()
  _loco_cache_status_variable(
    ${cache_status_varname} TRUE
    "Doxygen found in your system, with version '${DOXYGEN_VERSION}'")

  set(options)
  set(one_value_args "TARGET" "DOXYGEN_INPUT_DIR" "DOXYGEN_OUTPUT_DIR"
                     "DOXYFILE_IN" "DOXYFILE_OUT" "DOXYGEN_OUT_INDEX" "VERBOSE")
  set(multi_value_args "")
  cmake_parse_arguments(setup "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # -----------------------------------
  # Make sure we have a valid configuration given by the user
  if((NOT TARGET ${setup_TARGET}) AND ((NOT setup_DOXYGEN_INPUT_DIR)
                                       OR (NOT setup_DOXYGEN_OUTPUT_DIR)))
    loco_message("Must provide either single 'target' or both 'input'" \
                 " and 'output' doxygen directories" LOG_LEVEL WARNING)
    _loco_cache_status_variable(${cache_status_varname} FALSE
                                "User must provide valid configuration :(")
    return()
  endif()

  if(TARGET ${setup_TARGET})
    # The user gave us a valid target :D. In this mode, we'll get the include
    # directory from the target itself. We're assumming the INCLUDE_DIRECTORIES
    # set via `target_include_directories` was used to configure this target :)
    get_target_property(doxygen_target_type ${setup_TARGET} TYPE)
    if(${doxygen_target_type} STREQUAL "LIBRARY")
      get_target_property(doxygen_target_include_dirs ${setup_TARGET}
                          INCLUDE_DIRECTORIES)
    elseif(${doxygen_target_type} STREQUAL "INTERFACE_LIBRARY")
      get_target_property(doxygen_target_include_dirs ${setup_TARGET}
                          INTERFACE_INCLUDE_DIRECTORIES)
    else()
      loco_message(
        "It seems the given target '${setup_TARGET}' doesn't expose any" \
        " include directories. Stopping docs-generation :(" LOG_LEVEL WARNING)
      _loco_cache_status_variable(
        ${cache_status_varname} FALSE
        "Given target doesn't provide include-directories")
      return()
    endif()

    # Set the INPUT dir according to the target-includes
    set(DOXYGEN_INPUT_DIR "${doxygen_target_include_dirs}")
    # Set the OUTPUT dir to a fixed location (@todo: reuse OUTPUT_DIR if given)
    set(DOXYGEN_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/doxygen")
  elseif((NOT setup_DOXYGEN_INPUT_DIR STREQUAL "")
         AND (NOT setup_DOXYGEN_OUTPUT_DIR STREQUAL ""))
    # The user gave us both valid INPUT and OUTPUT directories, so fingers
    # crossed T_T' (@todo: validate the path or just assume user not trolling)
    set(DOXYGEN_INPUT_DIR "${setup_DOXYGEN_INPUT_DIR}")
    set(DOXYGEN_OUTPUT_DIR "${setup_DOXYGEN_OUTPUT_DIR}")
  else()
    loco_message("Wtf?!. Shouldn't get here o.O'" LOG_LEVEL FATAL_ERROR)
  endif()

  # -----------------------------------
  # Grab all header files whose docs we will generate
  file(GLOB_RECURSE doxygen_include_files "${DOXYGEN_INPUT_DIR}/*.hpp")

  # -----------------------------------
  # Keep configuring (if not given by the user, use some appropriate defaults)
  loco_validate_with_default(setup_DOXYGEN_OUT_INDEX
                             "${doxygen_output_dir}/html/index.html")
  loco_validate_with_default(setup_DOXYFILE_IN
                             "${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in")
  loco_validate_with_default(setup_DOXYFILE_OUT
                             "${CMAKE_CURRENT_BINARY_DIR}/Doxyfile")
  set(DOXYGEN_OUT_INDEX ${setup_DOXYGEN_OUT_INDEX})
  set(DOXYFILE_IN ${setup_DOXYFILE_IN})
  set(DOXYFILE_OUT ${setup_DOXYFILE_OUT})
  # Create the output directory (just in case not created yet)
  file(MAKE_DIRECTORY ${DOXYGEN_OUTPUT_DIR})
  # Replace variables in between @@ on the Doxyfile.in with the actual values
  configure_file(${DOXYFILE_IN} ${DOXYFILE_OUT} @ONLY)

  # -----------------------------------
  # Make a custom command to handle the Doxygen invocation
  # ~~~
  # add_custom_command(
  #  OUTPUT ${DOXYGEN_OUT_INDEX}
  #  DEPENDS ${doxygen_include_files}
  #  COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYFILE_OUT}
  #  )
  # ~~~

endfunction()

# ~~~
# _loco_cache_status_variable(<var_name> <var_value> <cache_message>)
#
# Sets a status variable with the given `var_name` in the internal global cache
# with the given `var_value`, and corresponding `cache_message`
# ~~~
macro(_loco_cache_status_variable var_name var_value cache_message)
  set(${var_name}
      ${var_value}
      CACHE INTERNAL "${cache_message}" FORCE)
endmacro()
