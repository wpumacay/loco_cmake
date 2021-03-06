# Look for the executable 'sphinx-build', which should be in your system's path
find_program(
  SPHINX_EXECUTABLE
  NAMES sphinx-build
  DOC "Path to the sphinx-build executable")

# Handle standard arguments to find_package like REQUIRED and QUIET
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  Sphinx "Failed to find sphinx-build executable" SPHINX_EXECUTABLE)
