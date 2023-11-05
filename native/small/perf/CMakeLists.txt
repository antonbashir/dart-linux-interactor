set(CMAKE_CXX_STANDARD 11)

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    return()
endif()

find_package(benchmark QUIET)
if (NOT ${benchmark_FOUND})
    return()
endif()

include_directories("${PROJECT_SOURCE_DIR}")

add_executable(small.perftest small.cc)
target_link_libraries(small.perftest small benchmark::benchmark)
