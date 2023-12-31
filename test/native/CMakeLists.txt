cmake_minimum_required(VERSION 3.16.0)
project(interactor_test C ASM)

add_definitions("-D_GNU_SOURCE")
set(CMAKE_REQUIRED_DEFINITIONS "-D_GNU_SOURCE")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -fPIC -O0 -g  -fno-stack-protector")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} -fPIC -O3 -fno-stack-protector")

file(GLOB sources
  *.c
  *.h
)

include_directories(${PROJECT_BINARY_DIR})
include_directories(${PROJECT_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../../native/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../../native/liburing/src/include)

add_library(interactor_test SHARED ${sources})
target_link_libraries(interactor_test PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/../../dart/native/libinteractor_debug_linux_x64.so")
add_custom_command(TARGET interactor_test POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:interactor_test> ${CMAKE_CURRENT_SOURCE_DIR}/../dart/native/libinteractortest.so)