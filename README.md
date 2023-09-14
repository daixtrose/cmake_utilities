# CMake Utilities - Dependency Management Done Right

## TL;DR

CMake Utilities is a collection of utilities which help escaping the dependency hell and to make dependency management as slick and easy as possible. 

It extends CMake's [`FetchContent`](https://cmake.org/cmake/help/latest/module/FetchContent.html) feature such that all dependency information is collected in a separate file in the top-level of the repository, thereby avoiding repetitive code in the CMake files and enabling efficient configuration management.

In addition, these utilities provide support for developers to apply code changes distributed across dependencies and the dependent code base. When configured accordingly, these utilities will put dependencies (and dependencies of dependencies) outside the standard `${CMAKE_BINARY_DIR}/_deps` structure to a user-defined place in the filesystem. The dependency hierarchy tree gets unfolded into a flat structure.  Debugging information will be adapted accordingly. It is possible to have mutiple build directories point to the very same codebase.

Although this project was designed to meet the needs of C++ developers, extra effort went into not having any dependency beyond CMake itself, so this project can be used in other context, e.g. as a drop-in replacement for [`svn externals`](https://svnbook.red-bean.com/en/1.7/svn.advanced.externals.html) in a git project.      

## Quick Start

- Impatient readers can look at [the examples](https://github.com/dep-heaven). 
  - [`tool_1`](https://github.com/dep-heaven/tool_1) depends on [`lib_A`](https://github.com/dep-heaven/lib_A), [`lib_B`](https://github.com/dep-heaven/lib_B), and [`libFreeAssange`](https://github.com/dep-heaven/libFreeAssange)
  - [`tool_2`](https://github.com/dep-heaven/tool_2) depends on [`lib_A`](https://github.com/dep-heaven/lib_A), [`lib_B`](https://github.com/dep-heaven/lib_B), and [`libFreeAssange`](https://github.com/dep-heaven/libFreeAssange)
  - [`lib_A`](https://github.com/dep-heaven/lib_A) depends on [`libFreeAssange`](https://github.com/dep-heaven/libFreeAssange)
  - [`lib_B`](https://github.com/dep-heaven/lib_B) depends on [`libFreeAssange`](https://github.com/dep-heaven/libFreeAssange)
- Try it out and watch it live, e.g.:
  ```bash
  git clone https://github.com/dep-heaven/tool_1
  cd tool_1/
  mkdir build
  cd build/
  cmake ..
  ```
- People who want to understand the motivation and history of this project and how it solves all problems that come with [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules), please check out [this talk](https://www.daixtrose.de/talk/saying-goodbye-to-dependency-hell/).

## A Quick First Example

Imagine you are creating a C/C++ codebase called [`tool_1`](https://github.com/dep-heaven/tool_1) that depends on several other libraries, specifically [`lib_A`](https://github.com/dep-heaven/lib_A) and [`lib_B`](https://github.com/dep-heaven/lib_B). Both of those dependencies furthermore depend on [`libFreeAssange`](https://github.com/dep-heaven/libFreeAssange). 

In addition to this, the project makes use of the `v2.x` branch of [`catch2`](https://github.com/catchorg/Catch2) for testing and for no good reason will rely on code found in the `master` branch of the [`fmt`](https://github.com/fmtlib/fmt) library.

Assume the following widely-used directory structure for C++ projects containing header files in `include/tool_1`, source code files in `src`, and test code in `test-catch`:    

```
tool_1
├── CMakeLists.txt
├── dependencies.txt
├── include
│   └── tool_1
│       └── fn.hpp
├── src
│   ├── fn.cpp
│   └── tool_1.cpp
└── test-catch
    ├── CMakeLists.txt
    ├── test_main.cpp
    └── test_tool_1.cpp
```

The minimal content of the top-level `CMakeLists.txt` then reads as 

```cmake
cmake_minimum_required(VERSION 3.16)
project(tool_1 VERSION 1.0.0 LANGUAGES CXX)

include(FetchContent)

FetchContent_Declare(
    cmake_utilities
    GIT_REPOSITORY https://github.com/daixtrose/cmake_utilities
    GIT_TAG main
)

# Use a custom file name for dependency files
set(REPOMAN_DEPENDENCIES_FILE_NAME "dependencies.txt" CACHE STRING "")

FetchContent_MakeAvailable(cmake_utilities)

add_executable(${PROJECT_NAME}
    src/fn.cpp
    src/tool_1.cpp)

target_include_directories(
    ${PROJECT_NAME} PUBLIC
    include
)

target_link_libraries(
    ${PROJECT_NAME}
    PUBLIC
    lib_A
    lib_B
    fmt::fmt
)    
```

The dependencies to the project are defined in a separate file called `dependencies.txt`. Note, that the filename can be freely chosen by setting the variable `REPOMAN_DEPENDENCIES_FILE_NAME` accordingly before calling `FetchContent_MakeAvailable(cmake_utilities)`, e.g.: 

```cmake
set(REPOMAN_DEPENDENCIES_FILE_NAME "dependencies.txt" CACHE STRING "") 
```

The content of the file `dependencies.txt` is as follows:


```cmake
Version: v1.0.0 # indicates the version of the dependencies file format
lib_A GIT_REPOSITORY https://github.com/dep-heaven/lib_A GIT_TAG master-yoda
lib_B GIT_REPOSITORY https://github.com/dep-heaven/lib_B GIT_TAG master-yoda

# include dependencies of dependencies, thereby overwriting branch settings 
libFreeAssange GIT_REPOSITORY https://github.com/dep-heaven/libFreeAssange GIT_TAG belmarsh

# External dependencies
catch2 GIT_REPOSITORY https://github.com/catchorg/Catch2 GIT_TAG v2.x
fmt GIT_REPOSITORY https://github.com/fmtlib/fmt GIT_TAG master
```

This file is read and parsed by the utilities. The first line of the file always must contain the file format version information. As of today this is `Version: v1.0.0`. This makes the information stored in this file robust against future changes of the utilities.     

Comments must be prepended with a `#` symbol. Empty lines are ignored. Please ensure that there is [a newline at the end of file to avoid surprises](https://unix.stackexchange.com/questions/18743/whats-the-point-in-adding-a-new-line-to-the-end-of-a-file).

All other non-empty lines are passed without modification to CMake's [`FetchContent`](https://cmake.org/cmake/help/latest/module/FetchContent.html) in such a way that it is possible to overwrite the dependency selection of dependencies. For C++ projects this is important for not violating the [One Definition Rule](https://en.cppreference.com/w/cpp/language/definition#One_Definition_Rule). 

In the example shown here, [`lib_A`](https://github.com/dep-heaven/lib_A) may depend on a different branch, version, or tag of [`libFreeAssange`](https://github.com/dep-heaven/libFreeAssange) than [`lib_B`](https://github.com/dep-heaven/lib_B). This may lead to ODR-violations. Therefore it is possible to add a deviating version of this dependency to the list of dependencies in the top layer `dependencies.txt`:

```cmake
libFreeAssange GIT_REPOSITORY https://github.com/dep-heaven/libFreeAssange GIT_TAG belmarsh
```

The utilities will ensure that these settings are propagated through the whole tree before the dependencies itself are populated. This means all other dependencies will get their own settings regarding this specific dependency overwritten.
Hence, a specific oder of dependencies in `dependencies.txt` is not required to be maintained.      

