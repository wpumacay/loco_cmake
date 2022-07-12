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
  # cmake-lint: disable=R0915
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
    loco_message("Couldn't find 'Doxygen', which is required to generate the \"
                  first pass of C/C++ docs generation" LOG_LEVEL ERROR)
    _cache_doxygen_setup_status(
      ${cache_status_var} FALSE
      "Doxygen wasn't found while configuring the project '${PROJECT_NAME}'")
    return()
  else()
    loco_message("Doxygen version='${DOXYGEN_VERSION}' found in your system :)"
                 LOG_LEVEL STATUS)
  endif()

  # -----------------------------------
  set(one_value_args
      "DOXYGEN_FILE_IN" "DOXYGEN_OUTPUT_DIR" "DOXYGEN_GENERATE_HTML"
      "DOXYGEN_GENERATE_XML" "DOXYGEN_GENERATE_LATEX" "DOXYGEN_QUIET")
  cmake_parse_arguments(setup "" "${one_value_args}" "" ${ARGN})

  # -----------------------------------
  # The user gave us a valid target :D. We'll get the include directory from the
  # target itself. Recall that we're assumming INCLUDE_DIRECTORIES is set via
  # `target_include_directories` when configuring the target :)
  get_target_property(target_type ${target_handle} TYPE)
  if(${target_type} MATCHES "LIBRARY")
    get_target_property(target_include_dirs ${target_handle}
                        INCLUDE_DIRECTORIES)
  elseif(${target_type} MATCHES "INTERFACE_LIBRARY")
    get_target_property(target_include_dirs ${target_handle}
                        INTERFACE_INCLUDE_DIRECTORIES)
  else()
    loco_message("Given target doesn't provide include-directories info"
                 LOG_LEVEL WARNING)
    _cache_doxygen_setup_status(
      ${cache_status_var} FALSE
      "Given target doesn't provide include-directories info")
    return()
  endif()

  # ------------------------------------
  # Set some sensible defaults
  loco_validate_with_default(setup_DOXYGEN_FILE_IN
                             ${PROJECT_SOURCE_DIR}/docs/Doxyfile.in)
  loco_validate_with_default(setup_DOXYGEN_OUTPUT_DIR
                             ${PROJECT_BINARY_DIR}/docs)
  loco_validate_with_default(setup_DOXYGEN_GENERATE_HTML TRUE)
  loco_validate_with_default(setup_DOXYGEN_GENERATE_LATEX TRUE)
  loco_validate_with_default(setup_DOXYGEN_GENERATE_XML TRUE)
  loco_validate_with_default(setup_DOXYGEN_QUIET TRUE)

  # -----------------------------------
  # Should generate at least one artifact (html|latex|xml)
  if((NOT setup_DOXYGEN_GENERATE_HTML)
     AND (NOT setup_DOXYGEN_GENERATE_LATEX)
     AND (NOT setup_DOXYGEN_GENERATE_XML))
    loco_message(
      "At least one generated artifact should be enabled (html|latex|xml)")
    _cache_doxygen_setup_status(
      ${cache_status_var} FALSE
      "At least one generated artifact should be enabled (html|latex|xml)")
    return()
  endif()

  # -----------------------------------
  # These variables are later replaced in the Doxyfile.in (@@ placeholder refs)
  set(DOXYGEN_PROJECT_NAME ${PROJECT_NAME})
  set(DOXYGEN_INPUT_DIR "${target_include_dirs}")
  set(DOXYGEN_OUTPUT_DIR ${setup_DOXYGEN_OUTPUT_DIR})
  set(DOXYGEN_GENERATE_HTML ${setup_DOXYGEN_GENERATE_HTML})
  set(DOXYGEN_GENERATE_LATEX ${setup_DOXYGEN_GENERATE_LATEX})
  set(DOXYGEN_GENERATE_XML ${setup_DOXYGEN_GENERATE_XML})
  set(DOXYGEN_QUIET ${setup_DOXYGEN_QUIET})

  # -----------------------------------
  # Grab all header files whose docs we will generate
  file(GLOB_RECURSE doxygen_header_files "${DOXYGEN_INPUT_DIR}/*.hpp")
  # Sanity check: should have at least one file to get docs from
  list(LENGTH doxygen_header_files num_header_files)
  if(num_header_files LESS 1)
    loco_message("It seems there are no header files (hpp) associated with the\"
                 given target '${target_handle}' :(" LOG_LEVEL WARNING)
    _cache_doxygen_setup_status(
      ${cache_status_var} FALSE
      "No .hpp files were found associated with the provided target :(")
    return()
  endif()

  # -----------------------------------
  set(doxyfile_in ${setup_DOXYGEN_FILE_IN})
  set(doxyfile_out ${setup_DOXYGEN_OUTPUT_DIR}/Doxyfile)
  set(doxygen_artifacts "")
  if(DOXYGEN_GENERATE_HTML)
    list(APPEND doxygen_artifacts ${setup_DOXYGEN_OUTPUT_DIR}/html/index.html)
  endif()
  if(DOXYGEN_GENERATE_LATEX)
    list(APPEND doxygen_artifacts ${setup_DOXYGEN_OUTPUT_DIR}/latex/files.tex)
  endif()
  if(DOXYGEN_GENERATE_XML)
    list(APPEND doxygen_artifacts ${setup_DOXYGEN_OUTPUT_DIR}/xml/index.xml)
  endif()
  # Create the output directory (just in case not created yet)
  file(MAKE_DIRECTORY ${setup_DOXYGEN_OUTPUT_DIR})
  # Replace variables in between @@ on the Doxyfile.in with the actual values
  configure_file(${setup_DOXYGEN_FILE_IN} ${setup_DOXYGEN_OUTPUT_DIR}/Doxyfile
                 @ONLY)

  # cmake-format: off
  # -----------------------------------
  # Handle Doxygen invocation to generate XML-docs
  add_custom_command(
    OUTPUT ${doxygen_artifacts}
    DEPENDS ${doxygen_header_files}
    COMMAND ${DOXYGEN_EXECUTABLE} ${doxyfile_out}
    MAIN_DEPENDENCY ${doxyfile_out} ${doxyfile_in}
    COMMENT "Configuring docs-generation using 'Doxygen...'")
  # cmake-lint: disable=C0113
  add_custom_target(
    ${target_handle}DocsDoxygen ALL DEPENDS ${doxygen_artifacts})
  # cmake-format: on

  loco_message("Successfully configured Doxygen docs generations for\
    artifacts ${doxygen_artifacts}")
  _cache_doxygen_setup_status(
    ${cache_status_var} TRUE "'Doxygen' successfully configured for \
    docs-generation for target '${target_handle}'")
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
