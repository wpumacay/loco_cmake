# -------------------------------------
# Make sure we don't include this twice
include_guard()

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
  # cmake-lint: disable=R0915
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

  # -----------------------------------
  # Check if we haven't cached the values of a previous try_run
  if(LOCO_SIMD_HAS_CACHED_RESULTS)
    loco_message(
      "Getting cached SIMD feature [${simd_FEATURE}] from previous try_run")
    _loco_cache_get_simd_feature(simd_FEATURE simd_RESULT)
    return()
  endif()

  # -----------------------------------
  # If we don't have cached values, do the query using try_run to check for SIMD

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
        -DLOCO_CMAKE_SIMD_HAS_INTRIN_CPUID=${simd_has_intrin_cpuid}
        -DLOCO_CMAKE_SIMD_HAS_INTRIN_CPUIDEX=${simd_has_intrin_cpuidex}
        -DLOCO_CMAKE_SIMD_HAS_GET_CPUID=${simd_has_get_cpuid}
        -DLOCO_CMAKE_SIMD_HAS_GET_CPUID_COUNT=${simd_has_get_cpuid_count}
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

  # ----------------------------------------------------------------------------
  # Check the snippet output for available SIMD x86_64 features. We cache these
  # results for later runs, to avoid using N times try_run unncessarily

  string(FIND ${run_output} "CPU_SIMD_HAS_SSE=TRUE" simd_sse_idx)
  string(FIND ${run_output} "CPU_SIMD_HAS_SSE2=TRUE" simd_sse2_idx)
  string(FIND ${run_output} "CPU_SIMD_HAS_SSE3=TRUE" simd_sse3_idx)
  string(FIND ${run_output} "CPU_SIMD_HAS_SSSE3=TRUE" simd_ssse3_idx)
  string(FIND ${run_output} "CPU_SIMD_HAS_SSE4_1=TRUE" simd_sse4_1_idx)
  string(FIND ${run_output} "CPU_SIMD_HAS_SSE4_2=TRUE" simd_sse4_2_idx)
  string(FIND ${run_output} "CPU_SIMD_HAS_FMA=TRUE" simd_fma_idx)
  string(FIND ${run_output} "CPU_SIMD_HAS_AVX=TRUE" simd_avx_idx)
  string(FIND ${run_output} "CPU_SIMD_HAS_AVX2=TRUE" simd_avx2_idx)

  # cmake-format: off
  set(LOCO_SIMD_HAS_CACHED_RESULTS TRUE CACHE BOOL "Cached SIMD checks results")
  # cmake-format: on

  _loco_cache_set_simd_feature(SSE ${simd_sse_idx})
  _loco_cache_set_simd_feature(SSE2 ${simd_sse2_idx})
  _loco_cache_set_simd_feature(SSE3 ${simd_sse3_idx})
  _loco_cache_set_simd_feature(SSSE3 ${simd_ssse3_idx})
  _loco_cache_set_simd_feature(SSE4_1 ${simd_sse4_1_idx})
  _loco_cache_set_simd_feature(SSE4_2 ${simd_sse4_2_idx})
  _loco_cache_set_simd_feature(FMA ${simd_fma_idx})
  _loco_cache_set_simd_feature(AVX ${simd_avx_idx})
  _loco_cache_set_simd_feature(AVX2 ${simd_avx2_idx})
  # ----------------------------------------------------------------------------
endfunction()

# ~~~
# loco_try_set_simd_support(
#     [TARGET <target>]
#     [FEATURE <simd-feature>])
#
# Checks if the given `simd-feature` is supported in the current host; if so, it
# enables the appropriate compiler option (e.g. "-mavx") to the given `target`
# ~~~
function(loco_try_set_simd_support)
  set(options)
  set(one_value_args "TARGET" "FEATURE" "VERBOSE")
  set(multi_value_args)
  cmake_parse_arguments(try_simd "${options}" "${one_value_args}"
                        "${multi_value_args}" ${ARGN})

  # -----------------------------------
  # Do some sanity-checks for the expected keyword arguments
  if(NOT TARGET ${try_simd_TARGET})
    loco_message("Must give a target, but got [${try_simd_TARGET}] instead"
                 LOG_LEVEL WARNING)
    return()
  endif()

  if(NOT DEFINED try_simd_FEATURE)
    loco_message("Must give a SIMD feature to check for" LOG_LEVEL WARNING)
    return()
  endif()

  loco_validate_with_default(try_simd_VERBOSE FALSE)

  # -----------------------------------
  # Check if we have the given SIMD feature
  loco_check_simd_support(RESULT has_feature FEATURE ${try_simd_FEATURE}
                          VERBOSE ${try_simd_VERBOSE})
  if(NOT has_feature)
    loco_message("SIMD-feature [${FEATURE}] not supported :(" LOG_LEVEL STATUS)
    return()
  endif()

  # -----------------------------------
  # Add a preprocessor definition to the given target for that given feature
  # @note(wilbert): we're making sure that the target-definition is always
  # passed along, for which we handle transitivity as INTERFACE and PUBLIC
  # appropriately
  string(TOUPPER "${PROJECT_NAME}" proj_name_upper)
  string(TOUPPER "${try_simd_FEATURE}" simd_feature_upper)
  string(TOLOWER "${try_simd_FEATURE}" simd_feature_lower)
  get_target_property(target_type ${try_simd_TARGET} TYPE)
  if(target_type MATCHES "INTERFACE_LIBRARY")
    target_compile_definitions(
      ${try_simd_TARGET}
      INTERFACE -D${proj_name_upper}_${simd_feature_upper}_ENABLED)
  else()
    target_compile_definitions(
      ${try_simd_TARGET}
      PUBLIC -D${proj_name_upper}_${simd_feature_upper}_ENABLED)
  endif()

  # -----------------------------------
  # ~~~
  # Map the feature name to its correct flag name. There are some corner cases,
  # which are listed below (most are just from x86_64 SSE or AVX, we might add
  # support NEON on ARM later, if we get the hardware o.O')
  #
  # gcc|clang: {(SSE4_1,-msse4.1),(SSE2,-msse2),(AVX,-mavx),(AVX2,-mavx2),...}
  # msvc: {(SSE4_1,/arch:SSE4.1),(SSE2,/arch:SSE2),(AVX,/arch:AVX),...}
  #
  # @todo(wilbert): refactor to avoid multiple if-statements, maybe later (T_T')
  # ~~~
  if(MSVC)
    string(REPLACE "_" "." simd_feature_validated ${simd_feature_upper})
    if(target_type MATCHES "INTERFACE_LIBRARY")
      target_compile_options(${try_simd_TARGET}
                             INTERFACE /arch:${simd_feature_validated})
    else()
      target_compile_options(${try_simd_TARGET}
                             PUBLIC /arch:${simd_feature_validated})
    endif()
  else()
    string(REPLACE "_" "." simd_feature_validated ${simd_feature_lower})
    if(target_type MATCHES "INTERFACE_LIBRARY")
      target_compile_options(${try_simd_TARGET}
                             INTERFACE -m${simd_feature_validated})
    else()
      target_compile_options(${try_simd_TARGET}
                             PUBLIC -m${simd_feature_validated})
    endif()
  endif()

  if(try_simd_VERBOSE)
    loco_message("Successfully added SIMD feature [${try_simd_FEATURE}] to the
      given target [${try_simd_TARGET}] for project [${PROJECT_NAME}]")
  endif()
endfunction()

# ~~~
# _loco_cache_set_simd_feature(<param_feature> <param_result_idx>)
#
# Caches the given SIMD feature, checking the given value index from a previous
# string-find operation (checking for right output of try_run)
# ~~~
macro(_loco_cache_set_simd_feature param_feature param_result_idx)
  # -----------------------------------
  # Check if the CPU_SIMD_HAS_XYZ feature was found in the try_run output

  if(NOT ${param_result_idx} EQUAL -1)
    set(LOCO_SIMD_CACHE_HAS_${param_feature}
        TRUE
        CACHE BOOL "CPU supports SIMD-${param_feature}")
  else()
    set(LOCO_SIMD_CACHE_HAS_${param_feature}
        FALSE
        CACHE BOOL "CPU doesn't support SIMD-${param_feature}")
  endif()
endmacro()

# ~~~
# _loco_cache_get_simd_feature(<param_feature> <param_output_var>)
#
# Gets the stored cached value of the requested SIMD feature, and stores it in
# the output variable given as second parameter
# ~~~
macro(_loco_cache_get_simd_feature param_feature param_output_var)
  # cmake-lint: disable=C0103
  # -----------------------------------
  # Make sure we have cached the result requested. If not, set just FALSE
  if(NOT DEFINED LOCO_SIMD_CACHE_HAS_${${param_feature}})
    loco_message(
      "SIMD feature ${${param_feature}} is not cached. Setting FALSE")
    set(${param_output_var}
        FALSE
        PARENT_SCOPE)
    return()
  endif()

  # -----------------------------------
  # Set the value of the output variable with the cached value
  set(${${param_output_var}}
      ${LOCO_SIMD_CACHE_HAS_${${param_feature}}}
      PARENT_SCOPE)
endmacro()
