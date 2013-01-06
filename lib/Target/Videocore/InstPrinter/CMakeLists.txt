include_directories( ${CMAKE_CURRENT_BINARY_DIR}/.. ${CMAKE_CURRENT_SOURCE_DIR}/.. )

add_llvm_library(LLVMVideocoreAsmPrinter
  VideocoreInstPrinter.cpp
  VideocoreInstComments.cpp
  )

add_dependencies(LLVMVideocoreAsmPrinter VideocoreCommonTableGen)
