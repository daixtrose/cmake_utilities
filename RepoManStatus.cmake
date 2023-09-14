# Show the status of a git project with regard to an expected state

# Check for missing arguments
foreach(ARGUMENT IN ITEMS NAME REPO EXPECTED_REVISION EXPECTED_REMOTE)
    if(NOT ${ARGUMENT})
        message(FATAL_ERROR "${ARGUMENT} is not defined.")
    endif()
endforeach()

find_program(GIT_COMMAND git REQUIRED)
mark_as_advanced(GIT_COMMAND)

set(STATUS "")

# Update repo
execute_process(COMMAND ${GIT_COMMAND} fetch --all
                OUTPUT_QUIET
                WORKING_DIRECTORY ${REPO})

# Check remote
execute_process(COMMAND ${GIT_COMMAND} remote get-url origin
                WORKING_DIRECTORY ${REPO}
                OUTPUT_VARIABLE REMOTE
                OUTPUT_STRIP_TRAILING_WHITESPACE
                COMMAND_ERROR_IS_FATAL ANY)

if(NOT EXPECTED_REMOTE STREQUAL REMOTE)
    string(APPEND STATUS "Remote: ${REMOTE} (expected ${EXPECTED_REMOTE})")
endif()

# Check current HEAD
execute_process(COMMAND ${GIT_COMMAND} show --no-patch --pretty="%D, %h" HEAD
                WORKING_DIRECTORY ${REPO}
                OUTPUT_VARIABLE LOCAL_REVISION
                OUTPUT_STRIP_TRAILING_WHITESPACE
                COMMAND_ERROR_IS_FATAL ANY)


string(REPLACE "\"" "" LOCAL_REVISION ${LOCAL_REVISION})
string(REPLACE "tag: " "" LOCAL_REVISION ${LOCAL_REVISION})
string(REPLACE ", " ";" LOCAL_REVISION ${LOCAL_REVISION})
execute_process(COMMAND ${GIT_COMMAND} branch --show-current
                WORKING_DIRECTORY ${REPO}
                OUTPUT_VARIABLE LOCAL_BRANCH
                OUTPUT_STRIP_TRAILING_WHITESPACE)
if(LOCAL_BRANCH)
    list(APPEND LOCAL_REVISION ${LOCAL_BRANCH})
endif()

set(REVISION "")
list(REVERSE LOCAL_REVISION)
foreach(ITEM IN LISTS LOCAL_REVISION)
    if(NOT ITEM MATCHES "^HEAD.*")
        if(EXPECTED_REVISION STREQUAL ITEM)
            unset(FOUND_REVISION)
            break()
        else()
            set(FOUND_REVISION "Revision: ${ITEM} (expected ${EXPECTED_REVISION})")
        endif()
    endif()
endforeach()
if(FOUND_REVISION)
    string(APPEND STATUS "${FOUND_REVISION})")
endif()

# Check for modifications
execute_process(COMMAND "${GIT_COMMAND}" describe --always --dirty --broken
                WORKING_DIRECTORY ${REPO}
                OUTPUT_VARIABLE GIT_STATUS
                OUTPUT_STRIP_TRAILING_WHITESPACE
                COMMAND_ERROR_IS_FATAL ANY)

if(GIT_STATUS MATCHES ".*-dirty")
    execute_process(COMMAND "${GIT_COMMAND}" status --show-stash --renames --ahead-behind
                    WORKING_DIRECTORY "${REPO}"
                    OUTPUT_VARIABLE GIT_STATUS
	    	        OUTPUT_STRIP_TRAILING_WHITESPACE
		            COMMAND_ERROR_IS_FATAL ANY)
    string(APPEND STATUS "\nStatus:\n${GIT_STATUS}")
endif()

# Print status
if(STATUS)
    message(STATUS "Dependency '${NAME}': ${STATUS}")
else()
    message(STATUS "Dependency '${NAME}': ok (${EXPECTED_REVISION})")
endif()
