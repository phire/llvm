//===-- VC4TargetMachine.cpp - Define TargetMachine for VC4 -----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//
//===----------------------------------------------------------------------===//

#include "VideocoreTargetMachine.h"
#include "Videocore.h"
#include "llvm/PassManager.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

extern "C" void LLVMInitializeVideocoreTarget() {
  // Register the target.
  RegisterTargetMachine<VideocoreTargetMachine> X(TheVideocoreTarget);
}

/// VideocoreTargetMachine ctor - Create an ILP32 architecture model
///
VideocoreTargetMachine::VideocoreTargetMachine(const Target &T, StringRef TT,
                                       StringRef CPU, StringRef FS,
                                       const TargetOptions &Options,
                                       Reloc::Model RM, CodeModel::Model CM,
                                       CodeGenOpt::Level OL)
  : LLVMTargetMachine(T, TT, CPU, FS, Options, RM, CM, OL),
    DL("e-p:32:32-i32:32:32"),
    Subtarget(TT, CPU, FS, true),
    InstrInfo(),
    TLInfo(*this), TSInfo(*this),
    FrameLowering(){
}

namespace {
/// Videocore Code Generator Pass Configuration Options.
class VideocorePassConfig : public TargetPassConfig {
public:
  VideocorePassConfig(VideocoreTargetMachine *TM, PassManagerBase &PM)
    : TargetPassConfig(TM, PM) {}

  VideocoreTargetMachine &getVideocoreTargetMachine() const {
    return getTM<VideocoreTargetMachine>();
  }

  virtual bool addInstSelector();
};
} // namespace

TargetPassConfig *VideocoreTargetMachine::createPassConfig(PassManagerBase &PM){
  return new VideocorePassConfig(this, PM);
}

bool VideocorePassConfig::addInstSelector() {
  addPass(createVideocoreISelDag(getVideocoreTargetMachine()));
  return false;
}
