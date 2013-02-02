add_llvm_library(LLVMVideocoreDesc
  VideocoreMCTargetDesc.cpp
  VideocoreMCAsmInfo.cpp
  VideocoreMCCodeEmitter.cpp
  VideocoreELFObjectWriter.cpp
  VideocoreAsmBackend.cpp
  )

add_dependencies(LLVMVideocoreDesc VideocoreCommonTableGen)

# Hack: we need to include 'main' target directory to grab private headers
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/.. ${CMAKE_CURRENT_BINARY_DIR}/..)
