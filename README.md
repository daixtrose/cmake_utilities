# CMake Utilities - Dependency Management Done Right

## TL;DR

CMake Utilities is a collection of utilities which help escaping the dependency hell and to make dependency management as slick and easy as possible. 

It extends CMake's [`FetchContent`](https://cmake.org/cmake/help/latest/module/FetchContent.html) feature such that all dependency information is collected in a separate file in the top-level of the repository, thereby avoiding repetitive code in the CMake files and enabling efficient configuration management.

In addition, these utilities provide support for developers to apply code changes distributed across dependencies and the dependent code base. When configured accordingly, these utilities will put dependencies (and dependencies of dependencies) outside the standard [`${CMAKE_BINARY_DIR}`](https://cmake.org/cmake/help/latest/variable/CMAKE_BINARY_DIR.html#cmake-binary-dir)`/_deps` structure to a user-defined place in the filesystem. The dependency hierarchy tree gets unfolded into a flat structure.  Debugging information will be adapted accordingly. It is possible to have mutiple build directories point to the very same codebase.

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

# Only build an run tests if this project is compiled as top-level project
if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
    enable_testing()
    add_subdirectory(test-catch)
endif()
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

The file `test-catch/CMakeLists.txt` which is conditionally included by the top-level `CMakeLists.txt` can now rely on the dependency to [`catch2`](https://github.com/catchorg/Catch2) already being populated and hence reads as follows: 

```cmake
cmake_minimum_required(VERSION 3.16)

include(CTest)

# Prepare use of extra functionality available in Catch2
list(APPEND CMAKE_MODULE_PATH ${Catch2_SOURCE_DIR}/contrib)
include(Catch)

add_executable(test_tool_1 
    ../src/fn.cpp
    test_main.cpp
    test_tool_1.cpp)

target_include_directories(test_tool_1
    PUBLIC
    ../include)

target_link_libraries(test_tool_1
    PUBLIC
    lib_A
    lib_B
    Catch2::Catch2
    fmt::fmt
)

# Make use of the extra functionality available in Catch2
catch_discover_tests(test_tool_1)

```

## Editing Code and Debugging

CMake's [`FetchContent`](https://cmake.org/cmake/help/latest/module/FetchContent.html) feature has one drawback when it code changes are required not only in the top-level project, but also in dependencies. All files are pulled into a subdirectory of the build directory, namely [`${CMAKE_BINARY_DIR}`](https://cmake.org/cmake/help/latest/variable/CMAKE_BINARY_DIR.html#cmake-binary-dir)`/_deps`. There they are not under version control. This makes code editing a pain. Also, building and debugging multiple variants (e.g. differing in compiler flags) requires to download or clone all dependencies multiple times into different build directories. This does not scale well with large dependency trees.

With the utilities presented here this is easily overcome. It is guaranteed that the network traffic *and* the disc usage are both minimized with the approach presented here.   

All one has to do is declare a deviation from the standard CMake behavior and set a custom filesystem location (directory) for the so-called workspace, i.e. the place where all dependencies are copied to on the filesystem. 

### Variant 1: A subdirectory below the top-level directory 

Add the following lines to `CMakeLists.txt` *before* (!) the call to `FetchContent_MakeAvailable(cmake_utilities)`  

```cmake
# Use a workspace instead of the default FetchContent directories
set(REPOMAN_DEPENDENCIES_USE_WORKSPACE ON CACHE BOOL "")

# Set the path to the directory containing all dependencies
set(REPOMAN_DEPENDENCIES_WORKSPACE "ws" CACHE PATH "")
```

Given these settings, the initial run of the `cmake` command with populate all dependencies into [`${CMAKE_PROJECT_NAME}`](https://cmake.org/cmake/help/latest/variable/CMAKE_PROJECT_NAME.html#cmake-project-name)`/ws` into a flat structure. All dependencies and all dependencies of dependencies mentioned in the top level `dependencies.txt` file will reside in dedicated subdirectories side by side.   

```bash
.../tool_1/build$ tree -L 2 ..
```
yields
```
..
├── build
...

└── ws
    ├── catch2
    ├── fmt
    ├── lib_A
    ├── lib_B
    └── libFreeAssange
```

### Variant 2: A named subdirectory besides the top-level directory 

Setting the path relatively adding a directory name, like e.g. 
```cmake
set(REPOMAN_DEPENDENCIES_WORKSPACE "../ws" CACHE PATH "") 
```
will use a custom directory name next to current project directory [`${CMAKE_PROJECT_NAME}`](https://cmake.org/cmake/help/latest/variable/CMAKE_PROJECT_NAME.html#cmake-project-name)

```bash
tool_1/build$ tree -L 2 ../..
```

yields

```
../..
├── tool_1
│   ├── build
│   ├── CMakeLists.txt
│   ├── dependencies.txt
│   ├── include
│   ├── src
│   └── test-catch
└── ws
    ├── catch2
    ├── fmt
    ├── lib_A
    ├── lib_B
    └── libFreeAssange
```


### Variant 3: Autogenerated unique directory names besides the top-level directory 

Setting the path relatively without adding a directory name, like e.g.    

```cmake
set(REPOMAN_DEPENDENCIES_WORKSPACE "../" CACHE PATH "") 
```
will use an automatically generated directory name and place it besides the current project directory [`${CMAKE_PROJECT_NAME}`](https://cmake.org/cmake/help/latest/variable/CMAKE_PROJECT_NAME.html#cmake-project-name).

```bash
tool_1/build$ tree -L 2 ../..
```

yields

```
../..
├── tool_1
│   ├── build
│   ├── CMakeLists.txt
│   ├── dependencies.txt
│   ├── include
│   ├── src
│   └── test-catch
└── tool_1-dependencies
    ├── catch2
    ├── fmt
    ├── lib_A
    ├── lib_B
    └── libFreeAssange

```


## Robustness Against Accidental Overwrites

The utilities presented here are robust against accidental overwrites. You can run CMake repetitively multiple times. This goes so far that if before running CMake you place a directory named after a dependency name into the workspace, maybe containing completely different code or code obtained from a different source than declared in the `dependencies.txt` file, this code or data will not get overwritten, rather the build will use what it finds in this directory. 

## Checking the Status of the Code

In addition, for all directories which are under version control, the utilities provide a custom target `repoman-status` to check the version control status. This yields a bulk status check over all directories.   

After the CMake run simply issue the command

```bash
make repoman-status
```

which e.g. yields

```
TODO
```