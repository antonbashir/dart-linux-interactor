cmake_minimum_required(VERSION 3.16.0)

project(native C ASM)

set(LIBURING_REPOSITORY "developer@git.local:dependencies/liburing.git")
set(LIBURING_VERSION evolution)
set(SMALL_REPOSITORY "developer@git.local:dependencies/tarantool-small.git")
set(SMALL_VERSION evolution)

add_definitions("-D_GNU_SOURCE")
set(CMAKE_REQUIRED_DEFINITIONS "-D_GNU_SOURCE")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -fPIC -O0 -g -fno-stack-protector")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} -fPIC -flto -O3 -fno-stack-protector")

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

include_directories(${PROJECT_BINARY_DIR})
include_directories(${PROJECT_SOURCE_DIR})
include_directories(include)

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

add_library(interactor_debug_linux_x64 SHARED ${sources})
add_dependencies(interactor_debug_linux_x64 liburing small)
target_link_libraries(interactor_debug_linux_x64 PRIVATE ${liburing_SOURCE_DIR}/build/lib/liburing.a small)
add_custom_command(TARGET interactor_debug_linux_x64 POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:interactor_debug_linux_x64> ${CMAKE_CURRENT_SOURCE_DIR}/../dart/native/libinteractor_debug_linux_x64.so)

add_library(interactor_release_linux_x64 SHARED ${sources})
add_dependencies(interactor_release_linux_x64 liburing small)
target_link_libraries(interactor_release_linux_x64 PRIVATE ${liburing_SOURCE_DIR}/build/lib/liburing.a small)
add_custom_command(TARGET interactor_release_linux_x64 POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:interactor_release_linux_x64> ${CMAKE_CURRENT_SOURCE_DIR}/../dart/native/libinteractor_release_linux_x64.so)

add_custom_target(native DEPENDS interactor_release_linux_x64 interactor_debug_linux_x64)