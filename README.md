# CMake Utilities - Dependency Management Done Right

## TL;DR

CMake Utilities is a collection of utilities which help espcaping the dependency hell and to make dependency management as slick and easy as possible. 

It extends CMake's [`FetchContent`](https://cmake.org/cmake/help/latest/module/FetchContent.html) feature such that all dependency information is collected in a separate file in the top-level of the repository, thereby avoiding repetitive code in the CMake files and enabling efficient configuration management.

In addition, it provides support for developers to apply code changes across dependencies and the dependent code base. When configured accordingly, CMake will clone code or fetch binaries from dependencies (and recursively dependencies of dependencies), thereby making cross-codebase code editing an easy task. 

Impatient readers can look at [the examples](https://github.com/dep-heaven). People who want to understand the motivation and history of this project please attend [this talk](https://github.com/daixtrose/saying-goodbye-to-dependency-hell).

## A Quick First Example



See https://github.com/dep-heaven/tool_1 for how to use this tool.  
