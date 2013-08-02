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

def retflag       : SDNode<"VCISD::RET_FLAG", SDTNone,
                               [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// (ins NZCV, Condition, Dest)
def SDT_VCbr_cc : SDTypeProfile<0, 3, [SDTCisVT<0, i32>]>;
def VCbr_cc : SDNode<"VCISD::BR_CC", SDT_VCbr_cc, [SDNPHasChain]>;

// (outs NZCV), (ins LHS, RHS, Condition)
def SDT_VCsetcc : SDTypeProfile<1, 3, [SDTCisVT<0, i32>,
                                        SDTCisSameAs<1, 2>]>;
def VCsetcc : SDNode<"VCISD::SETCC", SDT_VCsetcc>;

def VCcmp : PatFrag<(ops node:$lhs, node:$rhs),
                    (VCsetcc node:$lhs, node:$rhs, cond)>;

// When matching a notional (CMP op1, (sub 0, op2)), we'd like to use a CMN
// instruction on the grounds that "op1 - (-op2) == op1 + op2". However, the C
// and V flags can be set differently by this operation. It comes down to
// whether "SInt(~op2)+1 == SInt(~op2+1)" (and the same for UInt). If they are
// then everything is fine. If not then the optimization is wrong. Thus general
// comparisons are only valid if op2 != 0.

// So, finally, the only LLVM-native comparisons that don't mention C and V are
// SETEQ and SETNE. They're the only ones we can safely use CMN for in the
// absence of information about op2.
def equality_cond : PatLeaf<(cond), [{
  return N->get() == ISD::SETEQ || N->get() == ISD::SETNE;
}]>;

def VCcmn : PatFrag<(ops node:$lhs, node:$rhs),
                     (VCsetcc node:$lhs, (sub 0, node:$rhs), equality_cond)>;

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

def immU5opnd : Operand<i32> {
      let PrintMethod = "printU5ImmOperand";
}

def immU6opnd : Operand<i32> {
      let PrintMethod = "printU6ImmOperand";
}

def immU4 : PatLeaf<(imm), [{
  return (uint32_t)N->getZExtValue() < (1 << 4);
}]>;


def immU16 : PatLeaf<(imm), [{
  return (uint32_t)N->getZExtValue() < (1 << 16);
}]>;

def immS6 : PatLeaf<(imm), [{ return isInt<6>(N->getSExtValue()); }]>;

def immS6opnd : Operand<i32> {
      let PrintMethod = "printSignedImmOperand";
}

def immS16 : PatLeaf<(imm), [{ return isInt<16>(N->getSExtValue()); }]>;

def immS16opnd : Operand<i32> {
      let PrintMethod = "printSignedImmOperand";
}

def immU32 : PatLeaf<(imm), [{ return isInt<32>(N->getZExtValue()); }]>;

def immU32opnd : Operand<i32> {
      let PrintMethod = "printU32ImmOperand";
}

def immSignedShl2 : Operand<i32> {
  let PrintMethod = "printSignedShl2Operand";
}

def cond_code_asmoperand : AsmOperandClass {
  let Name = "CondCode";
  let DiagnosticType = "CondCode";
}

def cond_code : Operand<i32>, ImmLeaf<i32, [{
  return Imm >= 0 && Imm <= 15;
}]> {
  let PrintMethod = "printCondCodeOperand";
  let ParserMatchClass = cond_code_asmoperand;
}

// Instruction operand types
def calltarget  : Operand<i32>;
def brtarget : Operand<OtherVT>;
def pclabel : Operand<i32>;

// Complex patterns
def BITi : ComplexPattern<i32, 1, "SelectBITi", [imm]>;
def NOTBITi : ComplexPattern<i32, 1, "SelectNOTBITi", [imm]>;
def MASKi : ComplexPattern<i32, 1, "SelectMASKi", [imm]>;
def NEGu5 : ComplexPattern<i32, 1, "SelectNEGu5", [imm]>;

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
    let DecoderMethod = "DecodeMEMri";
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
// Instruction format superclass.
//===----------------------------------------------------------------------===//

include "VideocoreInstrFormats.td"

//===----------------------------------------------------------------------===//
// Instruction Class Templates
//===----------------------------------------------------------------------===//

// Even numbered operations
multiclass ArithLogicE3<int opc, string asmstr, SDNode node> {
  let Constraints="$src = $Rd", DisableEncoding="$src" in {
  def qq : ArithLogicQQ<opc, (ins LowReg:$src, LowReg:$Rs), 
		!strconcat(asmstr, " $Rd, $Rs"),
        [(set LowReg:$Rd, (node LowReg:$src, LowReg:$Rs))]> {
            let isConvertibleToThreeAddress = 1;
		}
  def qi : ArithLogicQI<opc, (ins LowReg:$src, immU5opnd:$imm),
		!strconcat(asmstr, " $Rd, $imm"),
        [(set LowReg:$Rd, (node LowReg:$src, (i32 immU5:$imm)))]> {
            let isConvertibleToThreeAddress = 1;
		}
  def ri : ArithLogicRI<opc, (ins IntReg:$src, immS16opnd:$imm), 
		!strconcat(asmstr, " $Rd, $imm"),
		[(set IntReg:$Rd, (node IntReg:$src, (i32 immS16:$imm)))]>;
  def i48 : ArithLogic48<opc, (ins IntReg:$src, immU32opnd:$imm),
		!strconcat(asmstr, " $Rd, $imm"),
		[(set IntReg:$Rd, (node IntReg:$src, (i32 immU32:$imm)))]>;
  }
  def rr : ArithLogicRRR<opc, (ins IntReg:$Ra, IntReg:$Rb),
		!strconcat(asmstr, " $Rd, $Ra, $Rb"),
        [(set IntReg:$Rd, (node IntReg:$Ra, IntReg:$Rb))]>;
  def rri : ArithLogicRRI<opc, (ins IntReg:$Rs, immS6opnd:$imm), 
		!strconcat(asmstr, " $Rd, $Rs, $imm"),
		[(set IntReg:$Rd, (node IntReg:$Rs, (i32 immS6:$imm)))]>;
}

// Even numbered operations
multiclass ArithLogicE2<int opc, string asmstr, SDNode node> {
  def qq : ArithLogicQQ<opc, (ins LowReg:$Rs), 
		!strconcat(asmstr, " $Rd, $Rs"),
        [(set LowReg:$Rd, (node LowReg:$Rs))]>;
  def qi : ArithLogicQI<opc, (ins immU5opnd:$imm),
		!strconcat(asmstr, " $Rd, $imm"),
        [(set LowReg:$Rd, (node (i32 immU5:$imm)))]>;
  def ri : ArithLogicRI<opc, (ins immS16opnd:$imm), 
		!strconcat(asmstr, " $Rd, $imm"),
		[(set IntReg:$Rd, (node (i32 immS16:$imm)))]>;
  def i48 : ArithLogic48<opc, (ins immU32opnd:$imm),
		!strconcat(asmstr, " $Rd, $imm"),
		[(set IntReg:$Rd, (node (i32 immU32:$imm)))]>;
  def rr : ArithLogicRR<opc, (ins IntReg:$Ra),
		!strconcat(asmstr, " $Rd, $Ra"),
        [(set IntReg:$Rd, (node IntReg:$Ra))]>;
  def rri : ArithLogicRRI<opc, (ins IntReg:$Rs), 
        !strconcat(asmstr, " $Rd, $Rs"),
        [(set IntReg:$Rd, (node IntReg:$Rs))]>;
}

// Odd numbered operations
multiclass ArithLogicO3<int opc, string asmstr, SDNode node> {
  let Constraints="$src = $Rd", DisableEncoding="$src" in {
  def qq : ArithLogicQQ<opc, (ins LowReg:$src, LowReg:$Rs), 
		!strconcat(asmstr, " $Rd, $Rs"),
        [(set LowReg:$Rd, (node LowReg:$src, LowReg:$Rs))]> {
            let isConvertibleToThreeAddress = 1;
		}
  def ri : ArithLogicRI<opc, (ins IntReg:$src, immS16opnd:$imm), 
		!strconcat(asmstr, " $Rd, $imm"),
		[(set IntReg:$Rd, (node IntReg:$src, (i32 immS16:$imm)))]>;
  def i48 : ArithLogic48<opc, (ins IntReg:$src, immU32opnd:$imm),
		!strconcat(asmstr, " $Rd, $imm"),
		[(set IntReg:$Rd, (node IntReg:$src, (i32 immU32:$imm)))]>;
  }
  def rr : ArithLogicRRR<opc, (ins IntReg:$Ra, IntReg:$Rb),
		!strconcat(asmstr, " $Rd, $Ra, $Rb"),
        [(set IntReg:$Rd, (node IntReg:$Ra, IntReg:$Rb))]>;
  def rri : ArithLogicRRI<opc, (ins IntReg:$Rs, immS6opnd:$imm), 
		!strconcat(asmstr, " $Rd, $Rs, $imm"),
		[(set IntReg:$Rd, (node IntReg:$Rs, (i32 immS6:$imm)))]>;
}

// Add Scale operations
multiclass AddScale<int opc, int shift> {
  let Constraints="$src = $Rd", DisableEncoding="$src" in {
  def qq : ArithLogicQQ<opc, (ins LowReg:$src, LowReg:$Rs), 
		"addscale $Rd, $Rs shl "#shift,
        [(set LowReg:$Rd, (add LowReg:$src, (shl LowReg:$Rs, shift)))]> {
            let isConvertibleToThreeAddress = 1;
		}
  def ri : ArithLogicRI<opc, (ins IntReg:$src, immS16opnd:$imm), 
		"addscale $Rd, $imm shl "#shift,
		[(set IntReg:$Rd, (add IntReg:$src, (shl (i32 immS16:$imm), shift)))]>;
  def i48 : ArithLogic48<opc, (ins IntReg:$src, immU32opnd:$imm),
		"addscale $Rd, $imm shl "#shift,
		[(set IntReg:$Rd, (add IntReg:$src, (shl (i32 immU32:$imm), shift)))]>;
  }
  def rr : ArithLogicRRR<opc, (ins IntReg:$Ra, IntReg:$Rb),
		"addscale $Rd, $Ra, $Rb shl "#shift,
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl IntReg:$Rb, shift)))]>;
  def rri : ArithLogicRRI<opc, (ins IntReg:$Rs, immS6opnd:$imm), 
		"addscale $Rd, $Rs, $imm shl "#shift,
		[(set IntReg:$Rd, (add IntReg:$Rs, (shl (i32 immS6:$imm), shift)))]>;
}


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

def B32 : InstVC32<(outs), (ins brtarget:$imm24), 
		"b $imm24", [(br bb:$imm24)]> {
	bits<24> imm24;

	let Inst{31-28} = 9;
	let Inst{27-24} = 0xe;
	let Inst{23} = 0;
	let Inst{22-0} = imm24{23-1};

	let isBranch=1;
	let isTerminator=1;
	let isBarrier=1;
	let hasDelaySlot=0;
}

def bcc : InstVC32<(outs), 
		(ins cond_code:$Cond, brtarget:$imm24), 
		"b$Cond $imm24", [(VCbr_cc NZCV, (i32 imm:$Cond), bb:$imm24)]> {
	bits<24> imm24;
    bits<4> Cond;

	let Inst{31-28} = 9;
	let Inst{27-24} = Cond;
	let Inst{23} = 0;
	let Inst{22-0} = imm24{23-1};

	let Uses = [NZCV];
	let isBranch=1;
	let isTerminator=1;
	let hasDelaySlot=0;
    let isPredicable=1;
}


def CMPqq : InstVC16<(outs), (ins LowReg:$Rd, LowReg:$Rs), "cmp $Rd, $Rs",
	[(set NZCV, (VCcmp LowReg:$Rd, LowReg:$Rs))]> {
	bits<4> Rd;
	bits<4> Rs;

	let Inst{15-13} = 2;
	let Inst{12-8} = 0xa;
	let Inst{7-4} = Rs;
	let Inst{3-0} = Rd;
	let isCommutable=1;
    let Defs = [NZCV];
}

def CMPqi : InstVC16<(outs), (ins LowReg:$Ra, immU5opnd:$imm), "cmp $Ra, $imm",
	[(set NZCV, (VCcmp LowReg:$Ra, immU5:$imm))]> {
	bits<4> Ra;
	bits<5> imm;

	let Inst{15-13} = 3;
	let Inst{12-9} = 0x5;
	let Inst{8-4} = imm;
	let Inst{3-0} = Ra;
    let Defs = [NZCV];
}


def CMPrr : InstVC32<(outs), (ins IntReg:$Ra, IntReg:$Rb), "cmp $Ra, $Rb",
	[(set NZCV, (VCcmp IntReg:$Ra, IntReg:$Rb))]> {
	bits<5> Ra;
	bits<5> Rb;

	let Inst{31-26} = 0b110000;
	let Inst{25-21} = 0xa;
	let Inst{15-11} = Ra;
	let Inst{10-7} = 0xe;
	let Inst{4-0} = Rb;
	let isCommutable=1;
    let Defs = [NZCV];
}

def CMPri : InstVC32<(outs), (ins IntReg:$Ra, immS16opnd:$imm), "cmp $Ra, $imm",
	[(set NZCV, (VCcmp IntReg:$Ra, immS16:$imm))]> {
	bits<5> Ra;
	bits<16> imm;

	let Inst{31-26} = 0b101100;
	let Inst{25-21} = 0xa;
	let Inst{20-16} = Ra;
	let Inst{15-0} = imm;
	let Defs = [NZCV];
}


/*
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
*/

def STWrri : InstVC32<(outs), (ins IntReg:$src, MEMri:$addr), "st $src, $addr",
        [(store IntReg:$src, ADDRri:$addr)]> {
    bits<5> Rd;
    bits<5> Rs;
    bits<12> offset;

    let Inst{31-25} = 0x51;
    let Inst{24} = offset{11};
    let Inst{23-21} = 1;
    let Inst{20-16} = Rd;
    let Inst{15-11} = Rs;
    let Inst{10-0} = offset{10-0};

    let DecoderMethod = "DecodeMem_5_12";
}

def LDWrri : InstVC32<(outs IntReg:$dst), (ins MEMri:$addr), "ld $dst, $addr",
        [(set IntReg:$dst, (load ADDRri:$addr))]> {
    bits<5> Rd;
    bits<5> Rs;
    bits<12> offset;

    let Inst{31-25} = 0x51;
    let Inst{24} = offset{11};
    let Inst{23-21} = 0;
    let Inst{20-16} = Rd;
    let Inst{15-11} = Rs;
    let Inst{10-0} = offset{10-0};

    let DecoderMethod = "DecodeMem_5_12";
}


// Move
def MOVqq : ArithLogicQQ<0, (ins LowReg:$Rs), "mov $Rd, $Rs",
        []>;
def MOVrr : ArithLogicRR<0, (ins IntReg:$Ra), "mov $Rd, $Ra",
        []>;
let isMoveImm=1 in {
  def MOVqi : ArithLogicQI<0, (ins immU5opnd:$imm), "mov $Rd, $imm",
        [(set LowReg:$Rd, (i32 immU5:$imm))]>;
  def MOVri : ArithLogicRI<0, (ins immS16opnd:$imm), "mov $Rd, $imm",
		[(set IntReg:$Rd, (i32 immS16:$imm))]>;
  def MOVrri : ArithLogicRRI<0, (ins immS6opnd:$imm), "mov $Rd, $imm",
		[(set IntReg:$Rd, (i32 immS6:$imm))]>;
  def MOVi48 : ArithLogic48<0, (ins immU32opnd:$imm), "mov $Rd, $imm",
		[(set IntReg:$Rd, (i32 immU32:$imm))]>;
}

// 1 - CMN

defm ADD  : ArithLogicO3<2, "add", add>;

// There are a few extra add instructions

// add Rd, Rs, imm32
// 1110 11ss sssd dddd uuuu uuuu uuuu uuuu uuuu uuuu uuuu uuuu
def ADDrri48 : InstVC48<(outs IntReg:$Rd), (ins IntReg:$Rs, immU32opnd:$imm),
        "add $Rd, $Rs, $imm",
        [(set IntReg:$Rd, (add IntReg:$Rs, immU32:$imm))]> {
  bits<5> Rd;
  bits<5> Rs;
  bits<32> imm;
  let Inst{47-42} = 0b111011;
  let Inst{41-37} = Rs;
  let Inst{36-32} = Rd;
  let Inst{31-0} = imm;
}

// 0001 0ooo oood dddd   -   add Rd, sp, immS6*4
def ADDrSPi : InstVC16<(outs IntReg:$Rd), (ins immSignedShl2:$imm),
        "add $Rd, sp, $imm",
        [(set IntReg:$Rd, (add SP, (shl immS6:$imm, 2)))]> {
  bits<5> Rd;
  bits<6> imm;
  let Inst{15-11} = 2;
  let Inst{10-5} = imm;
  let Inst{4-0} = Rd;

  let Uses = [SP];
}

// 1011 01ss sssd dddd iiii iiii iiii iiii 
// Also does pc reltive lea
def ADDrri16 : InstVC32<(outs IntReg:$Rd), (ins AllReg:$Rs, immS16opnd:$imm),
        "add $Rd, $Rs, $imm",
        [(set IntReg:$Rd, (add AllReg:$Rs, (i32 immS16:$imm)))]> {
  bits<5> Rd;
  bits<5> Rs;
  bits<16> imm;
  let Inst{31-26} = 0b101101;
  let Inst{25-21} = Rs;
  let Inst{20-16} = Rd;
  let Inst{15-0} = imm;
}

// 1110 0101 000d dddd oooo oooo oooo oooo oooo oooo oooo oooo
// AKA lea
def ADDrPCi48 : InstVC48<(outs IntReg:$Rd), (ins immU32opnd:$imm),
        "add $Rd, pc, $imm",
        [(set IntReg:$Rd, (add PC, (i32 immU32:$imm)))]> {
  bits<5> Rd;
  bits<32> imm;
  let Inst{47-37} = 0b11100101000;
  let Inst{36-32} = Rd;
  let Inst{31-0} = imm;

  let Uses = [PC];
}


let Constraints="$src = $Rd", DisableEncoding="$src" in {
  let isConvertibleToThreeAddress = 1 in
  def BICqq : ArithLogicQQ<3, (ins LowReg:$src, LowReg:$Rs), 
		"bic $Rd, $Rs",
        [(set LowReg:$Rd, (and LowReg:$src, (xor LowReg:$Rs, -1)))]>;
  def BICri : ArithLogicRI<3, (ins IntReg:$src, immS16opnd:$imm), 
		"bic $Rd, $imm",
		[(set IntReg:$Rd, (and IntReg:$src, (xor (i32 immS16:$imm), -1)))]>;
  def BICi48 : ArithLogic48<3, (ins IntReg:$src, immU32opnd:$imm),
		"bic $Rd, $imm",
		[(set IntReg:$Rd, (and IntReg:$src, (xor (i32 immU32:$imm), -1)))]>;
}
def BICrr : ArithLogicRRR<3, (ins IntReg:$Ra, IntReg:$Rb),
		"bic $Rd, $Ra, $Rb",
        [(set IntReg:$Rd, (and IntReg:$Ra, (xor IntReg:$Rb, -1)))]>;
def BICrri : ArithLogicRRI<3, (ins IntReg:$Rs, immS6opnd:$imm),
		"bic $Rd, $Rs, $imm",
        [(set IntReg:$Rd, (and IntReg:$Rs, (xor (i32 immS6:$imm), -1)))]>;


defm MUL  : ArithLogicE3<4, "mul", mul>;
defm XOR  : ArithLogicO3<5, "xor", xor>;
defm SUB  : ArithLogicO3<6, "sub", sub>; // use O3, so SUBqi isn't created

// llvm prefers adding negitave constants instead of using our smaller sub.
// So we override SUBqi to match additions with small negitave numbers
let Constraints="$src = $Rd", DisableEncoding="$src" in
def SUBqi : ArithLogicQI<6, (ins LowReg:$src, immU5opnd:$imm),
		"sub $Rd, $imm",
        [(set LowReg:$Rd, (add LowReg:$src, NEGu5:$imm))]>;

defm AND  : ArithLogicO3<7, "and", and>;

def NOTqq : ArithLogicQQ<8, (ins LowReg:$Rs), "not $Rd, $Rs",
		[(set LowReg:$Rd, (xor LowReg:$Rs, -1))]>;
def NOTrr : ArithLogicRR<8, (ins IntReg:$Ra), "not $Rd, $Ra",
		[(set IntReg:$Rd, (xor IntReg:$Ra, -1))]>;
def NOTqi : ArithLogicQI<8, (ins immU5opnd:$imm), "not $Rd, $imm",
		[(set LowReg:$Rd, (xor (i32 immU5:$imm), -1))]>;
def NOTri : ArithLogicRI<8, (ins immS16opnd:$imm), "not $Rd, $imm",
		[(set IntReg:$Rd, (xor (i32 immS16:$imm), -1))]>;
def NOTrri : ArithLogicRRI<8, (ins immS6opnd:$imm), "not $Rd, $imm",
		[(set IntReg:$Rd, (xor (i32 immS6:$imm), -1))]>;
def NOTi48 : ArithLogic48<8, (ins immU32opnd:$imm), "not $Rd, $imm",
		[(set IntReg:$Rd, (xor (i32 immU32:$imm), -1))]>;

defm ROR  : ArithLogicO3<9, "ror", rotr>;

// 10 - CMP

let Constraints="$src = $Rd", DisableEncoding="$src" in {
  let isConvertibleToThreeAddress = 1 in
  def RSUBqq : ArithLogicQQ<11, (ins LowReg:$src, LowReg:$Rs), 
		"rsub $Rd, $Rs",
        [(set LowReg:$Rd, (sub LowReg:$Rs, LowReg:$src))]>;
  def RSUBri : ArithLogicRI<11, (ins IntReg:$src, immS16opnd:$imm), 
		"rsub $Rd, $imm",
		[(set IntReg:$Rd, (sub (i32 immS16:$imm), IntReg:$src))]>;
  def RSUBi48 : ArithLogic48<11, (ins IntReg:$src, immU32opnd:$imm),
		"rsub $Rd, $imm",
		[(set IntReg:$Rd, (sub (i32 immU32:$imm), IntReg:$src))]>;
}
def RSUBrr : ArithLogicRRR<11, (ins IntReg:$Ra, IntReg:$Rb),
		"rsub $Rd, $Ra, $Rb",
        [(set IntReg:$Rd, (sub IntReg:$Rb, IntReg:$Ra))]>;
def RSUBrri : ArithLogicRRI<11, (ins IntReg:$Rs, immS6opnd:$imm),
		"rsub $Rd, $Rs, $imm",
        [(set IntReg:$Rd, (sub (i32 immS16:$imm), IntReg:$Rs))]>;

// 12 - BTST

defm OR   : ArithLogicO3<13, "or", or>;

let Constraints="$src = $Rd", DisableEncoding="$src" in {
  let isConvertibleToThreeAddress = 1 in {
  def BMASKqq : ArithLogicQQ<14, (ins LowReg:$src, LowReg:$Rs), 
		"bmask $Rd, $Rs",
        [(set LowReg:$Rd, (and LowReg:$src, (add (shl 1, LowReg:$Rs), -1)))]>;
  def BMASKqi : ArithLogicQI<14, (ins LowReg:$src, immU5opnd:$imm),
		"bmask $Rd, $imm",
        [(set LowReg:$Rd, (and LowReg:$src, MASKi:$imm))]>;
  }
  def BMASKri : ArithLogicRI<14, (ins IntReg:$src, immS16opnd:$imm), 
		"bmask $Rd, $imm",
		[(set IntReg:$Rd, (and IntReg:$src, MASKi:$imm))]>;
  def BMASKi48 : ArithLogic48<14, (ins IntReg:$src, immU32opnd:$imm), // useless
		"bmask $Rd, $imm",
		[(set IntReg:$Rd, (and IntReg:$src, MASKi:$imm))]>;
}
def BMASKrr : ArithLogicRRR<14, (ins IntReg:$Ra, IntReg:$Rb),
		"bmask $Rd, $Ra, $Rb",
        [(set IntReg:$Rd, (and IntReg:$Ra, (add (shl 1, IntReg:$Rb), -1)))]>;
def BMASKrri : ArithLogicRRI<14, (ins IntReg:$Rs, immS6opnd:$imm),
		"bmask $Rd, $Rs, $imm",
        [(set IntReg:$Rd, (and IntReg:$Rs, MASKi:$imm))]>;

// MAX -- FIXME: no codegen
let Constraints="$src = $Rd", DisableEncoding="$src" in {
  let isConvertibleToThreeAddress = 1 in
  def MAXqq : ArithLogicQQ<15, (ins LowReg:$src, LowReg:$Rs), 
		"max $Rd, $Rs",
        []>;
  def MAXri : ArithLogicRI<15, (ins IntReg:$src, immS16opnd:$imm), 
		"max $Rd, $imm",
		[]>;
  def MAXi48 : ArithLogic48<15, (ins IntReg:$src, immU32opnd:$imm),
		"max $Rd, $imm",
		[]>;
}
def MAXrr : ArithLogicRRR<15, (ins IntReg:$Ra, IntReg:$Rb),
		"max $Rd, $Ra, $Rb",
        []>;
def MAXrri : ArithLogicRRI<15, (ins IntReg:$Rs, immS6opnd:$imm),
		"max $Rd, $Rs, $imm",
        []>;


let Constraints="$src = $Rd", DisableEncoding="$src" in {
  let isConvertibleToThreeAddress = 1 in {
  def BSETqq : ArithLogicQQ<16, (ins LowReg:$src, LowReg:$Rs), 
		"bset $Rd, $Rs",
        [(set LowReg:$Rd, (or LowReg:$src, (shl 1, LowReg:$Rs)))]>;
  def BSETqi : ArithLogicQI<16, (ins LowReg:$src, immU5opnd:$imm),
		"bset $Rd, $imm",
        [(set LowReg:$Rd, (or LowReg:$src, BITi:$imm))]>;
  }
  def BSETri : ArithLogicRI<16, (ins IntReg:$src, immS16opnd:$imm), 
		"bset $Rd, $imm",
		[(set IntReg:$Rd, (or IntReg:$src, BITi:$imm))]>;
  def BSETi48 : ArithLogic48<16, (ins IntReg:$src, immU32opnd:$imm), // useless
		"bset $Rd, $imm",
		[(set IntReg:$Rd, (or IntReg:$src, BITi:$imm))]>;
}
def BSETrr : ArithLogicRRR<16, (ins IntReg:$Ra, IntReg:$Rb),
		"bset $Rd, $Ra, $Rb",
        [(set IntReg:$Rd, (or IntReg:$Ra, (shl 1, IntReg:$Rb)))]>;
def BSETrri : ArithLogicRRI<16, (ins IntReg:$Rs, immS6opnd:$imm), 
		"bset $Rd, $Rs, $imm",
		[(set IntReg:$Rd, (and IntReg:$Rs, BITi:$imm))]>;

// MIN -- FIXME: no codegen
let Constraints="$src = $Rd", DisableEncoding="$src" in {
  let isConvertibleToThreeAddress = 1 in
  def MINqq : ArithLogicQQ<17, (ins LowReg:$src, LowReg:$Rs), 
		"min $Rd, $Rs",
        []>;
  def MINri : ArithLogicRI<17, (ins IntReg:$src, immS16opnd:$imm), 
		"min $Rd, $imm",
		[]>;
  def MINi48 : ArithLogic48<17, (ins IntReg:$src, immU32opnd:$imm),
		"min $Rd, $imm",
		[]>;
}
def MINrr : ArithLogicRRR<17, (ins IntReg:$Ra, IntReg:$Rb),
		"min $Rd, $Ra, $Rb",
        []>;
def MINrri : ArithLogicRRI<17, (ins IntReg:$Rs, immS6opnd:$imm),
		"min $Rd, $Rs, $imm",
        []>;


let Constraints="$src = $Rd", DisableEncoding="$src" in {
  let isConvertibleToThreeAddress = 1 in {
  def BCLRqq : ArithLogicQQ<18, (ins LowReg:$src, LowReg:$Rs), 
		"bclr $Rd, $Rs",
        [(set LowReg:$Rd, (and LowReg:$src, (xor (shl 1, LowReg:$Rs), -1)))]>;
  def BCLRqi : ArithLogicQI<18, (ins LowReg:$src, immU5opnd:$imm),
		"bclr $Rd, $imm",
        [(set LowReg:$Rd, (and LowReg:$src, NOTBITi:$imm))]>;
  }
  def BCLRri : ArithLogicRI<18, (ins IntReg:$src, immS16opnd:$imm), 
		"bclr $Rd, $imm",
		[(set IntReg:$Rd, (and IntReg:$src, NOTBITi:$imm))]>;
  def BCLRi48 : ArithLogic48<18, (ins IntReg:$src, immU32opnd:$imm), // useless
		"bclr $Rd, $imm",
		[(set IntReg:$Rd, (and IntReg:$src, NOTBITi:$imm))]>;
}
def BCLRrr : ArithLogicRRR<18, (ins IntReg:$Ra, IntReg:$Rb),
		"bclr $Rd, $Ra, $Rb",
        [(set IntReg:$Rd, (and IntReg:$Ra, (xor (shl 1, IntReg:$Rb), -1)))]>;
def BCLRrri : ArithLogicRRI<18, (ins IntReg:$Rs, immS6opnd:$imm), 
		"bclr $Rd, $Rs, $imm",
		[(set IntReg:$Rd, (and IntReg:$Rs, NOTBITi:$imm))]>;

defm ADDSCALE_1 : AddScale<19, 1>;

let Constraints="$src = $Rd", DisableEncoding = "$src" in {
  let isConvertibleToThreeAddress = 1 in {
  def BCHGqq : ArithLogicQQ<20, (ins LowReg:$src, LowReg:$Rs), 
		"bchg $Rd, $Rs",
        [(set LowReg:$Rd, (xor LowReg:$src, (shl 1, LowReg:$Rs)))]>;
  def BCHGqi : ArithLogicQI<20, (ins LowReg:$src, immU5opnd:$imm),
		"bchg $Rd, $imm",
        [(set LowReg:$Rd, (xor LowReg:$src, BITi:$imm))]>;
  }
  def BCHGri : ArithLogicRI<20, (ins IntReg:$src, immS16opnd:$imm), 
		"bchg $Rd, $imm",
		[(set IntReg:$Rd, (xor IntReg:$src, BITi:$imm))]>;
  def BCHGi48 : ArithLogic48<20, (ins IntReg:$src, immU32opnd:$imm), // useless
		"bchg $Rd, $imm",
		[(set IntReg:$Rd, (xor IntReg:$src, BITi:$imm))]>;
}
def BCHGrr : ArithLogicRRR<20, (ins IntReg:$Ra, IntReg:$Rb),
		"bchg $Rd, $Ra, $Rb",
        [(set IntReg:$Rd, (xor IntReg:$Ra, (shl 1, IntReg:$Rb)))]>;
def BCHGrri : ArithLogicRRI<20, (ins IntReg:$Rs, immS6opnd:$imm), 
		"bchg $Rd, $Rs, $imm",
		[(set IntReg:$Rd, (xor IntReg:$Rs, BITi:$imm))]>;

defm ADDSCALE_2 : AddScale<21, 2>;
defm ADDSCALE_3 : AddScale<22, 3>;

// Since AddScale 3 has an even opcode, it gets an extra instruction
def ADDSCALE_3qi : ArithLogicQI<22, (ins LowReg:$src, immS16opnd:$imm), 
		"addscale $Rd, $imm shl 3",
		[(set LowReg:$Rd, (add LowReg:$src, (shl (i32 immS16:$imm), 3)))]> {
  let Constraints = "$src = $Rd";
  let DisableEncoding = "$src";
  let isConvertibleToThreeAddress = 1;
}

defm ADDSCALE_4 : AddScale<23, 4>;

// SIGNEXT -- FIXME: no codegen
let Constraints="$src = $Rd", DisableEncoding="$src" in {
  let isConvertibleToThreeAddress = 1 in
  def SIGNEXTqq : ArithLogicQQ<24, (ins LowReg:$src, LowReg:$Rs), 
		"signext $Rd, $Rs",
        []>;
  def SIGNEXTri : ArithLogicRI<24, (ins IntReg:$src, immS16opnd:$imm), 
		"signext $Rd, $imm",
		[]>;
  def SIGNEXTi48 : ArithLogic48<24, (ins IntReg:$src, immU32opnd:$imm),
		"signext $Rd, $imm",
		[]>;
}
def SIGNEXTrr : ArithLogicRRR<24, (ins IntReg:$Ra, IntReg:$Rb),
		"signext $Rd, $Ra, $Rb",
        []>;
def SIGNEXTrri : ArithLogicRRI<24, (ins IntReg:$Rs, immS6opnd:$imm),
		"signext $Rd, $Rs, $imm",
        []>;

// Negate
def NEGqq : ArithLogicQQ<25, (ins LowReg:$Rs), "neg $Rd, $Rs",
		[(set LowReg:$Rd, (sub 0, LowReg:$Rs))]>;
def NEGrr : ArithLogicRR<25, (ins IntReg:$Ra), "neg $Rd, $Ra",
		[(set IntReg:$Rd, (sub 0, IntReg:$Ra))]>;
def NEGqi : ArithLogicQI<25, (ins immU5opnd:$imm), "neg $Rd, $imm",
		[(set LowReg:$Rd, (sub 0, (i32 immU5:$imm)))]>;
def NEGri : ArithLogicRI<25, (ins immS16opnd:$imm), "neg $Rd, $imm",
		[(set IntReg:$Rd, (sub 0, (i32 immS16:$imm)))]>;
def NEGrri : ArithLogicRRI<25, (ins immS6opnd:$imm), "neg $Rd, $imm",
		[(set IntReg:$Rd, (sub 0, (i32 immS6:$imm)))]>;
def NEGi48 : ArithLogic48<25, (ins immU32opnd:$imm), "neg $Rd, $imm",
		[(set IntReg:$Rd, (sub 0, (i32 immU32:$imm)))]>;

defm LSR  : ArithLogicE3<26, "lsr", srl>;

// MSB -- FIXME: no codegen
let Constraints="$src = $Rd", DisableEncoding="$src" in {
  let isConvertibleToThreeAddress = 1 in
  def MSBqq : ArithLogicQQ<27, (ins LowReg:$src, LowReg:$Rs), 
		"msb $Rd, $Rs",
        []>;
  def MSBri : ArithLogicRI<27, (ins IntReg:$src, immS16opnd:$imm), 
		"msb $Rd, $imm",
		[]>;
  def MSBi48 : ArithLogic48<27, (ins IntReg:$src, immU32opnd:$imm),
		"msb $Rd, $imm",
		[]>;
}
def MSBrr : ArithLogicRRR<27, (ins IntReg:$Ra, IntReg:$Rb),
		"msb $Rd, $Ra, $Rb",
        []>;
def MSBrri : ArithLogicRRI<27, (ins IntReg:$Rs, immS6opnd:$imm),
		"msb $Rd, $Rs, $imm",
        []>;


defm SHL  : ArithLogicE3<28, "shl", shl>;

// BITREV -- FIXME: no codegen
let Constraints="$src = $Rd", DisableEncoding="$src" in {
  let isConvertibleToThreeAddress = 1 in
  def BITREVqq : ArithLogicQQ<29, (ins LowReg:$src, LowReg:$Rs), 
		"bitrev $Rd, $Rs",
        []>;
  def BITREVri : ArithLogicRI<29, (ins IntReg:$src, immS16opnd:$imm), 
		"bitrev $Rd, $imm",
		[]>;
  def BITREVi48 : ArithLogic48<29, (ins IntReg:$src, immU32opnd:$imm),
		"bitrev $Rd, $imm",
		[]>;
}
def BITREVrr : ArithLogicRRR<29, (ins IntReg:$Ra, IntReg:$Rb),
		"bitrev $Rd, $Ra, $Rb",
        []>;
def BITREVrri : ArithLogicRRI<29, (ins IntReg:$Rs, immS6opnd:$imm),
		"bitrev $Rd, $Rs, $imm",
        []>;

defm ASR  : ArithLogicE3<30, "asr", sra>;

// ASB -- FIXME: no codegen
let Constraints="$src = $Rd", DisableEncoding="$src" in {
  let isConvertibleToThreeAddress = 1 in
  def ASBqq : ArithLogicQQ<31, (ins LowReg:$src, LowReg:$Rs), 
		"asb $Rd, $Rs",
        []>;
  def ASBri : ArithLogicRI<31, (ins IntReg:$src, immS16opnd:$imm), 
		"asb $Rd, $imm",
		[]>;
  def ASBi48 : ArithLogic48<31, (ins IntReg:$src, immU32opnd:$imm),
		"asb $Rd, $imm",
		[]>;
}
def ASBrr : ArithLogicRRR<31, (ins IntReg:$Ra, IntReg:$Rb),
		"asb $Rd, $Ra, $Rb",
        []>;
def ASBrri : ArithLogicRRI<31, (ins IntReg:$Rs, immS6opnd:$imm),
		"asb $Rd, $Rs, $imm",
        []>;

// Conditional Multiply Instructions  FIXME: no codegen
// TODO: put dots back in name see: 
// https://llvm.org/viewvc/llvm-project?view=revision&revision=186388
def MULHDSSrrr : RRR<0b1000100000, "mulhdss $Rd, $Ra, $Rb", []>; 
def MULHDSSrri : RRI<0b1000100000, "mulhdss $Rd, $Ra, $imm", []>;
def MULHDSUrrr : RRR<0b1000100001, "mulhdsu $Rd, $Ra, $Rb", []>;
def MULHDSUrri : RRI<0b1000100001, "mulhdsu $Rd, $Ra, $imm", []>;
def MULHDUSrrr : RRR<0b1000100010, "mulhdus $Rd, $Ra, $Rb", []>;
def MULHDUSrri : RRI<0b1000100010, "mulhdus $Rd, $Ra, $imm", []>;
def MULHDUUrrr : RRR<0b1000100011, "mulhduu $Rd, $Ra, $Rb", []>;
def MULHDUUrri : RRI<0b1000100011, "mulhduu $Rd, $Ra, $imm", []>;

// Conditional Divide Instructions   FIXME: no codegen
def DIVSSrrr : RRR<0b1000100100, "divss $Rd, $Ra, $Rb", []>;
def DIVSSrri : RRI<0b1000100100, "divss $Rd, $Ra, $imm", []>;
def DIVSUrrr : RRR<0b1000100101, "divsu $Rd, $Ra, $Rb", []>;
def DIVSUrri : RRI<0b1000100101, "divsu $Rd, $Ra, $imm", []>;
def DIVUSrrr : RRR<0b1000100110, "divus $Rd, $Ra, $Rb", []>;
def DIVUSrri : RRI<0b1000100110, "divus $Rd, $Ra, $imm", []>;
def DIVUUrrr : RRR<0b1000100111, "divuu $Rd, $Ra, $Rb", []>;
def DIVUUrri : RRI<0b1000100111, "divuu $Rd, $Ra, $imm", []>;


// Additional Conditional Arithmetic and Logical Operations
// no codegen (intrinsics?)
def ADDSrrr : RRR<0b1000101000, "adds $Rd, $Ra, $Rb", []>;
def ADDSrri : RRI<0b1000101000, "adds $Rd, $Ra, $imm", []>;

def SUBSrrr : RRR<0b1000101001, "subs $Rd, $Ra, $Rb", []>;
def SUBSrri : RRI<0b1000101001, "subs $Rd, $Ra, $imm", []>;

def SHLSrrr : RRR<0b1000101010, "shls $Rd, $Ra, $Rb", []>;
def SHLSrri : RRI<0b1000101010, "shls $Rd, $Ra, $imm", []>;

def CLAMP16r_r : R_R<0b1000101011, "clamp16 $Rd, $Rb", []>;
def CLAMP16r_i : R_I<0b1000101011, "clamp16 $Rd, $imm", []>;

def COUNTr_r : R_R<0b1000110000, "count $Rd, $Rb", []>;
def COUNTr_i : R_I<0b1000110000, "count $Rd, $imm", []>;

// Additional Addscale opcodes
def ADDSCALE_5rrr : RRR<0b1000101100, "addscale $Rd, $Ra, $Rb shl 5",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl IntReg:$Rb, 5)))]>;
def ADDSCALE_6rrr : RRR<0b1000101101, "addscale $Rd, $Ra, $Rb shl 6",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl IntReg:$Rb, 6)))]>;
def ADDSCALE_7rrr : RRR<0b1000101110, "addscale $Rd, $Ra, $Rb shl 7",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl IntReg:$Rb, 7)))]>;
def ADDSCALE_8rrr : RRR<0b1000101111, "addscale $Rd, $Ra, $Rb shl 8",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl IntReg:$Rb, 8)))]>;

def ADDSCALE_5rri : RRI<0b1000101100, "addscale $Rd, $Ra, $imm shl 5",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl immS6:$imm, 5)))]>;
def ADDSCALE_6rri : RRI<0b1000101101, "addscale $Rd, $Ra, $imm shl 6",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl immS6:$imm, 6)))]>;
def ADDSCALE_7rri : RRI<0b1000101110, "addscale $Rd, $Ra, $imm shl 7",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl immS6:$imm, 7)))]>;
def ADDSCALE_8rri : RRI<0b1000101111, "addscale $Rd, $Ra, $imm shl 8",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl immS6:$imm, 8)))]>;

// Subscale opcodes
def SUBSCALE_1rrr : RRR<0b1000110001, "subscale $Rd, $Ra, $Rb shl 1",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 1)))]>;
def SUBSCALE_2rrr : RRR<0b1000110010, "subscale $Rd, $Ra, $Rb shl 2",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 2)))]>;
def SUBSCALE_3rrr : RRR<0b1000110011, "subscale $Rd, $Ra, $Rb shl 3",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 3)))]>;
def SUBSCALE_4rrr : RRR<0b1000110100, "subscale $Rd, $Ra, $Rb shl 4",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 4)))]>;
def SUBSCALE_5rrr : RRR<0b1000110101, "subscale $Rd, $Ra, $Rb shl 5",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 5)))]>;
def SUBSCALE_6rrr : RRR<0b1000110110, "subscale $Rd, $Ra, $Rb shl 6",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 6)))]>;
def SUBSCALE_7rrr : RRR<0b1000110111, "subscale $Rd, $Ra, $Rb shl 7",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 7)))]>;
def SUBSCALE_8rrr : RRR<0b1000111000, "subscale $Rd, $Ra, $Rb shl 8",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 8)))]>;

def SUBSCALE_1rri : RRI<0b1000110001, "subscale $Rd, $Ra, $imm shl 1",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 1)))]>;
def SUBSCALE_2rri : RRI<0b1000110010, "subscale $Rd, $Ra, $imm shl 2",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 2)))]>;
def SUBSCALE_3rri : RRI<0b1000110011, "subscale $Rd, $Ra, $imm shl 3",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 3)))]>;
def SUBSCALE_4rri : RRI<0b1000110100, "subscale $Rd, $Ra, $imm shl 4",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 4)))]>;
def SUBSCALE_5rri : RRI<0b1000110101, "subscale $Rd, $Ra, $imm shl 5",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 5)))]>;
def SUBSCALE_6rri : RRI<0b1000110110, "subscale $Rd, $Ra, $imm shl 6",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 6)))]>;
def SUBSCALE_7rri : RRI<0b1000110111, "subscale $Rd, $Ra, $imm shl 7",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 7)))]>;
def SUBSCALE_8rri : RRI<0b1000111000, "subscale $Rd, $Ra, $imm shl 8",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 8)))]>;




let isReturn=1, isTerminator=1, isBarrier=1, hasCtrlDep=1, isCodeGenOnly=1 in
    def BLR : InstVC16<(outs), (ins), "blr",
                [(retflag)]> {
        let Inst{15-0} = 0x5a;
}

// Utility Instructions

let hasSideEffects = 1 in {
  def BKPT : InstVC16<(outs), (ins), "bkpt", []> {
    let Inst{15-0} = 0x0000;
    let isTerminator = 1;
  }
  def NOP : InstVC16<(outs), (ins), "nop", []> {
    let Inst{15-0} = 0x0001;
    let hasSideEffects = 0;
  }
  def SLEEP : InstVC16<(outs), (ins), "sleep", []> {
    let Inst{15-0} = 0x0002;
  }
  def USER : InstVC16<(outs), (ins), "user", []> {
    let Inst{15-0} = 0x0003;
  }
  def EI : InstVC16<(outs), (ins), "ei", []> {
    let Inst{15-0} = 0x0004;
  }
  def DI : InstVC16<(outs), (ins), "di", []> {
    let Inst{15-0} = 0x0005;
  }
  def CLR : InstVC16<(outs), (ins), "clr", []> {
    let Inst{15-0} = 0x0006;
  }
  def INC : InstVC16<(outs), (ins), "inc", []> {
    let Inst{15-0} = 0x0007;
  }
  def CHG : InstVC16<(outs), (ins), "chg", []> {
    let Inst{15-0} = 0x0008;
  }
  def DEC : InstVC16<(outs), (ins), "dec", []> {
    let Inst{15-0} = 0x0009;
  }
}

// Return from interrupt
def RTI : InstVC16<(outs), (ins), "rti", []> {
  let Inst{15-0} = 0x000a;
  let isReturn=1;
  let isTerminator=1;
  let isBarrier=1;
  let hasCtrlDep=1;
  let hasSideEffects = 1;
}

let isCall = 1, hasSideEffects = 1 in {
  def SWIr : InstVC16<(outs), (ins IntReg:$Rd), "swi $Rd", []> {
    bits<5> Rd;
    let Inst{15-5} = 1;
    let Inst{4-0} = Rd;
  }
  def SWIi : InstVC16<(outs), (ins immU6opnd:$imm), "swi $imm", []> {
    bits<6> imm;
    let Inst{15-6} = 7;
    let Inst{5-0} = imm;
  }
}

// Branching
let isBranch=1, isTerminator=1, isBarrier=1 in
def Br : InstVC16<(outs), (ins IntReg:$Rd), "b $Rd", /*[(br bb:$Rd)]*/ []> {
  bits<5> Rd;
  let Inst{15-5} = 2;
  let Inst{4-0} = Rd;
}
let isCall=1 in
def BLr : InstVC16<(outs), (ins IntReg:$Rd), "bl $Rd", []> {
  bits<5> Rd;
  let Inst{15-5} = 3;
  let Inst{4-0} = Rd;
}

// Table/Switch jumps
let isBranch=1, isTerminator=1, isBarrier=1, hasSideEffects=1 in {
  def TBB : InstVC16<(outs), (ins IntReg:$Rd), "tbb $Rd", []> {
    bits<5> Rd;
    let Inst{15-5} = 4;
    let Inst{4-0} = Rd;
  }
  def TBH : InstVC16<(outs), (ins IntReg:$Rd), "tbh $Rd", []> {
    bits<5> Rd;
    let Inst{15-5} = 5;
    let Inst{4-0} = Rd;
  }
}

def CPUID : InstVC16<(outs IntReg:$Rd), (ins), "cpuid $Rd", []> {
  bits<5> Rd;
  let Inst{15-5} = 7;
  let Inst{4-0} = Rd;
}


//===----------------------------------------------------------------------===//
// Non-Instruction Patterns
//===----------------------------------------------------------------------===//

