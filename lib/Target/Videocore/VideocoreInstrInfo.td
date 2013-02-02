//=== VideooreInstrInfo.td - Target Description for Videocore *- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the Videocore instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Instruction format superclass.
//===----------------------------------------------------------------------===//

include "VideocoreInstrFormats.td"

//===----------------------------------------------------------------------===//
// Videocore specific DAG Nodes.
//===----------------------------------------------------------------------===//

//  These are target-independent nodes, but have target-specific formats.
def SDT_VCCallSeqStart : SDCallSeqStart<[ SDTCisVT<0, i32> ]>;
def SDT_VCCallSeqEnd   : SDCallSeqEnd<[ SDTCisVT<0, i32>,
                                        SDTCisVT<1, i32> ]>;

def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_VCCallSeqStart,
                           [SDNPHasChain, SDNPOutGlue]>;
def callseq_end   : SDNode<"ISD::CALLSEQ_END",   SDT_VCCallSeqEnd,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;

def retflag       : SDNode<"VideocoreISD::RET_FLAG", SDTNone,
                               [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

//===----------------------------------------------------------------------===//
// Instruction Pattern Stuff
//===----------------------------------------------------------------------===//

def div4_xform : SDNodeXForm<imm, [{
  // Transformation function: imm/4
  assert(N->getZExtValue() % 4 == 0);
  return getI32Imm(N->getZExtValue()/4);
}]>;

def msksize_xform : SDNodeXForm<imm, [{
  // Transformation function: get the size of a mask
  assert(isMask_32(N->getZExtValue()));
  // look for the first non-zero bit
  return getI32Imm(32 - CountLeadingZeros_32(N->getZExtValue()));
}]>;

def neg_xform : SDNodeXForm<imm, [{
  // Transformation function: -imm
  uint32_t value = N->getZExtValue();
  return getI32Imm(-value);
}]>;

def immU5 : PatLeaf<(imm), [{
  return (uint32_t)N->getZExtValue() < (1 << 5);
}]>;

def u5imm   : Operand<i32> {
      let PrintMethod = "printU5ImmOperand";
}

def immU4 : PatLeaf<(imm), [{
  return (uint32_t)N->getZExtValue() < (1 << 4);
}]>;


def immU16 : PatLeaf<(imm), [{
  return (uint32_t)N->getZExtValue() < (1 << 16);
}]>;

def immSExt16  : PatLeaf<(imm), [{ return isInt<16>(N->getSExtValue()); }]>;

// Instruction operand types
def calltarget  : Operand<i32>;
def brtarget : Operand<OtherVT>;
def pclabel : Operand<i32>;

// Addressing modes.
def ADDRrr : ComplexPattern<i32, 2, "SelectADDRrr", [], []>;
def ADDRri : ComplexPattern<i32, 2, "SelectADDRri", [frameindex], []>;

// Address operands
let PrintMethod = "printMemOperand" in {
  def MEMrr : Operand<i32> {
    let MIOperandInfo = (ops IntReg, IntReg);
  }
  def MEMri : Operand<i32> {
    let MIOperandInfo = (ops IntReg, i32imm);
  }
  // For instructions that can only access the lower 16 registers
  def MEMqq : Operand<i32> {
    let MIOperandInfo = (ops LowReg, LowReg);
  }
  def MEMqi : Operand<i32> {
    let MIOperandInfo = (ops LowReg, i32imm);
  }

  def MEMq : Operand<i32> {
    let MIOperandInfo = (ops LowReg);
  }
}

// Jump tables.
def InlineJT : Operand<i32> {
  let PrintMethod = "printInlineJT";
}

def InlineJT32 : Operand<i32> {
  let PrintMethod = "printInlineJT32";
}

def addr : ComplexPattern<iPTR, 2, "SelectAddr", [frameindex], [SDNPWantParent]>;

//===----------------------------------------------------------------------===//
// Instruction Class Templates
//===----------------------------------------------------------------------===//


//===----------------------------------------------------------------------===//
// Pseudo Instructions
//===----------------------------------------------------------------------===//

class Pseudo<dag outs, dag ins, string asmstr, list<dag> pattern>
     : InstVC<0, outs, ins, asmstr, pattern> {
  let isCodeGenOnly = 1;
  let isPseudo = 1;
}

let Defs = [SP], Uses = [SP] in {
def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i32imm:$amt),
                               "!ADJCALLSTACKDOWN $amt",
                               [(callseq_start timm:$amt)]>;
def ADJCALLSTACKUP : Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                            "!ADJCALLSTACKUP $amt1",
                            [(callseq_end timm:$amt1, timm:$amt2)]>;
}

//===----------------------------------------------------------------------===//
// Instructions
//===----------------------------------------------------------------------===//

def LDWqq  : LDST16<0, 0, 
		(outs LowReg:$dst), (ins MEMq:$addr), "ld $dst, $addr",
		 [(set LowReg:$dst, (load ADDRrr:$addr))]>;

def LDBqq  : LDST16<1, 0, 
		(outs LowReg:$dst), (ins MEMq:$addr), "ldb $dst, $addr",
		 [(set LowReg:$dst, (zextloadi8 ADDRrr:$addr))]>;

def LDHqq  : LDST16<2, 0, 
		(outs LowReg:$dst), (ins MEMq:$addr), "ldh $dst, $addr",
		 [(set LowReg:$dst, (zextloadi16 ADDRrr:$addr))]>;

def LDHSqq : LDST16<3, 0, 
		(outs LowReg:$dst), (ins MEMq:$addr), "ldhs $dst, $addr",
		 [(set LowReg:$dst, (sextloadi16 ADDRrr:$addr))]>;

def STWqq  : LDST16<0, 1, 
		(outs), (ins LowReg:$src, MEMq:$addr), "st $src, $addr",
		 [(store LowReg:$src, ADDRrr:$addr)]>;

def STBqq  : LDST16<1, 1, 
		(outs), (ins LowReg:$src, MEMq:$addr), "stb $src, $addr",
                [(truncstorei8 LowReg:$src, ADDRrr:$addr)]>;

def STHqq  : LDST16<2, 1, 
		(outs), (ins LowReg:$src, MEMq:$addr), "sth $src, $addr",
                 [(truncstorei16 LowReg:$src, ADDRrr:$addr)]>;

def STHSqq : LDST16<3, 1, 
		(outs), (ins LowReg:$src, MEMqi:$addr), "sths $src, $addr",
                 [(truncstorei16 LowReg:$src, ADDRrr:$addr)]>;

def STWrri : InstVC32<(outs), (ins IntReg:$src, MEMri:$addr), "st $src, $addr",
        [(store IntReg:$src, ADDRri:$addr)]>;

//def MOVqq : ArithLogicQQ<0,
//        (outs LowReg:$dst), (ins LowReg:$src), "mov $dst, $src",
//        [(set LowReg:$dst, LowReg:$src)]>;

def MOVqi : ArithLogicQI<0,
        (outs LowReg:$dst), (ins u5imm:$imm), "mov $dst, $imm",
        [(set LowReg:$dst, (i32 imm:$imm))]>;

def MOVrr : ArithLogicRR<0,
        (outs IntReg:$dst), (ins IntReg:$ra), "mov $ra, $ra",
        [(set IntReg:$dst, IntReg:$ra)]>;


let isReturn=1, isTerminator=1, isCodeGenOnly=1,
        isBarrier=1, hasCtrlDep=1 in
    def BLR : InstVC16<(outs), (ins), "blr",
                [(retflag)]> {
        let Inst{15-0} = 0x5a;
}

//===----------------------------------------------------------------------===//
// Non-Instruction Patterns
//===----------------------------------------------------------------------===//


