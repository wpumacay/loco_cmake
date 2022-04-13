@echo off
setlocal enabledelayedexpansion
:: List of paths to the examples we have so far
set ex_folder=%~dp0..\examples
set ex_paths=project simd target utils
:: Run each example|test
for %%x in (%ex_paths%) do (
    set ex_source_folder=%ex_folder%\%%x
    set ex_build_folder=%ex_folder%\%%x\build
    echo source-folder: !ex_source_folder!
    echo build-folder: !ex_build_folder!
    cmake -S !ex_source_folder! -B !ex_build_folder! -DCMAKE_BUILD_TYPE=%1
)
