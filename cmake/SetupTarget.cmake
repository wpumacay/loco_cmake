# -------------------------------------
# Make sure we don't include this twice
include_guard()

# cmake-lint: disable=C0301
# cmake-format: off
# -------------------------------------
# Default warnings for CLANG. Taken from cpp-best-practices (@github below):
# cpp-best-practices/project_options/blob/main/src/CompilerWarnings.cmake#L44
set(CLANG_BASE_WARNINGS
    -Wall
    -Wextra # reasonable and standard
    -Wshadow # warn the user if a variable declaration shadows one from a parent context
    -Wnon-virtual-dtor # warn the user if a class with virtual functions has a non-virtual destructor. This helps
    # catch hard to track down memory errors
    -Wold-style-cast # warn for c-style casts
    -Wcast-align # warn for potential performance problem casts
    -Wunused # warn on anything being unused
    -Woverloaded-virtual # warn if you overload (not override) a virtual function
    -Wpedantic # warn if non-standard C++ is used
    -Wconversion # warn on type conversions that may lose data
    -Wsign-conversion # warn on sign conversions
    -Wnull-dereference # warn if a null dereference is detected
    -Wdouble-promotion # warn if float is implicit promoted to double
    -Wformat=2 # warn on security issues around functions that format output (ie printf)
    -Wimplicit-fallthrough # warn on statements that fallthrough without an explicit annotation
)

# -------------------------------------
# Default warnings for MSVC. Taken from cpp-best-practices (@github below):
# cpp-best-practices/project_options/blob/main/src/CompilerWarnings.cmake#L16
set(MSVC_BASE_WARNINGS
    /W4 # Baseline reasonable warnings
    /w14242 # 'identifier': conversion from 'type1' to 'type1', possible loss of data
    /w14254 # 'operator': conversion from 'type1:field_bits' to 'type2:field_bits', possible loss of data
    /w14263 # 'function': member function does not override any base class virtual member function
    /w14265 # 'classname': class has virtual functions, but destructor is not virtual instances of this class may not
            # be destructed correctly
    /w14287 # 'operator': unsigned/negative constant mismatch
    /we4289 # nonstandard extension used: 'variable': loop control variable declared in the for-loop is used outside
            # the for-loop scope
    /w14296 # 'operator': expression is always 'boolean_value'
    /w14311 # 'variable': pointer truncation from 'type1' to 'type2'
    /w14545 # expression before comma evaluates to a function which is missing an argument list
    /w14546 # function call before comma missing argument list
    /w14547 # 'operator': operator before comma has no effect; expected operator with side-effect
    /w14549 # 'operator': operator before comma has no effect; did you intend 'operator'?
    /w14555 # expression has no effect; expected expression with side- effect
    /w14619 # pragma warning: there is no warning number 'number'
    /w14640 # Enable warning on thread un-safe static member initialization
    /w14826 # Conversion from 'type1' to 'type_2' is sign-extended. This may cause unexpected runtime behavior.
    /w14905 # wide string literal cast to 'LPSTR'
    /w14906 # string literal cast to 'LPWSTR'
    /w14928 # illegal copy-initialization; more than one user-defined conversion has been implicitly applied
    /permissive- # standards conformance mode for MSVC compiler.
)

# -------------------------------------
# Default warnings for GCC. Taken from cpp-best-practices (@github below):
# cpp-best-practices/project_options/blob/main/src/CompilerWarnings.cmake#L65
set(GCC_BASE_WARNINGS
    ${CLANG_BASE_WARNINGS}
    -Wmisleading-indentation # warn if indentation implies blocks where blocks do not exist
    -Wduplicated-cond # warn if if / else chain has duplicated conditions
    -Wduplicated-branches # warn if if / else branches have duplicated code
    -Wlogical-op # warn about logical operations being used where bitwise were probably wanted
    -Wuseless-cast # warn if you perform a cast to the same type
)
# cmake-format: on

# ~~~
# loco_setup_target(<target>
#       [SOURCES <sources>...]
#       [INCLUDE_DIRECTORIES <include-dirs>...]
#       [TARGET_DEPENDENCIES <target-dependencies>...]
#       [WARNINGS_AS_ERRORS <Werror>]
#       [CLANG_WARNINGS <clang-warnings>...]
#       [GCC_WARNINGS <gcc-warnings>...]
#       [MSVC_WARNINGS <msvc-warnings>...])
#
# Creates and configures the given target given the provided properties
# ~~~
function(loco_setup_target target)
  set(options "WARNINGS_AS_ERRORS")
  set(one_value_args)
  set(multi_value_args "SOURCES" "INCLUDE_DIRECTORIES" "TARGET_DEPENDENCIES")
  cmake_parse_arguments(setup "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # -----------------------------------
  if(DEFINED setup_SOURCES)
    target_sources(${target} PUBLIC ${setup_SOURCES})
  endif()

  # -----------------------------------
  if(DEFINED setup_INCLUDE_DIRECTORIES)
    foreach(include_dir ${setup_INCLUDE_DIRECTORIES})
      target_include_directories(${target} PUBLIC ${include_dir})
    endforeach()
  endif()

  # -----------------------------------
  if(DEFINED setup_TARGET_DEPENDENCIES)
    foreach(target_dep ${setup_TARGET_DEPENDENCIES})
      target_link_libraries(${target} PUBLIC ${target_dep})
    endforeach()
  endif()

  # cmake-format: off
  # -----------------------------------
  # Setup the appropriate|required compiler settings
  loco_setup_target_compiler_settings(${target}
                            WARNINGS_AS_ERRORS ${setup_WARNINGS_AS_ERRORS}
                            CLANG_WARNINGS ${setup_CLANG_WARNINGS}
                            GCC_WARNINGS ${setup_GCC_WARNINGS}
                            MSVC_WARNINGS ${setup_MSVC_WARNINGS})
  # cmake-format: on

endfunction()

# ~~~
# loco_setup_target_compiler_warnings(<target>
#       [WARNINGS_AS_ERRORS <Werror>]
#       [CLANG_WARNINGS <clang-warnings>...]
#       [GCC_WARNINGS <gcc-warnings>...]
#       [MSVC_WARNINGS <msvc-warnings>...])
#
#
# ~~~
function(loco_setup_target_compiler_settings target)
  set(options "WARNINGS_AS_ERRORS")
  set(one_value_args)
  set(multi_value_args "CLANG_WARNINGS" "GCC_WARNINGS" "MSVC_WARNINGS")
  cmake_parse_arguments(compiler "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  loco_validate_with_default(compiler_WARNINGS_AS_ERRORS FALSE)
  loco_validate_with_default(compiler_CLANG_WARNINGS "${CLANG_BASE_WARNINGS}")
  loco_validate_with_default(compiler_GCC_WARNINGS "${GCC_BASE_WARNINGS}")
  loco_validate_with_default(compiler_MSVC_WARNINGS "${MSVC_BASE_WARNINGS}")

  if(compiler_WARNINGS_AS_ERRORS)
    loco_message("Hey there!, we're treating WARNINGS as ERRORS!!!")
    list(APPEND compiler_CLANG_WARNINGS -Werror)
    list(APPEND compiler_GCC_WARNINGS -Werror)
    list(APPEND compiler_MSVC_WARNINGS /WX)
  endif()

  if(MSVC)
    set(project_warnings_cxx ${compiler_MSVC_WARNINGS})
  elseif(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*")
    set(project_warnings_cxx ${compiler_CLANG_WARNINGS})
  elseif(CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*")
    set(project_warnings_cxx ${compiler_GCC_WARNINGS})
  else()
    loco_message(
      "Compiler [${CMAKE_CXX_COMPILER_ID}] is currently not supported :("
      LOG_LEVEL FATAL_ERROR)
  endif()

  set(project_warnings_c ${project_warnings_cxx})
  list(REMOVE_ITEM project_warnings_c -Wnon-virtual-dtor -Wold-style-cast
       -Woverloaded-virtual -Wuseless-cast)

  get_target_property(target_type ${target} TYPE)
  if(target_type MATCHES "INTERFACE_LIBRARY")
    target_compile_options(
      ${target} INTERFACE $<$<COMPILE_LANGUAGE:CXX>:${project_warnings_cxx}>
                          $<COMPILE_LANGUAGE:C>:${project_warnings_c}>)
  elseif(target_type MATCHES "EXECUTABLE|LIBRARY")
    target_compile_options(
      ${target} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${project_warnings_cxx}>
                       $<$<COMPILE_LANGUAGE:C>:${project_warnings_c}>)
  else()
    loco_message("Target [${target}] doesn't match the pattern we expect"
                 LOG_LEVEL WARNING)
  endif()

endfunction()