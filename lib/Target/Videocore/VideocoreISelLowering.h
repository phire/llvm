//=== VideocoreISelLowering.h - Videocore DAG Lowering Interface -*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the interfaces that Videocore uses to lower LLVM code into
// a selection DAG.
//
//===----------------------------------------------------------------------===//

#ifndef VIDEOCORE_ISELLOWERING_H
#define VIDEOCORE_ISELLOWERING_H

#include "Videocore.h"
#include "MCTargetDesc/VideocoreBaseInfo.h"
#include "llvm/Target/TargetLowering.h"

namespace llvm {
  namespace VCISD {
    enum {
      FIRST_NUMBER = ISD::BUILTIN_OP_END,
      BR_CC,
      SELECT_CC,
      SETCC,
      RET_FLAG
    };
  }

  class VideocoreTargetLowering : public TargetLowering {
  public:
    VideocoreTargetLowering(TargetMachine &TM);
    virtual SDValue LowerOperation(SDValue Op, SelectionDAG &DAG) const;

  private:
	SDValue LowerBRCOND(SDValue Op, SelectionDAG &DAG) const;
	SDValue LowerBR_CC(SDValue Op, SelectionDAG &DAG) const;
	SDValue LowerSELECT(SDValue Op, SelectionDAG &DAG) const;
	SDValue LowerSELECT_CC(SDValue Op, SelectionDAG &DAG) const;
	SDValue LowerSETCC(SDValue Op, SelectionDAG &DAG) const;

    //- must be exist without function all
    virtual SDValue
      LowerFormalArguments(SDValue Chain,
                           CallingConv::ID CallConv, bool isVarArg,
                           const SmallVectorImpl<ISD::InputArg> &Ins,
                           DebugLoc dl, SelectionDAG &DAG,
                           SmallVectorImpl<SDValue> &InVals) const;

    //- must be exist without function all
    virtual SDValue
      LowerReturn(SDValue Chain,
                  CallingConv::ID CallConv, bool isVarArg,
                  const SmallVectorImpl<ISD::OutputArg> &Outs,
                  const SmallVectorImpl<SDValue> &OutVals,
                  DebugLoc dl, SelectionDAG &DAG) const;

  };
} // end namespace llvm

#endif    // VIDEOCORE_ISELLOWERING_H
