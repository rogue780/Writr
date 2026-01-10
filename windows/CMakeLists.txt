cmake_minimum_required(VERSION 3.14)
project(writr LANGUAGES CXX)

set(BINARY_NAME "writr")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Flutter tool
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

# Application source
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Generated plugin build rules
include(flutter/generated_plugins.cmake)

# Application executable
add_executable(${BINARY_NAME}
  "windows/runner/main.cpp"
  "windows/runner/utils.cpp"
  "windows/runner/win32_window.cpp"
  "windows/runner/flutter_window.cpp"
  "windows/runner/run_loop.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "windows/runner/Runner.rc"
  "windows/runner/runner.exe.manifest"
)

apply_standard_settings(${BINARY_NAME})

target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)

target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}"
  "${FLUTTER_MANAGED_DIR}"
)

add_dependencies(${BINARY_NAME} flutter_assemble)
