//===-- VideocoreISelLowering.cpp - Videocore DAG Lowering Implementation -===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the interfaces that Videocore uses to lower LLVM code 
// into a selection DAG.
//
//===----------------------------------------------------------------------===//

#include "VideocoreISelLowering.h"
#include "VideocoreTargetMachine.h"
#include "VideocoreMachineFunctionInfo.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/SelectionDAG.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/Support/ErrorHandling.h"
using namespace llvm;


//===----------------------------------------------------------------------===//
// Calling Convention Implementation
//===----------------------------------------------------------------------===//

#include "VideocoreGenCallingConv.inc"

//===----------------------------------------------------------------------===//
// TargetLowering Implementation
//===----------------------------------------------------------------------===//

VideocoreTargetLowering::VideocoreTargetLowering(TargetMachine &TM)
  : TargetLowering(TM, new TargetLoweringObjectFileELF()) {

  // Set up the register classes.
  addRegisterClass(MVT::i32, &VC::IntRegRegClass);
  addRegisterClass(MVT::f32, &VC::FloatRegRegClass);
  addRegisterClass(MVT::i32, &VC::LowRegRegClass);

  // Turn FP extload into load/fextend
  setLoadExtAction(ISD::EXTLOAD, MVT::f32, Expand);
  // Videocore doesn't have i1 loads
  setLoadExtAction(ISD::SEXTLOAD, MVT::i1, Promote);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::i1, Promote);
  setLoadExtAction(ISD::EXTLOAD, MVT::i1, Promote);

  // Turn FP truncstore into trunc + store.
  setTruncStoreAction(MVT::f64, MVT::f32, Expand);

  // FIXME: Videocore provides these multiplies, but we don't have them yet.
  setOperationAction(ISD::UMUL_LOHI, MVT::i32, Expand);
  setOperationAction(ISD::SMUL_LOHI, MVT::i32, Expand);

  // Use the default implementation.
  setOperationAction(ISD::VACOPY            , MVT::Other, Expand);
  setOperationAction(ISD::VAEND             , MVT::Other, Expand);
  setOperationAction(ISD::STACKSAVE         , MVT::Other, Expand);
  setOperationAction(ISD::STACKRESTORE      , MVT::Other, Expand);
  setOperationAction(ISD::DYNAMIC_STACKALLOC, MVT::i32  , Custom);

  // No debug info support yet.
  setOperationAction(ISD::EH_LABEL, MVT::Other, Expand);

  // VC instructions have the comparison predicate attached to the user of the
  // result, but having a separate comparison is valuable for matching.
  setOperationAction(ISD::BR_CC, MVT::i32, Custom);
  setOperationAction(ISD::BR_CC, MVT::f32, Custom);

  setOperationAction(ISD::SELECT, MVT::i32, Custom);
  setOperationAction(ISD::SELECT, MVT::f32, Custom);

  setOperationAction(ISD::SELECT_CC, MVT::i32, Custom);
  setOperationAction(ISD::SELECT_CC, MVT::f32, Custom);

  setOperationAction(ISD::BRCOND, MVT::Other, Custom);

  setOperationAction(ISD::SETCC, MVT::i32, Custom);
  setOperationAction(ISD::SETCC, MVT::f32, Custom);


  setStackPointerRegisterToSaveRestore(VC::SP);

  setMinFunctionAlignment(2);

  computeRegisterProperties();
}


SDValue VideocoreTargetLowering::
LowerOperation(SDValue Op, SelectionDAG &DAG) const {
  switch (Op.getOpcode()) {
  default: llvm_unreachable("Should not custom lower this!");
    case ISD::BRCOND: return LowerBRCOND(Op, DAG);
    case ISD::BR_CC: return LowerBR_CC(Op, DAG);
    case ISD::SELECT: return LowerSELECT(Op, DAG);
    case ISD::SELECT_CC: return LowerSELECT_CC(Op, DAG);
    case ISD::SETCC: return LowerSETCC(Op, DAG);
  }
}

static VCCC::CondCodes getVCCC(ISD::CondCode CC) {
  switch (CC) {
  case ISD::SETEQ:  return VCCC::EQ;
  case ISD::SETGT:  return VCCC::GT;
  case ISD::SETGE:  return VCCC::GE;
  case ISD::SETLT:  return VCCC::LT;
  case ISD::SETLE:  return VCCC::LE;
  case ISD::SETNE:  return VCCC::NE;
  case ISD::SETUGT: return VCCC::HI;
  case ISD::SETUGE: return VCCC::HS;
  case ISD::SETULT: return VCCC::LO;
  case ISD::SETULE: return VCCC::LS;
  default: llvm_unreachable("Unexpected condition code");
  }
}


SDValue VideocoreTargetLowering::
LowerBRCOND(SDValue Op, SelectionDAG &DAG) const {
  llvm_unreachable("LowerBRCOND");
  return Op;
}

// (BR_CC chain, condcode, lhs, rhs, dest)
SDValue VideocoreTargetLowering::
LowerBR_CC(SDValue Op, SelectionDAG &DAG) const {
  DebugLoc dl = Op.getDebugLoc();
  SDValue Chain = Op.getOperand(0);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(1))->get();
  SDValue LHS = Op.getOperand(2);
  SDValue RHS = Op.getOperand(3);
  SDValue DestBB = Op.getOperand(4);

  SDValue VCcc = DAG.getConstant(getVCCC(CC), MVT::i32);
  SDValue SetCC = DAG.getNode(VCISD::SETCC, dl, MVT::i32, LHS, RHS,
                              DAG.getCondCode(CC));
  SDValue VCBR_CC = DAG.getNode(VCISD::BR_CC, dl, MVT::Other,
                                Chain, SetCC, VCcc, DestBB);

  return VCBR_CC;
}

SDValue VideocoreTargetLowering::
LowerSELECT(SDValue Op, SelectionDAG &DAG) const {
  llvm_unreachable("LowerSELECT");
  return Op;
}

SDValue VideocoreTargetLowering::
LowerSELECT_CC(SDValue Op, SelectionDAG &DAG) const {
  llvm_unreachable("LowerSELECT_CC");
  return Op;
}

SDValue VideocoreTargetLowering::
LowerSETCC(SDValue Op, SelectionDAG &DAG) const {
  llvm_unreachable("LowerSETCC");
  return Op;
}



/// LowerFormalArguments - transform physical registers into virtual registers
/// and generate load operations for arguments places on the stack.
SDValue VideocoreTargetLowering::
LowerFormalArguments(SDValue Chain,
                     CallingConv::ID CallConv,
                     bool isVarArg,
                     const SmallVectorImpl<ISD::InputArg> &Ins,
                     DebugLoc dl, SelectionDAG &DAG,
                     SmallVectorImpl<SDValue> &InVals) const {
  return Chain;
}

//===----------------------------------------------------------------------===//
//               Return Value Calling Convention Implementation
//===----------------------------------------------------------------------===//

SDValue
VideocoreTargetLowering::LowerReturn(SDValue Chain,
                                CallingConv::ID CallConv, bool isVarArg,
                                const SmallVectorImpl<ISD::OutputArg> &Outs,
                                const SmallVectorImpl<SDValue> &OutVals,
                                DebugLoc dl, SelectionDAG &DAG) const {
    SmallVector<CCValAssign, 16> RVLocs;
    CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(),
                 getTargetMachine(), RVLocs, *DAG.getContext());
    CCInfo.AnalyzeReturn(Outs, RetCC_VC4);

    // If this is the first return lowered for this function, add the regs to the
    // liveout set for the function.
    //if (DAG.getMachineFunction().getRegInfo().liveout_empty()) {
    //    for (unsigned i = 0; i != RVLocs.size(); ++i)
    //    DAG.getMachineFunction().getRegInfo().addLiveOut(RVLocs[i].getLocReg());
    //}

    SDValue Flag;

  // Copy the result values into the output registers.
    for (unsigned i = 0; i != RVLocs.size(); ++i) {
        CCValAssign &VA = RVLocs[i];
        assert(VA.isRegLoc() && "Can only return in registers!");

        SDValue Arg = OutVals[i];

        switch (VA.getLocInfo()) {
        default: llvm_unreachable("Unknown loc info!");
        case CCValAssign::Full: break;
        case CCValAssign::AExt:
            Arg = DAG.getNode(ISD::ANY_EXTEND, dl, VA.getLocVT(), Arg);
            break;
        case CCValAssign::ZExt:
            Arg = DAG.getNode(ISD::ZERO_EXTEND, dl, VA.getLocVT(), Arg);
            break;
        case CCValAssign::SExt:
            Arg = DAG.getNode(ISD::SIGN_EXTEND, dl, VA.getLocVT(), Arg);
            break;
        }

        Chain = DAG.getCopyToReg(Chain, dl, VA.getLocReg(), Arg, Flag);
        Flag = Chain.getValue(1);
    }

    if (Flag.getNode())
        return DAG.getNode(VCISD::RET_FLAG, dl, MVT::Other, Chain, Flag);
    else
        return DAG.getNode(VCISD::RET_FLAG, dl, MVT::Other, Chain);
}

