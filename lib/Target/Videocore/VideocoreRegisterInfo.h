//===-- VideocoreRegisterInfo.h - Videocore Register Information Impl ---*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the Videocore implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef VCREGISTERINFO_H
#define VCREGISTERINFO_H

#include "llvm/Target/TargetRegisterInfo.h"

#define GET_REGINFO_HEADER
#include "VideocoreGenRegisterInfo.inc"

namespace llvm {

class TargetInstrInfo;
class Type;

struct VideocoreRegisterInfo : public VideocoreGenRegisterInfo {
  const TargetInstrInfo &TII;

  VideocoreRegisterInfo(const TargetInstrInfo &tii);

  /// Code Generation virtual methods...
  const uint16_t *getCalleeSavedRegs(const MachineFunction *MF = 0) const;

  BitVector getReservedRegs(const MachineFunction &MF) const;

  void eliminateFrameIndex(MachineBasicBlock::iterator II,
                           int SPAdj, RegScavenger *RS = NULL) const;

  // Debug information queries.
  unsigned getFrameRegister(const MachineFunction &MF) const;
};

} // end namespace llvm

#endif
