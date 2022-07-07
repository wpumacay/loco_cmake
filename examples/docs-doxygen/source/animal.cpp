
#include <algorithm>
#include <animal.hpp>
#include <iostream>

namespace zoo {

auto Animal::recover(int value) -> void {
    m_Health += value;
    m_Health = std::min(m_Health, BASE_HEALTH);
}

auto Animal::greet(const std::string& message) const -> void {
    std::cout << "Hey there, I'm " << m_Name << std::endl;
    _greet_internal(message);
}

auto operator<<(std::ostream& out_stream, const Animal& animal)
    -> std::ostream& {
    out_stream << "Animal(name=" << animal.name()
               << ", health=" << animal.health() << ", age=" << animal.age()
               << ")" << '\n';
    return out_stream;
}

}  // namespace zoo
