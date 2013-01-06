//===-- SparcRegisterInfo.cpp - SPARC Register Information ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the SPARC implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#include "VideocoreRegisterInfo.h"
#include "Videocore.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Target/TargetInstrInfo.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/STLExtras.h"

#define GET_REGINFO_TARGET_DESC
#include "VideocoreGenRegisterInfo.inc"

using namespace llvm;

VideocoreRegisterInfo::VideocoreRegisterInfo(const TargetInstrInfo &tii)
  : VideocoreGenRegisterInfo(VC::LR, 0, 0), TII(tii) {
}

const uint16_t* VideocoreRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF)
                                                                         const {
  return CSR_VC4_SaveList;
}

BitVector VideocoreRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  Reserved.set(VC::SP); // Stack pointer
  Reserved.set(VC::LR); // link return
  Reserved.set(VC::SR); // status reg
  //Reserved.set(VC::PC); // program counter
  return Reserved;
}

unsigned VideocoreRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  return VC::R23;
}

void VideocoreRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                           int SPAdj, RegScavenger *RS) const {
  // Implement me!!!
}
