//===-- VideocoreFrameLowering.h - Define frame lowering for Videocore --*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//
//
//===----------------------------------------------------------------------===//

#ifndef VIDEOCORE_FRAMEINFO_H
#define VIDEOCORE_FRAMEINFO_H

#include "Videocore.h"
#include "llvm/Target/TargetFrameLowering.h"

namespace llvm {

class VideocoreFrameLowering : public TargetFrameLowering {
public:
  explicit VideocoreFrameLowering()
    : TargetFrameLowering(TargetFrameLowering::StackGrowsDown, 4, 0) {
  }

  /// emitProlog/emitEpilog - These methods insert prolog and epilog code into
  /// the function.
  void emitPrologue(MachineFunction &MF) const;
  void emitEpilogue(MachineFunction &MF, MachineBasicBlock &MBB) const;

  bool hasFP(const MachineFunction &MF) const { return false; }
};

} // End llvm namespace

#endif
