cmake_minimum_required(VERSION 3.16.0)
project(root C ASM)

add_definitions("-D_GNU_SOURCE")
set(EXECUTABLE_OUTPUT_PATH  "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED true)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED true)
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -fPIC -O0 -g -fno-stack-protector")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} -fPIC -flto -O2 -fno-stack-protector")

set(LIBURING_REPOSITORY "developer@git.local:dependencies/liburing.git")
set(LIBURING_VERSION evolution)
set(SMALL_REPOSITORY "developer@git.local:dependencies/tarantool-small.git")
set(SMALL_VERSION evolution)

include(FetchContent)

FetchContent_Declare(
  liburing
  GIT_REPOSITORY ${LIBURING_REPOSITORY}
  GIT_TAG ${LIBURING_VERSION}
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/dependencies/liburing
)
FetchContent_MakeAvailable(liburing)
add_custom_target(liburing COMMAND ./configure --prefix=${liburing_SOURCE_DIR}/build && make && make install WORKING_DIRECTORY ${liburing_SOURCE_DIR})

FetchContent_Declare(
  small
  GIT_REPOSITORY ${SMALL_REPOSITORY}
  GIT_TAG ${SMALL_VERSION}
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/dependencies/small
)
FetchContent_MakeAvailable(small)
add_subdirectory(${small_SOURCE_DIR})

add_subdirectory(native)
add_subdirectory(test/native)