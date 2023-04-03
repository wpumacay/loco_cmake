#!/usr/bin/env bash

# Make sure we're given the build-type argument by the user
build_type="Debug"
if [[ $# < 1 || $# > 2 ]]; then
    echo "Usage ./run_examples.sh [mode=build,clean] [config=Debug,Release,RelWithDebInfo,MinSizeRel]"
    exit 1
fi

curr_mode=$1
mode_types=("build" "clean")
mode_valid=false
for valid_mode_type in ${mode_types[@]}; do
    if [[ ${curr_mode} -eq ${valid_mode_type} ]]; then
        mode_valid=true
    fi
done
if [[ ${mode_valid} != true ]]; then
    echo "Valid mode options: [mode=build,clean]"
    exit 1
fi

curr_build_type=$2
build_types=("Debug" "Release" "RelWithDebInfo" "MinSizeRel")
build_valid=false
for valid_build_type in ${build_types[@]}; do
    if [[ curr_build_type -eq ${valid_build_type} ]]; then
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
ex_names=("project" "simd" "target" "utils" "docs-doxygen" "docs-sphinx")

build_all_examples() {
    for example_name in ${ex_names[@]}; do
        # Define some paths we'll use later
        source_folder="${examples_dir}/${example_name}"
        build_folder="${examples_dir}/${example_name}/build"
        # Run the configuration|generation step
        echo "source-folder: ${source_folder}"
        echo "build-folder: ${build_folder}"
        cmake -S ${source_folder} -B ${build_folder} -DCMAKE_BUILD_TYPE=${curr_build_type} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
        # Make sure we copy the generated compile_commands.json (if it exists)
        if [ -f "${build_folder}/compile_commands.json" ]; then
            cp ${build_folder}/compile_commands.json ${source_folder}/compile_commands.json
        fi
        # Build our example using the generated configuration
        cmake --build ${build_folder} --config ${curr_build_type}
    done
}

clean_all_examples() {
    for example_name in ${ex_names[@]}; do
        build_folder="${examples_dir}/${example_name}/build"
        if [ -d ${build_folder} ]; then
            echo "Removing build-folder @ ${build_folder}"
            rm -rf ${build_folder}
        fi
    done
}

if [[ ${curr_mode} == "build" ]]; then
    build_all_examples
elif [[ ${curr_mode} == "clean" ]]; then
    clean_all_examples
fi
