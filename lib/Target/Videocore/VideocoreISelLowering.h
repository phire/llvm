//===-- VideocoreISelLowering.h - Videocore DAG Lowering Interface --------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the interfaces that Videocore uses to lower LLVM code into a
// selection DAG.
//
//===----------------------------------------------------------------------===//

#ifndef VIDEOCORE_ISELLOWERING_H
#define VIDEOCORE_ISELLOWERING_H

#include "Videocore.h"
#include "llvm/Target/TargetLowering.h"

namespace llvm {
  namespace SPISD {
    enum {
      FIRST_NUMBER = ISD::BUILTIN_OP_END
    };
  }

  class VideocoreTargetLowering : public TargetLowering {
  public:
    VideocoreTargetLowering(TargetMachine &TM);
    virtual SDValue LowerOperation(SDValue Op, SelectionDAG &DAG) const;


  };
} // end namespace llvm

#endif    // VIDEOCORE_ISELLOWERING_H
