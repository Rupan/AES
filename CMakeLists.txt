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

add_library(aes_dynamic SHARED ${LIB_SOURCES})
set_target_properties(aes_dynamic PROPERTIES
    OUTPUT_NAME aes
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/dynamic"
)
if(UNIX AND NOT APPLE)
    set_target_properties(aes_dynamic PROPERTIES
        SOVERSION 0
        VERSION ${PROJECT_VERSION}
    )
endif()
add_library(aes_static STATIC ${LIB_SOURCES})
set_target_properties(aes_static PROPERTIES
    OUTPUT_NAME aes
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/static"
)

add_executable(aesxam_d aesxam.c)
target_link_libraries(aesxam_d aes_dynamic)
add_executable(aesxam_s aesxam.c)
target_link_libraries(aesxam_s aes_static)

add_executable(tablegen tablegen.c aesaux.c)

add_executable(aesgav_d aesgav.c aesaux.c)
target_link_libraries(aesgav_d aes_dynamic)
add_executable(aesgav_s aesgav.c aesaux.c)
target_link_libraries(aesgav_s aes_static)

add_executable(aes_avs_d aes_avs.c aesaux.c)
target_link_libraries(aes_avs_d aes_dynamic)
add_executable(aes_avs_s aes_avs.c aesaux.c)
target_link_libraries(aes_avs_s aes_static)

add_executable(aesrav_d aesrav.c aesaux.c)
target_link_libraries(aesrav_d aes_dynamic)
add_executable(aesrav_s aesrav.c aesaux.c)
target_link_libraries(aesrav_s aes_static)

add_executable(aestst_d aestst.c)
target_link_libraries(aestst_d aes_dynamic)
add_executable(aestst_s aestst.c)
target_link_libraries(aestst_s aes_static)

add_executable(rfc3686_d rfc3686.c)
target_link_libraries(rfc3686_d aes_dynamic)
add_executable(rfc3686_s rfc3686.c)
target_link_libraries(rfc3686_s aes_static)

# Explicit thread to processor binding is not supported on OS X
if(NOT APPLE)
    add_executable(aestmr_d aestmr.c aesaux.c)
    add_executable(modetest_d modetest.c aesaux.c)
    add_executable(aestmr_s aestmr.c aesaux.c)
    add_executable(modetest_s modetest.c aesaux.c)
    if(WINDOWS)
        target_link_libraries(aestmr_d aes_dynamic)
        target_link_libraries(modetest_d aes_dynamic)
        target_link_libraries(aestmr_s aes_static)
        target_link_libraries(modetest_s aes_static)
    elseif(UNIX)
        target_link_libraries(aestmr_d aes_dynamic m)
        target_link_libraries(modetest_d aes_dynamic m)
        target_link_libraries(aestmr_s aes_static m)
        target_link_libraries(modetest_s aes_static m)
    endif()
endif()
