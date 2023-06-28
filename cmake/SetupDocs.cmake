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
  set(target_include_dirs "")
  # Look for first option for the include directories of the target
  get_target_property(target_INCLUDE_DIRECTORIES ${target_handle}
                      INCLUDE_DIRECTORIES)
  if(target_INCLUDE_DIRECTORIES)
    list(APPEND target_include_dirs ${target_INCLUDE_DIRECTORIES})
  endif()
  # Look for the other option for the include directories of the target
  get_target_property(target_INTERFACE_INCLUDE_DIRECTORIES ${target_handle}
                      INTERFACE_INCLUDE_DIRECTORIES)
  if(target_INTERFACE_INCLUDE_DIRECTORIES)
    list(APPEND target_include_dirs ${target_INTERFACE_INCLUDE_DIRECTORIES})
  endif()

  # -----------------------------------
  # Validate if we have at least some information of the include directories. We
  # also have to make sure there are header files at these locations
  set(validated_inc_dirs "")
  set(validated_header_files "")
  foreach(target_inc_dir IN LISTS target_include_dirs)
    file(GLOB_RECURSE list_inc_files "${target_inc_dir}/*.hpp")
    list(LENGTH list_inc_files num_inc_files)
    if(num_inc_files GREATER 0)
      if(NOT target_inc_dir IN_LIST validated_inc_dirs)
        list(APPEND validated_inc_dirs ${target_inc_dir})
        list(APPEND validated_header_files ${list_inc_files})
      endif()
    endif()
  endforeach()
  list(LENGTH validated_inc_dirs num_valid_inc_dirs)
  if(num_valid_inc_dirs LESS 1)
    loco_message(
      "It seems we either don't have any include directories, or we don't \
      have header files at these locations. Warning generated while \
      checking target '${target_handle}'" LOG_LEVEL WARNING)
    return()
  endif()

  # -----------------------------------
  # Doxygen expects files and directories to be space separated. We have CMake
  # lists so far, which are ";" separated, so we'll replace these by spaces to
  # make sure Doxygen doesn't complain about our paths
  string(REPLACE ";" " " validated_inc_dirs_str "${validated_inc_dirs}")

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
  set(DOXYGEN_PROJECT_NAME ${target_handle})
  set(DOXYGEN_INPUT_DIR ${validated_inc_dirs_str})
  set(DOXYGEN_OUTPUT_DIR ${setup_DOXYGEN_OUTPUT_DIR})
  set(DOXYGEN_GENERATE_HTML ${setup_DOXYGEN_GENERATE_HTML})
  set(DOXYGEN_GENERATE_LATEX ${setup_DOXYGEN_GENERATE_LATEX})
  set(DOXYGEN_GENERATE_XML ${setup_DOXYGEN_GENERATE_XML})
  set(DOXYGEN_QUIET ${setup_DOXYGEN_QUIET})

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
    DEPENDS ${validated_header_files}
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
#       [SPHINX_OUTPUT_DIR <output-dir>]
#       [SPHINX_COPYRIGHT <copyright>]
#       [SPHINX_AUTHOR <author>]
#       [SPHINX_BREATHE_PROJECT <breathe-project>]
#       [SPHINX_DOXYGEN_XML_OUTDIR <doxygen-xml-outdir>])
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
  set(SPHINX_PROJECT_NAME ${target_handle})
  set(SPHINX_PROJECT_COPYRIGHT ${setup_SPHINX_COPYRIGHT})
  set(SPHINX_PROJECT_AUTHOR ${setup_SPHINX_AUTHOR})
  set(SPHINX_PROJECT_VERSION ${PROJECT_VERSION})
  # Use Breathe if there is any project requested by the user
  if(setup_SPHINX_BREATHE_PROJECT)
    loco_message("Configuring Sphinx for Doxygen integration via Breathe")
    set(breathe_comment "# Breathe configuration")
    set(breathe_variable "breathe_default_project")
    set(breathe_value "\"${setup_SPHINX_BREATHE_PROJECT}\"")
    set(breathe_projects_value
        "{\"${target_handle}\": \"${setup_SPHINX_DOXYGEN_XML_OUTDIR}\"}")
    set(SPHINX_BREATHE_EXTENSION "extensions.append('breathe')")
    set(SPHINX_BREATHE_PROJECTS_DICT
        "${breathe_comment}\nbreathe_projects = ${breathe_projects_value}")
    set(SPHINX_BREATHE_DEFAULT_PROJECT
        "${breathe_variable} = ${breathe_value}\n")
  else()
    # If not integrating with doxygen via breathe, then just dismiss the option
    set(SPHINX_BREATHE_EXTENSION "")
    set(SPHINX_BREATHE_PROJECTS_DICT "")
    set(SPHINX_BREATHE_DEFAULT_PROJECT "")
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
        ${SPHINX_EXECUTABLE} -b html ${sphinx_source_dir} ${sphinx_build_dir}
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
#       [SPHINX_OUTPUT_DIR <sphinx-output-dir>]
#       [SPHINX_COPYRIGHT <sphinx-copyright>]
#       [SPHINX_AUTHOR <sphinx-author>]
#       [SPHINX_BREATHE_PROJECT <sphinx-breathe-project>]
#       [SPHINX_DOXYGEN_XML_OUTDIR <sphinx-doxygen-xml-outdir>])
#
# Configures doxygen + sphinx + breathe to generate documentation for the
# given `target-handle`. These docs would consists of separate user-generated
# documentation using markdown (.md) or restructuredText (.rst), as well as the
# auto-generated documentation extracted from the docstrings in the header files
# associated with the given target (if any).
# ~~~
function(loco_setup_cppdocs target_handle)

  set(one_value_args
      "DOXYGEN_FILE_IN"
      "DOXYGEN_OUTPUT_DIR"
      "DOXYGEN_GENERATE_HTML"
      "DOXYGEN_GENERATE_LATEX"
      "DOXYGEN_GENERATE_XML"
      "DOXYGEN_QUIET"
      "SPHINX_FILE_IN"
      "SPHINX_OUTPUT_DIR"
      "SPHINX_COPYRIGHT"
      "SPHINX_AUTHOR"
      "SPHINX_BREATHE_PROJECT"
      "SPHINX_DOXYGEN_XML_OUTDIR")
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

  loco_validate_with_default(setup_SPHINX_FILE_IN
                             ${PROJECT_SOURCE_DIR}/docs/conf.py.in)
  loco_validate_with_default(setup_SPHINX_OUTPUT_DIR
                             ${PROJECT_BINARY_DIR}/docs/Sphinx)
  loco_validate_with_default(setup_SPHINX_COPYRIGHT "2022, ${PROJECT_NAME}")
  loco_validate_with_default(setup_SPHINX_AUTHOR "Anomymous")
  loco_validate_with_default(setup_SPHINX_BREATHE_PROJECT "")
  loco_validate_with_default(setup_SPHINX_DOXYGEN_XML_OUTDIR
                             ${PROJECT_BINARY_DIR}/docs/Doxygen/xml)

  # cmake-format: off
  # -----------------------------------
  # Configure Doxygen XML output
  loco_setup_cppdocs_doxygen(${target_handle}
    DOXYGEN_FILE_IN ${setup_DOXYGEN_FILE_IN}
    DOXYGEN_OUTPUT_DIR ${setup_DOXYGEN_OUTPUT_DIR}
    DOXYGEN_GENERATE_HTML ${setup_DOXYGEN_GENERATE_HTML}
    DOXYGEN_GENERATE_LATEX ${setup_DOXYGEN_GENERATE_LATEX}
    DOXYGEN_GENERATE_XML ${setup_DOXYGEN_GENERATE_XML}
    DOXYGEN_QUIET ${setup_DOXYGEN_QUIET})

  # -----------------------------------
  # Configure Sphinx + Breathe
  loco_setup_cppdocs_sphinx(${target_handle}
    SPHINX_FILE_IN ${setup_SPHINX_FILE_IN}
    SPHINX_OUTPUT_DIR ${setup_SPHINX_OUTPUT_DIR}
    SPHINX_COPYRIGHT ${setup_SPHINX_COPYRIGHT}
    SPHINX_AUTHOR ${setup_SPHINX_AUTHOR}
    SPHINX_BREATHE_PROJECT ${setup_SPHINX_BREATHE_PROJECT}
    SPHINX_DOXYGEN_XML_OUTDIR ${setup_SPHINX_DOXYGEN_XML_OUTDIR})
  # cmake-format: on
endfunction()
