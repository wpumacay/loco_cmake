#pragma once

#include <algorithm>
#include <cassert>
#include <sstream>
#include <string>
#include <type_traits>

#include "../inc/types.hpp"

namespace geom {
namespace types {

template <typename T, size_t N>
Vector<T, N>::Vector(const std::initializer_list<T>& values) {
    assert(N == values.size());
    std::copy(values.begin(), values.end(), m_Data.data());
}

template <typename T, size_t N>
auto Vector<T, N>::toString() const -> std::string {
    std::stringstream str_result;

    if (std::is_same<T, float>()) {
        str_result << "Vector2f(";
    } else if (std::is_same<T, double>()) {
        str_result << "Vector2d(";
    } else {
        str_result << "Vector2(";
    }
    for (size_t i = 0; i < (N - 1); i++) {
        str_result << m_Data[i] << ", ";
    }
    str_result << m_Data[N - 1] << ")";

    return str_result.str();
}

}  // namespace types
}  // namespace geom
