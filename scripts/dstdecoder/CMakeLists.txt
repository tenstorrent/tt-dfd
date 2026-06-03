cmake_minimum_required(VERSION 2.8.12)

# Define the project
project(dstdecoder)

# Enable C++11
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

#Shared libraries require position-independent code.
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Add include directories
include_directories(${PROJECT_SOURCE_DIR}/include)
include_directories(${PROJECT_SOURCE_DIR}/src)

# Define the library target (static or shared)
add_library(dstdecoder SHARED
    src/DSTDataPacket.cpp
    src/DSTDecoderAPI.cpp
    src/DSTDecoder.cpp
    src/DSTPacket.cpp
    src/DSTTimestampPacket.cpp
    src/FrameWalker.cpp
)

# Specify output directories for the library
set_target_properties(dstdecoder PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
    ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib
    RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin
)

# Optionally, define DLL export macros for Windows
target_compile_definitions(dstdecoder PRIVATE DSTDECODER_EXPORTS)


# Add a test executable to validate the library
add_executable(test_app test/Main.cpp)

# Link the library with the test executable
target_link_libraries(test_app dstdecoder)
