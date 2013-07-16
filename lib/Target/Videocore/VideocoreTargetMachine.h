//===-- VideocoreTargetMachine.h - Define TargetMachine for Videocore ---*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the Videocore specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//

#ifndef VIDEOCORETARGETMACHINE_H
#define VIDEOCORETARGETMACHINE_H

#include "VideocoreInstrInfo.h"
#include "VideocoreFrameLowering.h"
#include "VideocoreISelLowering.h"
#include "VideocoreSelectionDAGInfo.h"
#include "VideocoreSubtarget.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetFrameLowering.h"

namespace llvm {

class VideocoreTargetMachine : public LLVMTargetMachine {
  const DataLayout DL;       // Calculates type size & alignment
  VideocoreSubtarget Subtarget;
  VideocoreInstrInfo InstrInfo;
  VideocoreTargetLowering TLInfo;
  VideocoreSelectionDAGInfo TSInfo;
  VideocoreFrameLowering FrameLowering;
public:
  VideocoreTargetMachine(const Target &T, StringRef TT,
                     StringRef CPU, StringRef FS, const TargetOptions &Options,
                     Reloc::Model RM, CodeModel::Model CM,
                     CodeGenOpt::Level OL);

  virtual const VideocoreInstrInfo *getInstrInfo() const { 
	return &InstrInfo;
 }
  virtual const TargetFrameLowering  *getFrameLowering() const {
    return &FrameLowering;
  }
  virtual const VideocoreRegisterInfo *getRegisterInfo() const {
    return &getInstrInfo()->getRegisterInfo();
  }
  virtual const VideocoreTargetLowering* getTargetLowering() const {
    return &TLInfo;
  }
  virtual const VideocoreSelectionDAGInfo* getSelectionDAGInfo() const {
    return &TSInfo;
  }
  virtual const VideocoreSubtarget *getSubtargetImpl() const { 
    return &Subtarget; 
  }
  virtual const DataLayout *getDataLayout() const { 
    return &DL; 
  }

  // Pass Pipeline Configuration
  virtual TargetPassConfig *createPassConfig(PassManagerBase &PM);
};

} // end namespace llvm

#endif
