#pragma once

#include <iostream>
#include <string>
#include <utility>

namespace zoo {

/// Base number of health assigned to each generic animal
static constexpr int BASE_HEALTH = 100;

class Animal {
 public:
    /// Creates an animal with given parameters
    /// \param[in] name Name of the animal
    /// \param[in] health Health points of the animal (from 1 to 100)
    /// \param[in] age Age of the animal (in years)
    Animal(std::string&& name, int health, int age)
        : m_Name(std::move(name)), m_Health(health), m_Age(age) {}

    /// Constructs an animal by copy
    Animal(const Animal& rhs) = default;

    /// Constructs an animal by move
    Animal(Animal&& rhs) = default;

    /// Copy-assignment operator
    auto operator=(const Animal& rhs) -> Animal& = default;

    /// Move-assignment operator
    auto operator=(Animal&& rhs) -> Animal& = default;

    /// Cleans up instance for disposal
    virtual ~Animal() = default;

    /// Recovers the given amount of health
    /// \param[in] value The amount of health points to be recovered
    auto recover(int value) -> void;

    /// Greets the user with a given message
    /// \param[in] message A message used as part of the greeting
    auto greet(const std::string& message) const -> void;

    /// Returns the name of the animal
    auto name() const -> std::string { return m_Name; }

    /// Returns the health of the animal
    auto health() const -> int { return m_Health; }

    /// Returns the age of the animal
    auto age() const -> int { return m_Age; }

 protected:
    /// Class-specific greeting method
    virtual auto _greet_internal(const std::string& message) const -> void = 0;

 protected:
    /// Name of the animal
    std::string m_Name;  // NOLINT
    /// Number of health points
    int m_Health = BASE_HEALTH;  // NOLINT
    /// Age of the animal (in years)
    int m_Age = 0;  // NOLINT
};

/// Sends a string representation of the given animal to the given stream
/// \param[in,out] out_stream The output stream to write to
/// \param[in] animal The animal whose information we want printed to the stream
auto operator<<(std::ostream& out_stream, const Animal& animal)
    -> std::ostream&;
}  // namespace zoo
