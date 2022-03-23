cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

# -------------------------------------
# Include all features by including the main entrypoint
include("../../Index.cmake")

# -------------------------------------
# Define the project
project(ExampleProject VERSION 1.0.0)

# -------------------------------------
# Initialize the project (bare-minimum setup)
loco_initialize_project()

# -------------------------------------
# Show some info of the this project
loco_print_project_info()
