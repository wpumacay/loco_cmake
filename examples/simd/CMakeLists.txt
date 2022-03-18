cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

project(ExampleSIMD VERSION 1.0.0)

# -------------------------------------
# Add the root folder (in a normal project the path wouldn't be this weird)
include("../../CMakeLists.txt")

# -------------------------------------
# Check for SIMD support (both SSE and AVX on x86_64)
loco_check_simd_support(RESULT has_sse FEATURE SSE)
loco_check_simd_support(RESULT has_sse2 FEATURE SSE2)
loco_check_simd_support(RESULT has_sse3 FEATURE SSE3)
loco_check_simd_support(RESULT has_ssse3 FEATURE SSSE3)
loco_check_simd_support(RESULT has_sse4_1 FEATURE SSE4_1)
loco_check_simd_support(RESULT has_sse4_2 FEATURE SSE4_2)
loco_check_simd_support(RESULT has_avx FEATURE AVX)
loco_check_simd_support(RESULT has_avx2 FEATURE AVX2)

loco_message("has_sse       : ${has_sse}")
loco_message("has_sse2      : ${has_sse2}")
loco_message("has_sse3      : ${has_sse3}")
loco_message("has_ssse3     : ${has_ssse3}")
loco_message("has_sse4_1    : ${has_sse4_1}")
loco_message("has_sse4_2    : ${has_sse4_2}")
loco_message("has_avx       : ${has_avx}")
loco_message("has_avx2      : ${has_avx2}")
