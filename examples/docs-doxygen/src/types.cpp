#include "../inc/types.hpp"

namespace geom {
namespace types {

Vector2::Vector2() : Vector2::Base() {
    m_Data[0] = static_cast<ScalarType>(0.0);
    m_Data[1] = static_cast<ScalarType>(0.0);
}

Vector2::Vector2(const ScalarType& x, const ScalarType& y) : Vector2::Base() {
    m_Data[0] = x;
    m_Data[1] = y;
}

Vector3::Vector3() : Vector3::Base() {
    m_Data[0] = static_cast<ScalarType>(0.0);
    m_Data[1] = static_cast<ScalarType>(0.0);
}

Vector3::Vector3(const ScalarType& x, const ScalarType& y, const ScalarType& z)
    : Vector3::Base() {
    m_Data[0] = x;
    m_Data[1] = y;
}

}  // namespace types
}  // namespace geom
