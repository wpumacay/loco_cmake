# -------------------------------------
# Make sure we don't include this twice
include_guard()

# ~~~
# loco_setup_cppdocs_doxygen(<target-handle>
#       [DOXYGEN_FILE_IN <path-to-doxyfile>]
#       [DOXYGEN_OUTPUT_DIR <output-dir>]
#       [DOXYGEN_GENERATE_HTML <generate-html>]
#       [DOXYGEN_GENERATE_LATEX <generate-latex>]
#       [DOXYGEN_GENERATE_XML <generate-xml>]
#       [DOXYGEN_QUIET <quiet>])
#
# Configures `Doxygen` for generating docs for a given target. Notice that we're
# assumming that the user provides us with a "proper" target (i.e. the include
# headers can be extracted from the include dirs, set by
# `target_include_directories`).
#
# ~~~
function(loco_setup_cppdocs_doxygen target_handle)
  # cmake-lint: disable=R0915

  # -----------------------------------
  # Sanity check: we're expecting a target from the user
  if(NOT TARGET ${target_handle})
    loco_message(
      "Expected a valid target, but got '${target_handle}', which is not :("
      LOG_LEVEL WARNING)
    return()
  endif()

  # -----------------------------------
  # Sanity check: Make sure we have Doxygen installed in our system
  find_package(Doxygen QUIET)
  if(NOT DOXYGEN_FOUND)
    loco_message(
      "Couldn't find 'Doxygen', which is required to generate C/C++ docs"
      LOG_LEVEL ERROR)
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
    return()
  endif()

  # ------------------------------------
  # Set some sensible defaults
  loco_validate_with_default(setup_DOXYGEN_FILE_IN
                             ${PROJECT_SOURCE_DIR}/docs/Doxyfile.in)
  loco_validate_with_default(setup_DOXYGEN_OUTPUT_DIR
                             ${PROJECT_BINARY_DIR}/docs/Doxygen)
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
  # Notify the caller that everyting went well during the configuration
  set(LOCO_${PROJECT_NAME}_DOXYGEN
      TRUE
      PARENT_SCOPE)
endfunction()

# ~~~
# loco_setup_cppdocs_sphinx(<target-handle>
#       [SPHINX_FILE_IN <input-dir>]
#       [SPHINX_OUTPUT_DIR <output-dir>])
#
# Configures `Sphinx` for generating docs for a given target.
# ~~~
function(loco_setup_cppdocs_sphinx target_handle)
  # cmake-lint: disable=R0915

  # -----------------------------------
  # Sanity check: we're expecting a target from the user
  if(NOT TARGET ${target_handle})
    loco_message(
      "Expected a valid target, but got '${target_handle}', which is not :("
      LOG_LEVEL WARNING)
    return()
  endif()

  # -----------------------------------
  # Sanity check: Make sure we have Sphinx installed in our system
  find_package(Sphinx QUIET)
  if(NOT Sphinx_FOUND)
    loco_message(
      "Couldn't find 'Sphinx', which is required to generate the main docs"
      LOG_LEVEL ERROR)
    return()
  else()
    loco_message("Sphinx was successfully found in your system :)" LOG_LEVEL
                 STATUS)
  endif()

  # -----------------------------------
  set(one_value_args
      "SPHINX_FILE_IN" "SPHINX_OUTPUT_DIR" "SPHINX_COPYRIGHT" "SPHINX_AUTHOR"
      "SPHINX_BREATHE_PROJECT" "SPHINX_DOXYGEN_XML_OUTDIR")
  cmake_parse_arguments(setup "" "${one_value_args}" "" ${ARGN})

  # ------------------------------------
  # Set some sensible defaults
  loco_validate_with_default(setup_SPHINX_FILE_IN
                             ${PROJECT_SOURCE_DIR}/docs/conf.py.in)
  loco_validate_with_default(setup_SPHINX_OUTPUT_DIR
                             ${PROJECT_BINARY_DIR}/docs/Sphinx)
  loco_validate_with_default(setup_SPHINX_COPYRIGHT "2022, ${PROJECT_NAME}")
  loco_validate_with_default(setup_SPHINX_AUTHOR "Anomymous")
  loco_validate_with_default(setup_SPHINX_BREATHE_PROJECT "")
  loco_validate_with_default(setup_SPHINX_DOXYGEN_XML_OUTDIR
                             ${PROJECT_BINARY_DIR}/docs/Doxygen/xml)

  # -----------------------------------
  # These variables will be replaced in the conf.py.in file during configuration
  set(SPHINX_PROJECT_NAME ${PROJECT_NAME})
  set(SPHINX_PROJECT_COPYRIGHT ${setup_SPHINX_COPYRIGHT})
  set(SPHINX_PROJECT_AUTHOR ${setup_SPHINX_AUTHOR})
  set(SPHINX_PROJECT_VERSION ${PROJECT_VERSION})
  # Use Breathe if there is any project requested by the user
  if(setup_SPHINX_BREATHE_PROJECT)
    loco_message("Configuring Sphinx for Doxygen integration via Breathe")
    set(breathe_comment "#Breathe configuration")
    set(breathe_variable "breathe_default_project")
    set(breathe_value "\"${setup_SPHINX_BREATHE_PROJECT}\"")
    set(SPHINX_BREATHE_EXTENSION "extensions.append('breathe')")
    set(SPHINX_BREATHE_PROJECT
        "${breathe_comment}\n${breathe_variable} = ${breathe_value}\n")
  else()
    # If not integrating with doxygen via breathe, then just dismiss the option
    set(SPHINX_BREATHE_EXTENSION "")
    set(SPHINX_BREATHE_PROJECT "")
  endif()

  # -----------------------------------
  # Get where the sources are located (conf.py, index.rst, etc.). We are
  # assumming that all these are in a single directory in /docs somewhere
  get_filename_component(sphinx_source_dir ${setup_SPHINX_FILE_IN} DIRECTORY)

  # -----------------------------------
  set(sphinx_conffile_in ${setup_SPHINX_FILE_IN})
  set(sphinx_conffile_out ${sphinx_source_dir}/conf.py)
  set(sphinx_build_dir ${setup_SPHINX_OUTPUT_DIR})
  set(sphinx_working_dir ${setup_SPHINX_OUTPUT_DIR})
  set(sphinx_index_file ${sphinx_build_dir}/index.html)
  # Create the output directory (just in case not created yet)
  file(MAKE_DIRECTORY ${sphinx_build_dir})
  # Replace variables in between @@ on the Doxyfile.in with the actual values
  configure_file(${sphinx_conffile_in} ${sphinx_conffile_out} @ONLY)

  # cmake-format: off
  # -----------------------------------
  # Handle Sphinx invocation to generate nicer-docs
  if(NOT setup_SPHINX_BREATHE_PROJECT)
    loco_message("Running Sphinx WITHOUT Breathe integration")
    add_custom_command(
      OUTPUT ${sphinx_index_file}
      COMMAND
        ${SPHINX_EXECUTABLE} -b html ${sphinx_source_dir} ${sphinx_build_dir}
      WORKING_DIRECTORY ${sphinx_working_dir}
      DEPENDS ${sphinx_source_dir}/index.rst
      MAIN_DEPENDENCY ${sphinx_conffile_out}
      COMMENT
        "${PROJECT_NAME} >>> running docs-generation using Sphinx")
  else()
    loco_message("Running Sphinx WITH Breathe integration")
    set(sphinx_doxygen_index_file ${setup_SPHINX_DOXYGEN_XML_OUTDIR}/index.xml)
    add_custom_command(
      OUTPUT ${sphinx_index_file}
      COMMAND
        ${SPHINX_EXECUTABLE} -b html
        # Tell breathe where to find the Doxygen xml output
        -Dbreathe_projects.${PROJECT_NAME}=${setup_SPHINX_DOXYGEN_XML_OUTDIR}
        ${sphinx_source_dir} ${sphinx_build_dir}
      WORKING_DIRECTORY ${sphinx_working_dir}
      DEPENDS ${sphinx_source_dir}/index.rst ${sphinx_doxygen_index_file}
      MAIN_DEPENDENCY ${sphinx_conffile_out}
      COMMENT
        "${PROJECT_NAME} >>> running docs-generation using Sphinx + Breathe")
  endif()
  # cmake-format: on
  add_custom_target(
    ${target_handle}DocsSphinx ALL
    DEPENDS ${sphinx_index_file}
    COMMENT "Constructing Sphinx docs-generation target")

  loco_message("Successfully configured Sphinx docs generations")
  # Notify the caller that everyting went well during the configuration
  set(LOCO_${PROJECT_NAME}_SPHINX
      TRUE
      PARENT_SCOPE)
endfunction()

# ~~~
# loco_setup_cppdocs(<target-handle>
#       [DOXYGEN_FILE_IN <path-to-doxyfile>]
#       [DOXYGEN_OUTPUT_DIR <output-dir>]
#       [DOXYGEN_GENERATE_HTML <generate-html>]
#       [DOXYGEN_GENERATE_LATEX <generate-latex>]
#       [DOXYGEN_GENERATE_XML <generate-xml>]
#       [DOXYGEN_QUIET <quiet>]
#       [SPHINX_FILE_IN <sphinx-input-dir>]
#       [SPHINX_OUTPUT_DIR <sphinx-output-dir>])
#
# Configures doxygen + sphinx + breathe to generate documentation for the
# given `target-handle`. These docs would consists of separate user-generated
# documentation using markdown (.md) or restructuredText (.rst), as well as the
# auto-generated documentation extracted from the docstrings in the header files
# associated with the given target (if any).
# ~~~
function(loco_setup_cppdocs target_handle)

  set(one_value_args"DOXYGEN_FILE_IN"
      "DOXYGEN_OUTPUT_DIR" "DOXYGEN_GENERATE_HTML" "DOXYGEN_GENERATE_LATEX"
      "DOXYGEN_GENERATE_XML" "DOXYGEN_QUIET" "SPHINX_FILE_IN"
      "SPHINX_OUTPUT_DIR")
  cmake_parse_arguments(setup "" "${one_value_args}" "" ${ARGN})
  # TODO(wilbert): Check if not-defined here are passed down as not-defined
  # ------------------------------------
  # Validate with some sensible defaults first, as might pass over not-defined
  loco_validate_with_default(setup_DOXYGEN_FILE_IN
                             ${PROJECT_SOURCE_DIR}/docs/Doxyfile.in)
  loco_validate_with_default(setup_DOXYGEN_OUTPUT_DIR
                             ${PROJECT_BINARY_DIR}/docs)
  loco_validate_with_default(setup_DOXYGEN_GENERATE_HTML TRUE)
  loco_validate_with_default(setup_DOXYGEN_GENERATE_LATEX TRUE)
  loco_validate_with_default(setup_DOXYGEN_GENERATE_XML TRUE)
  loco_validate_with_default(setup_DOXYGEN_QUIET TRUE)

endfunction()
