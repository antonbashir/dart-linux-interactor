cmake_minimum_required(VERSION 3.16.0)

if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
  cmake_policy(SET CMP0135 NEW)
endif()

project(native C ASM)

set(LIBURING_REPOSITORY "developer@git.local:dependencies/liburing.git")
set(LIBURING_VERSION evolution)
set(SMALL_REPOSITORY "developer@git.local:dependencies/tarantool-small.git")
set(SMALL_VERSION evolution)

add_definitions("-D_GNU_SOURCE")
set(CMAKE_REQUIRED_DEFINITIONS "-D_GNU_SOURCE")

set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -fPIC -O0 -g -fno-stack-protector")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} -fPIC -O3 -fno-stack-protector")
set(HAVE_CLOCK_GETTIME_DECL ON)

include(FetchContent)

FetchContent_Declare(
  liburing
  GIT_REPOSITORY ${LIBURING_REPOSITORY}
  GIT_TAG ${LIBURING_VERSION}
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/liburing
)
FetchContent_MakeAvailable(liburing)
include_directories(${liburing_SOURCE_DIR}/src/include)
add_custom_target(liburing COMMAND ./configure --prefix=${liburing_SOURCE_DIR}/build && make && make install WORKING_DIRECTORY ${liburing_SOURCE_DIR})

FetchContent_Declare(
  small
  GIT_REPOSITORY ${SMALL_REPOSITORY} 
  GIT_TAG ${SMALL_VERSION}
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/small
)
FetchContent_MakeAvailable(small)
include_directories(${small_SOURCE_DIR}/src/include)
include_directories(${small_SOURCE_DIR}/include)
include_directories(${small_SOURCE_DIR}/third_party)
include_directories(${small_BINARY_DIR}/small/include)
add_subdirectory(${small_SOURCE_DIR})

configure_file(
  "${PROJECT_SOURCE_DIR}/common/configuration.h.cmake"
  "${PROJECT_SOURCE_DIR}/common/configuration.h"
)
message(STATUS "")

file(GLOB sources
  *.c
  *.h
  dart/*.h
  dart/*.c
  collections/*.h
  collections/*.c
  common/*.h
  common/*.c
)

include_directories(${PROJECT_BINARY_DIR})
include_directories(${PROJECT_SOURCE_DIR})
include_directories(include)

add_library(native SHARED ${sources})
add_dependencies(native liburing small)
target_link_libraries(native PRIVATE ${liburing_SOURCE_DIR}/build/lib/liburing.a small)
add_custom_command(TARGET native POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:native> ${CMAKE_CURRENT_SOURCE_DIR}/../dart/native/libinteractor.so)
