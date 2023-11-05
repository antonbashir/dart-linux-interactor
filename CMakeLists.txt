cmake_minimum_required(VERSION 3.16.0)

if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
  cmake_policy(SET CMP0135 NEW)
endif()

project(interactor C ASM)
add_subdirectory(native)
add_subdirectory(test/native)