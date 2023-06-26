#!/usr/bin/env -S cmake -P

#[[
This script can be used to resolve dependencies without a top-level CMake project.

It can be called either via ``RepoManResolve.cmake`` or more traditionally via ``cmake -P RepoManResolve.cmake``.

.. note::
  The working/project directory is always the current directory. Only call this script while in your project root directory.
#]]

cmake_path(GET CMAKE_SCRIPT_MODE_FILE PARENT_PATH SCRIPT_PATH)
include(${SCRIPT_PATH}/RepoMan.cmake)
