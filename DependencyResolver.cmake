cmake_minimum_required(VERSION 3.16.4)
project(dependency_resolver VERSION 1.1.0)

find_package(Git REQUIRED)

macro(fetchcontent_dependencies)
    set(options "")
    set(oneValueArgs FILENAME WORKSPACE)
    set(multiValueArgs "")
    cmake_parse_arguments(FETCHCONTENT_DEPENDENCIES "${options}" "${oneValueArgs}"
                        "${multiValueArgs}" ${ARGN})
    
    # Read a list of required git repositories from a file
    file(STRINGS ${FETCHCONTENT_DEPENDENCIES_FILENAME} DEPENDENCIES)

    # Add those dependencies via FetchContent

    # STEP 1: declare all dependencies
    foreach(dependency ${DEPENDENCIES})
        # Strip leading spaces
        string(REGEX REPLACE "^[ ]+" "" dependency ${dependency})
        
        # skip empty lines
        if ("${dependency}" STREQUAL "")
            continue()
        endif()

        # skip comment lines
        if ("${dependency}" MATCHES "^#")
            continue()
        endif()

        # transform into list
        separate_arguments(deps_as_list UNIX_COMMAND ${dependency})
        
        # Extract space-separated values 
        list(GET deps_as_list 0 name)
        list(GET deps_as_list 1 repository)
        list(GET deps_as_list 2 git_tag)  

        list (LENGTH deps_as_list nelem)

        if (${nelem} GREATER 3)
            list(GET deps_as_list 3 additional_args)
        endif()  

        # If the dependency was formerly cloned to the workspace (aka directory exists), 
        # use it, otherwise declare as to be fetched from URL
        set (LOCAL_SOURCE ${PROJECT_SOURCE_DIR}/${FETCHCONTENT_DEPENDENCIES_WORKSPACE}/${name})

        if (EXISTS ${LOCAL_SOURCE})
            # Note that cmake makes a copy into its build/_deps directory, but 
            # detects any changes made at 
            # ${LOCAL_SOURCE} 

            # Check git version
            if (EXISTS ${LOCAL_SOURCE}/.git)            
                execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD 
                    WORKING_DIRECTORY ${LOCAL_SOURCE}
                    OUTPUT_VARIABLE git_tag_detected
                    RESULT_VARIABLE GIT_COMMAND_RESULT 
                    # COMMAND_ECHO STDOUT
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

                if(NOT GIT_COMMAND_RESULT EQUAL "0")
                    set(git_tag_detected "!!! CHECKING OF VERSION FAILED !!!")
                endif()
            else()
                set(git_tag_detected "!!! NOT UNDER VERSION CONTROL !!!")
            endif()

            message("Adding '${name}' from '${PROJECT_SOURCE_DIR}/ws/${name}' with git tag '${git_tag_detected}'")      
            
            FetchContent_Declare(${name} 
                SOURCE_DIR ${PROJECT_SOURCE_DIR}/ws/${name})
        else()
            message("Adding '${name}' from '${repository}' with git tag '${git_tag}'")  
            FetchContent_Declare(${name} 
                GIT_REPOSITORY ${repository}
                GIT_TAG ${git_tag}
            )
        endif()
    endforeach()

    # STEP 2: populate
    foreach(dependency ${DEPENDENCIES})
        # Strip leading spaces
        string(REGEX REPLACE "^[ ]+" "" dependency ${dependency})
        
        # skip empty lines
        if ("${dependency}" STREQUAL "")
            continue()
        endif()

        # skip comment lines
        if ("${dependency}" MATCHES "^#")
            continue()
        endif()

        # transform into list
        separate_arguments(deps_as_list UNIX_COMMAND ${dependency})
        
        # Extract space-separated values 
        list(GET deps_as_list 0 name)

        FetchContent_GetProperties(${name})
        
        string(TOLOWER ${name} lowercase_name)
        
        if(NOT ${lowercase_name}_POPULATED)
            message("==> Populating '${name}' ...")     
            FetchContent_Populate(${name})
            message("==> Adding subdirectory ${${name}_SOURCE_DIR}")
            add_subdirectory(${${lowercase_name}_SOURCE_DIR} ${${lowercase_name}_BINARY_DIR} ${additional_args})
        endif()

        # HACK: we **know** we need extra work for Catch2 population 
        # We could generalize this approach and check for *.cmake files in order to add 
        # the directories they reside in CMAKE_MODULE_PATH. This itself could yield 
        # some problems, so this must be carefully designed
        if ("${lowercase_name}" STREQUAL "catch2")
            message("==> Appending ${catch2_SOURCE_DIR}/contrib to CMAKE_MODULE_PATH")
            list(APPEND CMAKE_MODULE_PATH "${catch2_SOURCE_DIR}/contrib")
            message("CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}")
            include(Catch)
        endif()
    endforeach()
endmacro()
