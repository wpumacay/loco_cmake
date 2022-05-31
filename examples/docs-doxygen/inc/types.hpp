#pragma once

#include <array>
#include <cstddef>
#include <initializer_list>
#include <string>
#include <vector>

/// Floating point number precision to be used along the library
using ScalarType = float;

namespace geom {
namespace types {

/// \class Vector
///
/// \brief Data type used to represent a vector
///
/// \tparam T Type of scalar value used for this vector (float, double, ...)
/// \tparam N Number of dimensions of this vector
///
template <typename T, size_t N>
struct Vector {
    Vector() = default;

    // cppcheck-suppress noExplicitConstructor
    /// \brief Creates a vector from a list of values the form `{1, 2, ...}`
    ///
    /// \param values List of initial values of the vector
    ///
    /// \code
    ///     // Creates some vectors from some lists of initial values
    ///     Vector<float, 2> v2 = {1.0f, 1.0f};
    ///     Vector<double, 3> v3 = {1.0, 2.0, 3.0};
    ///     Vector<double, 4> q = {0.0, 0.0, 0.0, 1.0};
    /// \encode
    Vector(const std::initializer_list<T>& values);

    /// \brief Returns a mutable reference to the requested entry
    ///
    /// \param index Index of the requested entry
    /// \return Mutable reference to the requested entry
    auto operator[](size_t index) -> T& { return m_Data[index]; }

    /// \brief Returns an unmutable reference to the requested entry
    ///
    /// \param index Index of the requested entry
    /// \return Unmutable reference to the requested entry
    auto operator[](size_t index) const -> const T& { return m_Data[index]; }

    /// \brief Returns a pointer to the internal storage of the vector
    auto ptr() -> T* { return m_Data.data(); }

    /// \brief Returns a const-pointer to the internal storage of the vector
    auto ptr() const -> const T* { return m_Data.data(); }

    /// \brief Returns a printable string representation of the vector
    auto toString() const -> std::string;

 protected:
    /// Internal storage for the vector's data
    std::array<T, N> m_Data;  // NOLINT
};

/// \brief Data type representing a vector in 2d-space
struct Vector2 : public Vector<ScalarType, 2> {
    using Base = Vector<ScalarType, 2>;

    Vector2();

    /// \brief Creates a 2d-vector given its two entries
    explicit Vector2(const ScalarType& x, const ScalarType& y);

    /// \brief Returns a mutable reference to the x-component of the vector
    auto x() -> ScalarType& { return m_Data[0]; }

    /// \brief Returns an unmutable reference to the x-component of the vector
    auto x() const -> const ScalarType& { return m_Data[0]; }

    /// \brief Returns a mutable reference to the y-component of the vector
    auto y() -> ScalarType& { return m_Data[1]; }

    /// \brief Returns an unmutable reference to the y-component of the vector
    auto y() const -> const ScalarType& { return m_Data[1]; }
};

/// \brief Data type representing a vector in 3d-space
struct Vector3 : public Vector<ScalarType, 3> {
    using Base = Vector<ScalarType, 3>;

    Vector3();

    /// \brief Creates a 3d-vector given its three entries
    explicit Vector3(const ScalarType& x, const ScalarType& y,
                     const ScalarType& z);

    /// \brief Returns a mutable reference to the x-component of the vector
    auto x() -> ScalarType& { return m_Data[0]; }

    /// \brief Returns an unmutable reference to the x-component of the vector
    auto x() const -> const ScalarType& { return m_Data[0]; }

    /// \brief Returns a mutable reference to the y-component of the vector
    auto y() -> ScalarType& { return m_Data[1]; }

    /// \brief Returns an unmutable reference to the y-component of the vector
    auto y() const -> const ScalarType& { return m_Data[1]; }

    /// \brief Returns a mutable reference to the z-component of the vector
    auto z() -> ScalarType& { return m_Data[2]; }

    /// \brief Returns an unmutable reference to the z-component of the vector
    auto z() const -> const ScalarType& { return m_Data[2]; }
};

}  // namespace types
}  // namespace geom
