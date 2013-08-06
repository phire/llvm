//===-- VideocoreInstrInfo.cpp - Videocore Instruction Information --------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the Videocore implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "VideocoreInstrInfo.h"
#include "VideocoreMachineFunctionInfo.h"
#include "Videocore.h"
#include "llvm/MC/MCContext.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_INSTRINFO_CTOR
#include "VideocoreGenInstrInfo.inc"

namespace llvm {
namespace Videocore {

  // Videocore Condition Codes
  enum CondCode {
    COND_TRUE,
    COND_FALSE,
    COND_INVALID
  };
}
}

using namespace llvm;

VideocoreInstrInfo::VideocoreInstrInfo()
  : VideocoreGenInstrInfo(VC::ADJCALLSTACKDOWN, VC::ADJCALLSTACKUP),
    RI(*this) {
}
/*
static bool isZeroImm(const MachineOperand &op) {
  return op.isImm() && op.getImm() == 0;
}

/// isLoadFromStackSlot - If the specified machine instruction is a direct
/// load from a stack slot, return the virtual or physical register number of
/// the destination along with the FrameIndex of the loaded stack slot.  If
/// not, return 0.  This predicate must return 0 if the instruction has
/// any side effects other than loading from the stack slot.
unsigned VideocoreInstrInfo::
isLoadFromStackSlot(const MachineInstr *MI, int &FrameIndex) const{
  int Opcode = MI->getOpcode();
  return 0;
}

  /// isStoreToStackSlot - If the specified machine instruction is a direct
  /// store to a stack slot, return the virtual or physical register number of
  /// the source reg along with the FrameIndex of the loaded stack slot.  If
  /// not, return 0.  This predicate must return 0 if the instruction has
  /// any side effects other than storing to the stack slot.
unsigned
VideocoreInstrInfo::isStoreToStackSlot(const MachineInstr *MI,
                                   int &FrameIndex) const {
  int Opcode = MI->getOpcode();
  return 0;
}


/// AnalyzeBranch - Analyze the branching code at the end of MBB, returning
/// true if it cannot be understood (e.g. it's a switch dispatch or isn't
/// implemented for a target).  Upon success, this returns false and returns
/// with the following information in various cases:
///
/// 1. If this block ends with no branches (it just falls through to its succ)
///    just return false, leaving TBB/FBB null.
/// 2. If this block ends with only an unconditional branch, it sets TBB to be
///    the destination block.
/// 3. If this block ends with an conditional branch and it falls through to
///    an successor block, it sets TBB to be the branch destination block and a
///    list of operands that evaluate the condition. These
///    operands can be passed to other TargetInstrInfo methods to create new
///    branches.
/// 4. If this block ends with an conditional branch and an unconditional
///    block, it returns the 'true' destination in TBB, the 'false' destination
///    in FBB, and a list of operands that evaluate the condition. These
///    operands can be passed to other TargetInstrInfo methods to create new
///    branches.
///
/// Note that RemoveBranch and InsertBranch must be implemented to support
/// cases where this method returns success.
///
bool VideocoreInstrInfo::AnalyzeBranch(MachineBasicBlock &MBB,
                                  MachineBasicBlock *&TBB,
                                  MachineBasicBlock *&FBB,
                                  SmallVectorImpl<MachineOperand> &Cond,
                                  bool AllowModify) const {
  // If the block has no terminators, it just falls into the block after it.
  MachineBasicBlock::iterator I = MBB.end();
  if (I == MBB.begin())
    return false;
  --I;
  while (I->isDebugValue()) {
    if (I == MBB.begin())
      return false;
    --I;
  }
  if (!isUnpredicatedTerminator(I))
    return false;

  // Get the last instruction in the block.
  MachineInstr *LastInst = I;

  // If there is only one terminator instruction, process it.
  if (I == MBB.begin() || !isUnpredicatedTerminator(--I)) {
    if (IsBRU(LastInst->getOpcode())) {
      TBB = LastInst->getOperand(0).getMBB();
      return false;
    }

    Videocore::CondCode BranchCode = GetCondFromBranchOpc(LastInst->getOpcode());
    if (BranchCode == Videocore::COND_INVALID)
      return true;  // Can't handle indirect branch.

    // Conditional branch
    // Block ends with fall-through condbranch.

    TBB = LastInst->getOperand(1).getMBB();
    Cond.push_back(MachineOperand::CreateImm(BranchCode));
    Cond.push_back(LastInst->getOperand(0));
    return false;
  }

  // Get the instruction before it if it's a terminator.
  MachineInstr *SecondLastInst = I;

  // If there are three terminators, we don't know what sort of block this is.
  if (SecondLastInst && I != MBB.begin() &&
      isUnpredicatedTerminator(--I))
    return true;

  unsigned SecondLastOpc    = SecondLastInst->getOpcode();
  Videocore::CondCode BranchCode = GetCondFromBranchOpc(SecondLastOpc);

  // If the block ends with conditional branch followed by unconditional,
  // handle it.
  if (BranchCode != Videocore::COND_INVALID
    && IsBRU(LastInst->getOpcode())) {

    TBB = SecondLastInst->getOperand(1).getMBB();
    Cond.push_back(MachineOperand::CreateImm(BranchCode));
    Cond.push_back(SecondLastInst->getOperand(0));

    FBB = LastInst->getOperand(0).getMBB();
    return false;
  }

  // If the block ends with two unconditional branches, handle it.  The second
  // one is not executed, so remove it.
  if (IsBRU(SecondLastInst->getOpcode()) &&
      IsBRU(LastInst->getOpcode())) {
    TBB = SecondLastInst->getOperand(0).getMBB();
    I = LastInst;
    if (AllowModify)
      I->eraseFromParent();
    return false;
  }

  // Likewise if it ends with a branch table followed by an unconditional branch
  if (IsBR_JT(SecondLastInst->getOpcode()) && IsBRU(LastInst->getOpcode())) {
    I = LastInst;
    if (AllowModify)
      I->eraseFromParent();
    return true;
  }

  // Otherwise, can't handle this.
  return true;
}

unsigned
VideocoreInstrInfo::InsertBranch(MachineBasicBlock &MBB,MachineBasicBlock *TBB,
                             MachineBasicBlock *FBB,
                             const SmallVectorImpl<MachineOperand> &Cond,
                             DebugLoc DL)const{
  // Shouldn't be a fall through.
  assert(TBB && "InsertBranch must not be told to insert a fallthrough");
  assert((Cond.size() == 2 || Cond.size() == 0) &&
         "Unexpected number of components!");

  if (FBB == 0) { // One way branch.
    if (Cond.empty()) {
      // Unconditional branch
      BuildMI(&MBB, DL, get(Videocore::BRFU_lu6)).addMBB(TBB);
    } else {
      // Conditional branch.
      unsigned Opc = GetCondBranchFromCond((Videocore::CondCode)Cond[0].getImm());
      BuildMI(&MBB, DL, get(Opc)).addReg(Cond[1].getReg())
                             .addMBB(TBB);
    }
    return 1;
  }

  // Two-way Conditional branch.
  assert(Cond.size() == 2 && "Unexpected number of components!");
  unsigned Opc = GetCondBranchFromCond((Videocore::CondCode)Cond[0].getImm());
  BuildMI(&MBB, DL, get(Opc)).addReg(Cond[1].getReg())
                         .addMBB(TBB);
  BuildMI(&MBB, DL, get(Videocore::BRFU_lu6)).addMBB(FBB);
  return 2;
}

unsigned
VideocoreInstrInfo::RemoveBranch(MachineBasicBlock &MBB) const {
  MachineBasicBlock::iterator I = MBB.end();
  if (I == MBB.begin()) return 0;
  --I;
  while (I->isDebugValue()) {
    if (I == MBB.begin())
      return 0;
    --I;
  }
  if (!IsBRU(I->getOpcode()) && !IsCondBranch(I->getOpcode()))
    return 0;

  // Remove the branch.
  I->eraseFromParent();

  I = MBB.end();

  if (I == MBB.begin()) return 1;
  --I;
  if (!IsCondBranch(I->getOpcode()))
    return 1;

  // Remove the branch.
  I->eraseFromParent();
  return 2;
} */

void VideocoreInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator I, DebugLoc DL,
                                 unsigned DestReg, unsigned SrcReg,
                                 bool KillSrc) const {
  int opc;
  if (VC::LowRegRegClass.contains(SrcReg) &&
		VC::LowRegRegClass.contains(DestReg))
	opc = VC::MOVqq;
  else
	opc = VC::MOVrr;

  BuildMI(MBB, I, DL, get(opc)).addReg(DestReg).addReg(SrcReg);
}

/*
void VideocoreInstrInfo::storeRegToStackSlot(MachineBasicBlock &MBB,
                                         MachineBasicBlock::iterator I,
                                         unsigned SrcReg, bool isKill,
                                         int FrameIndex,
                                         const TargetRegisterClass *RC,
                                         const TargetRegisterInfo *TRI) const
{
  DebugLoc DL;
  if (I != MBB.end()) DL = I->getDebugLoc();
}

void VideocoreInstrInfo::loadRegFromStackSlot(MachineBasicBlock &MBB,
                                          MachineBasicBlock::iterator I,
                                          unsigned DestReg, int FrameIndex,
                                          const TargetRegisterClass *RC,
                                          const TargetRegisterInfo *TRI) const
{
  DebugLoc DL;
  if (I != MBB.end()) DL = I->getDebugLoc();
}

/// ReverseBranchCondition - Return the inverse opcode of the
/// specified Branch instruction.
bool VideocoreInstrInfo::
ReverseBranchCondition(SmallVectorImpl<MachineOperand> &Cond) const {
  assert((Cond.size() == 2) &&
          "Invalid Videocore branch condition!");
  Cond[0].setImm(GetOppositeBranchCondition((Videocore::CondCode)Cond[0].getImm()));
  return false;
} */
