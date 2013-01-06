//===-- VideocoreFrameLowering.cpp - Videocore Frame Information ----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the Videocore implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "VideocoreFrameLowering.h"
#include "VideocoreInstrInfo.h"
#include "VideocoreMachineFunctionInfo.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

void VideocoreFrameLowering::emitPrologue(MachineFunction &MF) const {
  /*MachineBasicBlock &MBB = MF.front();
  MachineFrameInfo *MFI = MF.getFrameInfo();
  const VideocoreInstrInfo &TII =
    *static_cast<const VideocoreInstrInfo*>(MF.getTarget().getInstrInfo());
  MachineBasicBlock::iterator MBBI = MBB.begin();
  DebugLoc dl = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();

  // Get the number of bytes to allocate from the FrameInfo
  int NumBytes = (int) MFI->getStackSize();*/

}

void VideocoreFrameLowering::emitEpilogue(MachineFunction &MF,
                                  MachineBasicBlock &MBB) const {
  /*MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  const VideocoreInstrInfo &TII =
    *static_cast<const VideocoreInstrInfo*>(MF.getTarget().getInstrInfo());
  DebugLoc dl = MBBI->getDebugLoc();*/
}
