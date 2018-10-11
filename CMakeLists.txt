cmake_minimum_required(VERSION 3.10)
project(aes_code VERSION 1.0.0 DESCRIPTION "AES code in C and assembly")

include(CheckCCompilerFlag)
include(CheckSymbolExists)

set(LIB_SOURCES aeskey.c aes_modes.c aestab.c aescrypt.c)

if(WINDOWS)
    set(YASM_EXE "c:\\\\program files\\\\yasm\\\\yasm.exe")
    set(YASM_EXE_PATH ${YASM_EXE})
    set(AES64_OPTIMIZED_CPU "AMD64")
elseif(UNIX)
    check_c_compiler_flag(-march=native HAS_MARCH_NATIVE)
    if(HAS_MARCH_NATIVE)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=native")
        set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} -march=native")
    endif()
    set(YASM_EXE_PATH "yasm")
    set(AES64_OPTIMIZED_CPU "x86_64")
else()
    message(FATAL_ERROR "Unsupported platform.")
endif()

if(CMAKE_SYSTEM_PROCESSOR STREQUAL "${AES64_OPTIMIZED_CPU}")
    list(APPEND CMAKE_REQUIRED_INCLUDES "${CMAKE_SOURCE_DIR}")
    # Add AES_NI source code if the define INTEL_AES_POSSIBLE exists in aesopt.h
    check_symbol_exists(INTEL_AES_POSSIBLE aesopt.h INTEL_AES_POSSIBLE)
    if(INTEL_AES_POSSIBLE)
        list(APPEND LIB_SOURCES aes_ni.c)
    endif()
    # Enable assembly code
    enable_language(ASM_NASM)
    set(CMAKE_ASM_NASM_COMPILER "${YASM_EXE_PATH}")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DASM_AMD64_C")
    if(WINDOWS)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DDLL_EXPORT")
    endif()
    list(APPEND LIB_SOURCES aes_amd64.asm)
    if(INTEL_AES_POSSIBLE)
        set(CMAKE_ASM_NASM_FLAGS "${CMAKE_ASM_NASM_FLAGS} -DINTEL_AES_POSSIBLE")
    endif()
    # On UNIX-like systems, use the System V AMD64 ABI
    if(UNIX)
        set(CMAKE_ASM_NASM_FLAGS "${CMAKE_ASM_NASM_FLAGS} -D__GNUC__")
    endif()
    # Enable debugging symbols on Linux -- others possible?
    if(CMAKE_BUILD_TYPE MATCHES Debug OR CMAKE_BUILD_TYPE MATCHES RelWithDebInfo)
        if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
            set(CMAKE_ASM_NASM_FLAGS "${CMAKE_ASM_NASM_FLAGS} -g dwarf2")
        endif()
    endif()
endif()

add_library(aes SHARED ${LIB_SOURCES})
if(UNIX AND NOT APPLE)
    set_target_properties(aes PROPERTIES
        SOVERSION 0
        VERSION ${PROJECT_VERSION}
    )
endif()

add_executable(aesxam aesxam.c)
target_link_libraries(aesxam aes)

add_executable(tablegen tablegen.c aesaux.c)

add_executable(aesgav aesgav.c aesaux.c)
target_link_libraries(aesgav aes)

add_executable(aes_avs aes_avs.c aesaux.c)
target_link_libraries(aes_avs aes)

add_executable(aesrav aesrav.c aesaux.c)
target_link_libraries(aesrav aes)

add_executable(aestst aestst.c)
target_link_libraries(aestst aes)

add_executable(rfc3686 rfc3686.c)
target_link_libraries(rfc3686 aes)

# Explicit thread to processor binding is not supported on OS X
if(NOT APPLE)
    add_executable(aestmr aestmr.c aesaux.c)
    add_executable(modetest modetest.c aesaux.c)
    if(WINDOWS)
        target_link_libraries(aestmr aes)
        target_link_libraries(modetest aes)
    elseif(UNIX)
        target_link_libraries(aestmr aes m)
        target_link_libraries(modetest aes m)
    endif()
endif()
