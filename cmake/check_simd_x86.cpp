#include <array>
#include <iostream>
#include <string>

using uint = unsigned int;
// Make sure we're not in any funky architecture
static_assert(sizeof(uint) == 4, "");

struct CPUIDregs {
    uint eax{};
    uint ebx{};
    uint ecx{};
    uint edx{};
};

#if LOCO_CMAKE_SIMD_HAS_GET_CPUID == 1
#include <cpuid.h>
#elif LOCO_CMAKE_SIMD_HAS_INTRIN_CPUID == 1
#include <intrin.h>
#endif

auto cpuid(uint *info, uint option_eax) -> void {
#if LOCO_CMAKE_SIMD_HAS_GET_CPUID == 1
    __get_cpuid(option_eax, info, info + 1, info + 2, info + 3);
#elif LOCO_CMAKE_SIMD_HAS_INTRIN_CPUID == 1
    __cpuid(reinterpret_cast<int *>(info), static_cast<int>(option_eax));
#endif
}

auto cpuidex(uint *info, uint option_eax, uint option_ecx) -> void {
#if LOCO_CMAKE_SIMD_HAS_GET_CPUID == 1
    __get_cpuid_count(option_eax, option_ecx, info, info + 1, info + 2,
                      info + 3);
#elif LOCO_CMAKE_SIMD_HAS_INTRIN_CPUID == 1
    __cpuidex(reinterpret_cast<int *>(info), static_cast<int>(option_eax),
              static_cast<int>(option_ecx));
#endif
}

constexpr uint BIT_SSE = (1 << 25);     // Capability found in edx (eax=1)
constexpr uint BIT_SSE2 = (1 << 26);    // Capability found in edx (eax=1)
constexpr uint BIT_SSE3 = (1 << 0);     // Capability found in ecx (eax=1)
constexpr uint BIT_SSSE3 = (1 << 9);    // Capability found in ecx (eax=1)
constexpr uint BIT_SSE4_1 = (1 << 19);  // Capability found in ecx (eax=1)
constexpr uint BIT_SSE4_2 = (1 << 20);  // Capability found in ecx (eax=1)
constexpr uint BIT_FMA = (1 << 10);     // Capability found in ecx (eax=1)
constexpr uint BIT_AVX = (1 << 28);     // Capability found in ecx (eax=1)
constexpr uint BIT_AVX2 = (1 << 5);     // Capability found in ebx (eax=7,ecx=0)

constexpr uint RETVAL_BIT_SSE = 0;
constexpr uint RETVAL_BIT_SSE2 = 1;
constexpr uint RETVAL_BIT_SSE3 = 2;
constexpr uint RETVAL_BIT_SSSE3 = 3;
constexpr uint RETVAL_BIT_SSE4_1 = 4;
constexpr uint RETVAL_BIT_SSE4_2 = 5;
constexpr uint RETVAL_BIT_FMA = 6;
constexpr uint RETVAL_BIT_AVX = 7;
constexpr uint RETVAL_BIT_AVX2 = 8;

template <typename T>
auto report_feature(const std::string &feature_name, T feature_value) -> void {
    std::cout << feature_name << "=" << feature_value << '\n';
}

auto main() -> int {
    CPUIDregs regs;
    int simd_info_bits{0x00000000};

    // Get CPU vendor information ----------------------------------------------
    cpuid(reinterpret_cast<uint *>(&regs), 0);  // NOLINT
    // Assemble data to get vendor string
    std::array<uint, 3> vendor_regs = {regs.ebx, regs.edx, regs.ecx};
    // NOLINTNEXTLINE
    std::string vendor_str(reinterpret_cast<const char *>(vendor_regs.data()),
                           sizeof(uint) * 3);
    // std::cout << "Vendor information: " << vendor_str << '\n';
    //  ------------------------------------------------------------------------

    // Get CPU capabilities ----------------------------------------------------
    cpuid(reinterpret_cast<uint *>(&regs), 1);  // NOLINT
    const bool HAS_SSE = (regs.edx & BIT_SSE) != 0;
    const bool HAS_SSE2 = (regs.edx & BIT_SSE2) != 0;
    const bool HAS_SSE3 = (regs.ecx & BIT_SSE3) != 0;
    const bool HAS_SSSE3 = (regs.ecx & BIT_SSSE3) != 0;
    const bool HAS_SSE4_1 = (regs.ecx & BIT_SSE4_1) != 0;
    const bool HAS_SSE4_2 = (regs.ecx & BIT_SSE4_2) != 0;
    const bool HAS_FMA = (regs.ecx & BIT_FMA) != 0;
    const bool HAS_AVX = (regs.ecx & BIT_AVX) != 0;
    cpuidex(reinterpret_cast<uint *>(&regs), 7, 0);  // NOLINT
    const bool HAS_AVX2 = (regs.ebx & BIT_AVX2) != 0;
    // -------------------------------------------------------------------------

    // Assemble the simd capabilities into bitfields for each feature ----------
    simd_info_bits |= (HAS_SSE ? 1 : 0) << RETVAL_BIT_SSE;
    simd_info_bits |= (HAS_SSE2 ? 1 : 0) << RETVAL_BIT_SSE2;
    simd_info_bits |= (HAS_SSE3 ? 1 : 0) << RETVAL_BIT_SSE3;
    simd_info_bits |= (HAS_SSSE3 ? 1 : 0) << RETVAL_BIT_SSSE3;
    simd_info_bits |= (HAS_SSE4_1 ? 1 : 0) << RETVAL_BIT_SSE4_1;
    simd_info_bits |= (HAS_SSE4_2 ? 1 : 0) << RETVAL_BIT_SSE4_2;
    simd_info_bits |= (HAS_FMA ? 1 : 0) << RETVAL_BIT_FMA;
    simd_info_bits |= (HAS_AVX ? 1 : 0) << RETVAL_BIT_AVX;
    simd_info_bits |= (HAS_AVX2 ? 1 : 0) << RETVAL_BIT_AVX2;
    // std::cout << "retval: " << simd_info_bits << '\n';
    //  ------------------------------------------------------------------------

    // Send to sdtout the cpuinfo as a csv like file ---------------------------
    report_feature("VENDOR_NAME", vendor_str);
    report_feature("VENDOR_MODEL", "Intel Core i0");
    report_feature("CPU_SIMD_HAS_SSE", HAS_SSE ? "TRUE" : "FALSE");
    report_feature("CPU_SIMD_HAS_SSE2", HAS_SSE2 ? "TRUE" : "FALSE");
    report_feature("CPU_SIMD_HAS_SSE3", HAS_SSE3 ? "TRUE" : "FALSE");
    report_feature("CPU_SIMD_HAS_SSSE3", HAS_SSSE3 ? "TRUE" : "FALSE");
    report_feature("CPU_SIMD_HAS_SSE4_1", HAS_SSE4_1 ? "TRUE" : "FALSE");
    report_feature("CPU_SIMD_HAS_SSE4_2", HAS_SSE4_2 ? "TRUE" : "FALSE");
    report_feature("CPU_SIMD_HAS_FMA", HAS_FMA ? "TRUE" : "FALSE");
    report_feature("CPU_SIMD_HAS_AVX", HAS_AVX ? "TRUE" : "FALSE");
    report_feature("CPU_SIMD_HAS_AVX2", HAS_AVX2 ? "TRUE" : "FALSE");
    report_feature("CPU_SIMD_FEATURES_BITS", simd_info_bits);
    //  ------------------------------------------------------------------------
    return 0;
}
