//===--- Videocore.h - Top-level interface for Videocore representation ---===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in the LLVM
// Videocore back-end.
//
//===----------------------------------------------------------------------===//

#ifndef TARGET_VIDEOCORE_H
#define TARGET_VIDEOCORE_H

#include "MCTargetDesc/VideocoreMCTargetDesc.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {
  class FunctionPass;
  class TargetMachine;
  class VideocoreTargetMachine;
  class formatted_raw_ostream;

  FunctionPass *createVideocoreISelDag(VideocoreTargetMachine &TM);

} // end namespace llvm;

#endif
