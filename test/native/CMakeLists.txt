cmake_minimum_required(VERSION 3.16.0)
project(test C ASM)

file(GLOB sources
  *.c
  *.h
)


include_directories(${small_SOURCE_DIR}/include)
include_directories(${small_SOURCE_DIR}/include/small)
include_directories(${small_SOURCE_DIR}/third_party)
include_directories(${small_BINARY_DIR}/small/include)
include_directories(${liburing_SOURCE_DIR}/src/include)
include_directories(${liburing_BINARY_DIR}/src/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../../native/include)
include_directories(${PROJECT_BINARY_DIR})
include_directories(${PROJECT_SOURCE_DIR})

add_library(interactor_test SHARED ${sources})
target_link_libraries(interactor_test PUBLIC interactor_debug_linux_x64)
add_custom_command(TARGET interactor_test POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:interactor_test> ${CMAKE_CURRENT_SOURCE_DIR}/../dart/native/libinteractortest.so)