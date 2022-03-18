# ~~~
# loco_check_simd_support(
#       [RESULT <result_var>]
#       [FEATURE <query_feature>]
#       [VERBOSE <verbose>])
#
# Checks if the current host has support for SIMD, as requested by the
# `query_feature`. The result (either TRUE or FALSE) is stored in `result_var`.
#
# Valid FEATURE values are listed below:
#
#   * Streaming SIMD Extensions (SSE): SSE, SSE2, SSE3, SSSE3, SSE4_1, SSE4_2
#   * Advanced Vector eXtensions (AVX): AVX, AVX2
# ~~~
function(loco_check_simd_support)
  set(options)
  set(one_value_args RESULT FEATURE VERBOSE)
  set(multi_value_args)
  cmake_parse_arguments(simd "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # -----------------------------------
  # Make sure the user gives us the RESULT parameter (throw otherwise)
  if(NOT DEFINED simd_RESULT)
    loco_message("RESULT variable is a required parameter for this function"
                 LOG_LEVEL FATAL_ERROR)
  endif()

  # -----------------------------------
  # Make sure the user gives us the FEATURE parameter (throw otherwise)
  if(NOT DEFINED simd_FEATURE)
    loco_message("Must request a feature to this function, but none given"
                 LOG_LEVEL FATAL_ERROR)
  endif()

  include(CheckCXXSourceCompiles)
  include(CheckCXXSymbolExists)

  # -----------------------------------
  # Check if __cpuid and __cpuidex are available (on WINDOWS)
  check_cxx_source_compiles(
    "
    #include <intrin.h>
    auto main() -> int { __cpuid(NULL, 0); return 0; }
    "
    simd_has_intrin_cpuid)
  check_cxx_source_compiles(
    "
    #include <intrin.h>
    auto main() -> int { __cpuidex(NULL, 0, 0); return 0; }
    "
    simd_has_intrin_cpuidex)

  # -----------------------------------
  # Check if __get_cpuid and __get_cpuid_count are available (on UNIX)
  check_cxx_symbol_exists(__get_cpuid cpuid.h simd_has_get_cpuid)
  check_cxx_symbol_exists(__get_cpuid_count cpuid.h simd_has_get_cpuid_count)

  # -----------------------------------
  # Make sure that we at least place an integer value for these definitions
  if(NOT simd_has_intrin_cpuid)
    set(simd_has_intrin_cpuid 0)
  endif()
  if(NOT simd_has_intrin_cpuidex)
    set(simd_has_intrin_cpuidex 0)
  endif()
  if(NOT simd_has_get_cpuid)
    set(simd_has_get_cpuid 0)
  endif()
  if(NOT simd_has_get_cpuid_count)
    set(simd_has_get_cpuid_count 0)
  endif()

  # cmake-format: off
  # -----------------------------------
  # Run the x86_64 simd checker snippet (@todo(wilbert): support ARM) The
  # snippet will print to stdout the features supported by the host processor;
  # we then grab this output for later processing
  try_run(
    # Variable where the result of running the program is stored (exit-code)
    run_result
    # Variable where the result of compiling the program is stored (TRUE|FALSE)
    compile_result
    # Where to place the executable generated after linking
    ${CMAKE_CURRENT_BINARY_DIR}
    # File path of the source file to be compiled and run
    ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/check_simd_x86.cpp
    # Send the definitions on what header file to use for 'cpuid' usage
    COMPILE_DEFINITIONS
        -DTINYMATH_SIMD_HAS_INTRIN_CPUID=${simd_has_intrin_cpuid}
        -DTINYMATH_SIMD_HAS_INTRIN_CPUIDEX=${simd_has_intrin_cpuidex}
        -DTINYMATH_SIMD_HAS_GET_CPUID=${simd_has_get_cpuid}
        -DTINYMATH_SIMD_HAS_GET_CPUID_COUNT=${simd_has_get_cpuid_count}
    # Variable where the messages generated during compilation is stored
    COMPILE_OUTPUT_VARIABLE compile_output
    # Variable where the output of running the program is stored (stdout?)
    RUN_OUTPUT_VARIABLE run_output)
  # cmake-format: on

  if(simd_VERBOSE)
    loco_message("check-simd-x86 - compilation result:\n${compile_result}")
    loco_message("check-simd-x86 - compilation output:\n${compile_output}")
    loco_message("check-simd-x86 - running result:\n${run_result}")
    loco_message("check-simd-x86 - running output:\n${run_output}")
  endif()

  # -----------------------------------
  # Find if the snippet's output contains the requested feature
  string(FIND ${run_output} "CPU_SIMD_HAS_${simd_FEATURE}=TRUE" has_feature)

  # -----------------------------------
  # Store the result into the given RESULT output variable
  if(${has_feature} EQUAL -1)
    set(${simd_RESULT}
        FALSE
        PARENT_SCOPE)
  else()
    set(${simd_RESULT}
        TRUE
        PARENT_SCOPE)
  endif()

endfunction()
