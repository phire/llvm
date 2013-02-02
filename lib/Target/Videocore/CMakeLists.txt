set(LLVM_TARGET_DEFINITIONS Videocore.td)

tablegen(LLVM VideocoreGenRegisterInfo.inc -gen-register-info)
tablegen(LLVM VideocoreGenDisassemblerTables.inc -gen-disassembler)
tablegen(LLVM VideocoreGenInstrInfo.inc -gen-instr-info)
tablegen(LLVM VideocoreGenAsmWriter.inc -gen-asm-writer)
#tablegen(LLVM VideocoreGenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM VideocoreGenCodeEmitter.inc -gen-emitter)
tablegen(LLVM VideocoreGenMCCodeEmitter.inc -gen-emitter -mc-emitter)
tablegen(LLVM VideocoreGenDAGISel.inc -gen-dag-isel)
tablegen(LLVM VideocoreGenSubtargetInfo.inc -gen-subtarget)
tablegen(LLVM VideocoreGenCallingConv.inc -gen-callingconv)
add_public_tablegen_target(VideocoreCommonTableGen)

add_llvm_target(VideocoreCodeGen
  VideocoreAsmPrinter.cpp
  VideocoreInstrInfo.cpp
  VideocoreISelDAGToDAG.cpp
  VideocoreISelLowering.cpp
  VideocoreFrameLowering.cpp
  VideocoreMachineFunctionInfo.cpp
  VideocoreMCInstLower.cpp
  VideocoreRegisterInfo.cpp
  VideocoreSubtarget.cpp
  VideocoreTargetMachine.cpp
  VideocoreSelectionDAGInfo.cpp
  )

add_dependencies(LLVMVideocoreCodeGen intrinsics_gen)

add_subdirectory(TargetInfo)
add_subdirectory(MCTargetDesc)
add_subdirectory(InstPrinter)


