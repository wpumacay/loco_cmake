# -------------------------------------
# Make sure we don't include this twice
include_guard()

# ~~~
# _loco_setup_doxygen(<target-handle>
#       [DOXYGEN_OUT_INDEX <path-doxygen-index>]
#       [DOXYFILE_IN <path-doxyfile-in>]
#       [DOXYFILE_OUT <path-doxyfile-out>]
#       [VERBOSE <verbose>])
#
# Configures `Doxygen` for generating docs for a given target. If the setup
# process succeeds then the cache variable `LOCO_${proj_name_upper}_HAS_DOXYGEN`
# is set to `TRUE`; otherwise, it's set to `FALSE`. Notice that we're assumming
# that the user provides us with a "proper" target (i.e. the include headers can
# be extracted from the include dirs, set by `target_include_directories`).
#
# ~~~
function(_loco_setup_doxygen target_handle)
  string(TOUPPER ${PROJECT_NAME} proj_name_upper)
  set(cache_status_var LOCO_${proj_name_upper}_HAS_DOXYGEN)

  # -----------------------------------
  # Sanity check: we're expecting a target from the user
  if(NOT TARGET ${target_handle})
    loco_message(
      "Expected a valid target, but got '${target_handle}', which is not :("
      LOG_LEVEL WARNING)
    _cache_doxygen_setup_status(${cache_status_var} FALSE
                                "User must provide a valid target :(")
    return()
  endif()

  # -----------------------------------
  # Sanity check: Make sure we have Doxygen installed in our system
  find_package(Doxygen QUIET)
  if(NOT DOXYGEN_FOUND)
    loco_message("Couldn't find 'Doxygen', which is required to generate the "
                 \ "first pass of C/C++ docs generation" LOG_LEVEL WARNING)
    _cache_doxygen_setup_status(
      ${cache_status_var} FALSE
      "Doxygen wasn't found while configuring the project '${PROJECT_NAME}'")
    return()
  else()
    loco_message("Doxygen version='${DOXYGEN_VERSION}' found in your system :)"
                 LOG_LEVEL STATUS)
  endif()

  # -----------------------------------
  set(one_value_args "TARGET" "DOXYFILE_IN" "DOXYFILE_OUT" "DOXYGEN_OUT_INDEX"
                     "VERBOSE")
  cmake_parse_arguments(setup "" "${one_value_args}" "" ${ARGN})

  # -----------------------------------
  # The user gave us a valid target :D. We'll get the include directory from the
  # target itself. Recall that we're assumming INCLUDE_DIRECTORIES is set via
  # `target_include_directories` when configuring the target :)
  get_target_property(target_type ${setup_TARGET} TYPE)
  if(${target_type} STREQUAL "LIBRARY")
    get_target_property(target_include_dirs ${setup_TARGET} INCLUDE_DIRECTORIES)
  elseif(${target_type} STREQUAL "INTERFACE_LIBRARY")
    get_target_property(target_include_dirs ${setup_TARGET}
                        INTERFACE_INCLUDE_DIRECTORIES)
  else()
    loco_message(
      "It seems the given target '${setup_TARGET}' doesn't expose any" \
      " include directories. Stopping docs-generation :(" LOG_LEVEL WARNING)
    _cache_doxygen_setup_status(
      ${cache_status_var} FALSE
      "Given target doesn't provide include directories info")
    return()
  endif()

  # -----------------------------------
  # These variables are later replaced in the Doxyfile.in (@@ placeholder refs)
  set(DOXYGEN_INPUT_DIR "${target_include_dirs}")
  set(DOXYGEN_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/doxygen")

  # -----------------------------------
  # Grab all header files whose docs we will generate
  file(GLOB_RECURSE doxygen_header_files "${DOXYGEN_INPUT_DIR}/*.hpp")
  # Sanity check: should have at least one file to get docs from
  list(LENGTH doxygen_header_files num_header_files)
  if(num_header_files LESS 1)
    loco_message("It seems there are no header files (.hpp) associated with the"
                 \ " given target '${target_handle}' :(" LOG_LEVEL WARNING)
    _cache_doxygen_setup_status(
      ${cache_status_var} FALSE
      "No .hpp files were found associated with the provided target :(")
    return()
  endif()

  # -----------------------------------
  # Keep configuring (if not given by the user, use some reasonable defaults)
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

  # cmake-format: off
  # -----------------------------------
  # Handle Doxygen invocation to generate XML-docs
  add_custom_command(
    OUTPUT ${DOXYGEN_OUT_INDEX}
    DEPENDS ${doxygen_header_files}
    COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYFILE_OUT}
    MAIN_DEPENDENCY ${DOXYFILE_OUT} ${DOXYFILE_IN}
    COMMENT "Configuring docs-generation using 'Doxygen'")
  # cmake-lint: disable=C0113
  add_custom_target(
    ${target_handle}DocsDoxygen ALL DEPENDS ${DOXYGEN_OUT_INDEX})
  # cmake-format: on

  _cache_doxygen_setup_status(
    ${cache_status_var} TRUE
    "'Doxygen' successfully configured for docs-generation" \
    " for target '${target_handle}'")
endfunction()

# ~~~
# _cache_doxygen_setup_status(<var_name> <var_value> <cache_message>)
#
# Sets a status variable with the given `var_name` in the internal global cache
# with the given `var_value`, and corresponding `cache_message`
# ~~~
macro(_cache_doxygen_setup_status var_name var_value cache_message)
  # cmake-format: off
  set(${var_name} ${var_value} CACHE BOOL "${cache_message}" FORCE)
  # cmake-format: on
endmacro()
