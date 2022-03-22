cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

# -------------------------------------
# Add the root folder (in a normal project the path wouldn't be this weird)
include("../../CMakeLists.txt")

# -------------------------------------
# Define the project
project(ExampleProject VERSION 1.0.0)

# -------------------------------------
# Initialize the project (bare-minimum setup)
loco_initialize_project()

# -------------------------------------
# Show some info of the this project
loco_print_project_info()
