# CMake Utilities - Dependency Management Done Right

## TL;DR

CMake Utilities is a collection of utilities which help espcaping the dependency hell and to make dependency management as slick and easy as possible. 

It extends CMake's [`FetchContent`](https://cmake.org/cmake/help/latest/module/FetchContent.html) feature such that all dependency information is collected in a separate file in the top-level of the repository, thereby avoiding repetitive code in the CMake files and enabling efficient configuration management.

In addition, it provides support for developers to apply code changes across dependencies and the dependent code base. When configured accordingly, CMake will clone code or fetch binaries from dependencies (and recursively dependencies of dependencies), thereby making cross-codebase code editing an easy task. 

## Useful links

- Impatient readers can look at [the examples](https://github.com/dep-heaven). 
  - [tool_1](https://github.com/dep-heaven/tool_1) depends on [lib_A](https://github.com/dep-heaven/lib_A), [lib_B](https://github.com/dep-heaven/lib_B), and [libFreeAssange](https://github.com/dep-heaven/libFreeAssange)
  - [tool_2](https://github.com/dep-heaven/tool_2) depends on [lib_A](https://github.com/dep-heaven/lib_A), [lib_B](https://github.com/dep-heaven/lib_B), and [libFreeAssange](https://github.com/dep-heaven/libFreeAssange)
  - [lib_A](https://github.com/dep-heaven/lib_A) depends on [libFreeAssange](https://github.com/dep-heaven/libFreeAssange)
  - [lib_B](https://github.com/dep-heaven/lib_B) depends on [libFreeAssange](https://github.com/dep-heaven/libFreeAssange)
- People who want to understand the motivation and history of this project please check out [this talk](https://www.daixtrose.de/talk/saying-goodbye-to-dependency-hell/).

## A Quick First Example



See  for how to use this tool.  
