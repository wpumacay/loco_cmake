#!/usr/bin/env bash

# Make sure we're given the build-type argument by the user
build_type="Debug"
if [[ $# != 1 ]]; then
    echo "Usage ./run_examples.sh [config=Debug,Release,RelWithDebInfo,MinSizeRel]"
    exit 1
fi

build_types=("Debug" "Release" "RelWithDebInfo" "MinSizeRel")
build_valid=false
for valid_build_type in ${build_types[@]}; do
    if [[ $1 -eq ${valid_build_type} ]]; then
        build_valid=true
    fi
done
if [[ ${build_valid} != true ]]; then
    echo "Valid build options: [config=Debug,Release,RelWithDebInfo,MinSizeRel]"
    exit 1
fi

# List of paths to the examples we have so far
script_path="$(readlink -f ${BASH_SOURCE})"
scripts_dir="$(dirname -- ${script_path})"
root_dir="$(dirname -- ${scripts_dir})"
examples_dir="${root_dir}/examples"
ex_names=("project" "simd" "target" "utils")

# Run each example|test
for example_name in ${ex_names[@]}; do
    source_folder="${examples_dir}/${example_name}"
    build_folder="${examples_dir}/${example_name}/build"

    echo "source-folder: ${source_folder}"
    echo "build-folder: ${build_folder}"
    cmake -S ${source_folder} -B ${build_folder} -DCMAKE_BUILD_TYPE=$1
    cmake --build ${build_folder} --config $1
done
