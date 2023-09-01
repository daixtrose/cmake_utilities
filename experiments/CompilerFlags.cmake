cmake_minimum_required(VERSION 3.16)
project(compiler_flags VERSION 1.1.0)

########################################################################
# define a virtual library target for propagation of compiler flags  

add_library(cxx_flags INTERFACE)
add_library(Daixtrose::CxxFlags ALIAS cxx_flags)

target_compile_features(cxx_flags INTERFACE cxx_std_20)

target_compile_options(cxx_flags INTERFACE
    # GCC
    # TODO: refine compiler flag settings according to your needs
    $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-fno-omit-frame-pointer>
    $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-Wuninitialized>
    $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-Wunused-parameter>
    $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-Wall>
    $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-Wextra>
    $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-Wpedantic>
    $<$<CXX_COMPILER_ID:GNU>:-Wno-psabi>
    $<$<CXX_COMPILER_ID:GNU>:-fPIC>
    
    # Clang    
    $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>>:-pedantic>
    $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>>:-fsanitize=integer>
    $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>>:-fno-omit-frame-pointer>
    $<$<CXX_COMPILER_ID:Clang>:-fPIC>
)


# Sanitizers

if (SANITIZE_THREAD)
    target_compile_options(cxx_flags INTERFACE
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-fsanitize=thread>
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>>:-fsanitize=thread>
    )

    target_link_libraries(cxx_flags INTERFACE
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-fsanitize=thread>
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>>:-fsanitize=thread>
    )
endif()

if (SANITIZE_ADDRESS)
    target_compile_options(cxx_flags INTERFACE
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-fsanitize=address>
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>>:-fsanitize=address>
    )

    target_link_libraries(cxx_flags INTERFACE
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-fsanitize=address>
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>>:-fsanitize=address>
    )
endif()

if (SANITIZE_UB)
    target_compile_options(cxx_flags INTERFACE
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-fsanitize=undefined>
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>>:-fsanitize=undefined>
    )

    target_link_libraries(cxx_flags INTERFACE
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-fsanitize=undefined>
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>>:-fsanitize=undefined>
    )
endif()

########################################################################
# set RPATH correctly

function(apply_rpath_settings target)
    set_target_properties(${target} 
        PROPERTIES
        BUILD_RPATH_USE_ORIGIN ON
        INSTALL_RPATH "$ORIGIN:$ORIGIN/../lib"
        BUILD_RPATH "$ORIGIN:$ORIGIN/../lib"
    )
endfunction()