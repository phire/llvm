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


def bic   : PatFrag<(ops node:$lhs, node:$rhs),
                    (and node:$lhs, (xor node:$rhs, -1))>;
def rsub  : PatFrag<(ops node:$lhs, node:$rhs), 
                    (sub node:$rhs, node:$lhs)>;
def bmask : PatFrag<(ops node:$lhs, node:$rhs),
                    (and node:$lhs, (add (shl 1, node:$rhs), -1))>;
def bset  : PatFrag<(ops node:$lhs, node:$rhs),
                    (or node:$lhs, (shl 1, node:$rhs))>;
def bclr  : PatFrag<(ops node:$lhs, node:$rhs),
                    (and node:$lhs, (xor (shl 1, node:$rhs), -1))>;
def bchg  : PatFrag<(ops node:$lhs, node:$rhs),
                    (xor node:$lhs, (shl 1, node:$rhs))>;


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

def cond_code : PredicateOperand<i32, (ops i32imm), (ops (i32 14))>,
                ImmLeaf<i32, [{
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

// Odd numbered, two input operations
multiclass ArithLogicO3<int opc, string asmstr, SDPatternOperator node, 
                        SDPatternOperator immnode=node> {
  let Constraints="$src = $Rd", DisableEncoding="$src" in {
  def qq : ArithLogicQQ<opc, (ins LowReg:$src, LowReg:$Rs), 
		!strconcat(asmstr, " $Rd, $Rs"),
        [(set LowReg:$Rd, (node LowReg:$src, LowReg:$Rs))]> {
            let isConvertibleToThreeAddress = 1;
		}
  def ri : ArithLogicRI<opc, (ins IntReg:$src, immS16opnd:$imm), 
		!strconcat(asmstr, " $Rd, $imm"),
		[(set IntReg:$Rd, (immnode IntReg:$src, (i32 immS16:$imm)))]>;
  def i48 : ArithLogic48<opc, (ins IntReg:$src, immU32opnd:$imm),
		!strconcat(asmstr, " $Rd, $imm"),
		[(set IntReg:$Rd, (immnode IntReg:$src, (i32 immU32:$imm)))]>;
  }
  def rrr : RRR<!add(0xc00, !shl(opc, 1)), asmstr,
        [(set IntReg:$Rd, (node IntReg:$Ra, IntReg:$Rb))]>;
  def rri : RRI<!add(0xc00, !shl(opc, 1)), asmstr, 
		[(set IntReg:$Rd, (immnode IntReg:$Ra, (i32 immS6:$imm)))]>;
}

// Even numbered, two input operations
multiclass ArithLogicE3<int opc, string asmstr, SDPatternOperator node,
     SDPatternOperator immnode=node> : ArithLogicO3<opc, asmstr, node, immnode> {
  let Constraints="$src = $Rd", DisableEncoding="$src" in {
  def qi : ArithLogicQI<opc, (ins LowReg:$src, immU5opnd:$imm),
		!strconcat(asmstr, " $Rd, $imm"),
        [(set LowReg:$Rd, (node LowReg:$src, (i32 immU5:$imm)))]> {
            let isConvertibleToThreeAddress = 1;
		}
  }
}

// Odd numbered, one input operations
multiclass ArithLogicO2<int opc, string asmstr, SDPatternOperator node, 
                        SDPatternOperator immnode=node> {
  def qq : ArithLogicQQ<opc, (ins LowReg:$Rs), 
		!strconcat(asmstr, " $Rd, $Rs"),
        [(set LowReg:$Rd, (node LowReg:$Rs))]>;
  def ri : ArithLogicRI<opc, (ins immS16opnd:$imm), 
		!strconcat(asmstr, " $Rd, $imm"),
		[(set IntReg:$Rd, (immnode (i32 immS16:$imm)))]>;
  def i48 : ArithLogic48<opc, (ins immU32opnd:$imm),
		!strconcat(asmstr, " $Rd, $imm"),
		[(set IntReg:$Rd, (immnode (i32 immU32:$imm)))]>;
  def r_r : R_R<!add(0xc00, !shl(opc, 1)), asmstr,
        [(set IntReg:$Rd, (node IntReg:$Rb))]>;
  def r_i : R_I<!add(0xc00, !shl(opc, 1)), asmstr, 
		[(set IntReg:$Rd, (immnode (i32 immS6:$imm)))]>;
}

// Even numbered, one input operations
multiclass ArithLogicE2<int opc, string asmstr, SDPatternOperator node, 
    SDPatternOperator immnode=node> : ArithLogicO2<opc, asmstr, node, immnode> {
  def qi : ArithLogicQI<opc, (ins immU5opnd:$imm),
		!strconcat(asmstr, " $Rd, $imm"),
        [(set LowReg:$Rd, (node (i32 immU5:$imm)))]>;
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
// For the single even numbered addscale operation
multiclass AddScale_E<int opc, int shift> : AddScale<opc, shift> {
  let Constraints="$src = $Rd", DisableEncoding="$src" in {
  def qi : ArithLogicQI<opc, (ins LowReg:$src, immU5opnd:$imm),
		"addscale $Rd, $imm shl "#shift,
        [(set LowReg:$Rd, (add LowReg:$src, (shl (i32 immU5:$imm), shift)))]> {
            let isConvertibleToThreeAddress = 1;
		}
  }
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
		"b$Cond $imm24", [/*(VCbr_cc NZCV, (i32 imm:$Cond), bb:$imm24)*/]> {
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
def MOVqq : ArithLogicQQ<0, (ins LowReg:$Rs), "mov $Rd, $Rs", []>;
def MOVrr : R_R<0xc00, "mov", []>;
let isMoveImm=1 in {
  def MOVqi : ArithLogicQI<0, (ins immU5opnd:$imm), "mov $Rd, $imm",
        [(set LowReg:$Rd, (i32 immU5:$imm))]>;
  def MOVri : ArithLogicRI<0, (ins immS16opnd:$imm), "mov $Rd, $imm",
		[(set IntReg:$Rd, (i32 immS16:$imm))]>;
  def MOVrri : R_I<0xc00, "mov", [(set IntReg:$Rd, (i32 immS6:$imm))]>;
  def MOVi48 : ArithLogic48<0, (ins immU32opnd:$imm), "mov $Rd, $imm",
		[(set IntReg:$Rd, (i32 immU32:$imm))]>;
}

// 1 - CMN
defm ADD  : ArithLogicO3<2, "add", add>;
defm BIC  : ArithLogicO3<3, "bic", bic>;
defm MUL  : ArithLogicE3<4, "mul", mul>;
defm XOR  : ArithLogicO3<5, "xor", xor>;
defm SUB  : ArithLogicE3<6, "sub", sub>;
defm AND  : ArithLogicO3<7, "and", and>;
defm NOT  : ArithLogicE2<8, "and", not>;
defm ROR  : ArithLogicO3<9, "ror", rotr>;
// 10 - CMP
defm RSUB : ArithLogicO3<11, "rsub", rsub>;
// 12 - BTST
defm OR   : ArithLogicO3<13, "or", or>;
defm BMASK: ArithLogicE3<14, "bmask", bmask, null_frag>;
defm MAX  : ArithLogicO3<15, "max", null_frag>;            // No Codegen
defm BSET : ArithLogicE3<16, "bset", bset, null_frag>;
defm MIN  : ArithLogicO3<17, "min", null_frag>;            // No Codegen
defm BCLR : ArithLogicE3<18, "bclr", bclr, null_frag>;
defm ADDSCALE_1 : AddScale<19, 1>;
defm BCHG : ArithLogicE3<20, "bchg", bchg, null_frag>;
defm ADDSCALE_2 : AddScale<21, 2>;
defm ADDSCALE_3 : AddScale_E<22, 3>;
defm ADDSCALE_4 : AddScale<23, 4>;
defm SIGNEXT : ArithLogicE3<24, "signext", null_frag>;     // No Codegen
defm NEG  : ArithLogicO2<25, "neg", ineg>;
defm LSR  : ArithLogicE3<26, "lsr", srl>;
defm MSB  : ArithLogicO2<27, "msb", null_frag>;            // No Codegen
defm SHL  : ArithLogicE3<28, "shl", shl>;
defm BITREV  : ArithLogicO3<29, "bitrev", null_frag>;      // No Codegen
defm ASR  : ArithLogicE3<30, "asr", sra>;
defm ASB  : ArithLogicO2<31, "asb", null_frag>;            // No Codegen


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

// Conditional Multiply Instructions  FIXME: no codegen
def MULHDSSrrr : _RRR<0xc40, "mulhd${Cond}.ss $Rd, $Ra, $Rb", []>; 
def MULHDSSrri : _RRI<0xc40, "mulhd${Cond}.ss $Rd, $Ra, $imm", []>;
def MULHDSUrrr : _RRR<0xc42, "mulhd${Cond}.su $Rd, $Ra, $Rb", []>;
def MULHDSUrri : _RRI<0xc42, "mulhd${Cond}.su $Rd, $Ra, $imm", []>;
def MULHDUSrrr : _RRR<0xc44, "mulhd${Cond}.us $Rd, $Ra, $Rb", []>;
def MULHDUSrri : _RRI<0xc44, "mulhd${Cond}.us $Rd, $Ra, $imm", []>;
def MULHDUUrrr : _RRR<0xc46, "mulhd${Cond}.uu $Rd, $Ra, $Rb", []>;
def MULHDUUrri : _RRI<0xc46, "mulhd${Cond}.uu $Rd, $Ra, $imm", []>;

// Conditional Divide Instructions   FIXME: no codegen
def DIVSSrrr : _RRR<0xc48, "div${Cond}.ss $Rd, $Ra, $Rb", []>;
def DIVSSrri : _RRI<0xc48, "div${Cond}.ss $Rd, $Ra, $imm", []>;
def DIVSUrrr : _RRR<0xc4a, "div${Cond}.su $Rd, $Ra, $Rb", []>;
def DIVSUrri : _RRI<0xc4a, "div${Cond}.su $Rd, $Ra, $imm", []>;
def DIVUSrrr : _RRR<0xc4c, "div${Cond}.us $Rd, $Ra, $Rb", []>;
def DIVUSrri : _RRI<0xc4c, "div${Cond}.us $Rd, $Ra, $imm", []>;
def DIVUUrrr : _RRR<0xc4e, "div${Cond}.uu $Rd, $Ra, $Rb", []>;
def DIVUUrri : _RRI<0xc4e, "div${Cond}.uu $Rd, $Ra, $imm", []>;

// Additional Conditional Arithmetic and Logical Operations
// no codegen (intrinsics?)
def ADDSrrr : RRR<0xc50, "adds", []>;
def ADDSrri : RRI<0xc50, "adds", []>;

def SUBSrrr : RRR<0xc52, "subs", []>;
def SUBSrri : RRI<0xc52, "subs", []>;

def SHLSrrr : RRR<0xc54, "shls", []>;
def SHLSrri : RRI<0xc54, "shls", []>;

def CLAMP16r_r : R_R<0xc56, "clamp16", []>;
def CLAMP16r_i : R_I<0xc56, "clamp16", []>;

def COUNTr_r : R_R<0xc60, "count", []>;
def COUNTr_i : R_I<0xc60, "count", []>;

// Additional Addscale opcodes
def ADDSCALE_5rrr : _RRR<0xc58, "addscale$Cond $Rd, $Ra, $Rb shl 5",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl IntReg:$Rb, 5)))]>;
def ADDSCALE_6rrr : _RRR<0xc5a, "addscale$Cond $Rd, $Ra, $Rb shl 6",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl IntReg:$Rb, 6)))]>;
def ADDSCALE_7rrr : _RRR<0xc5c, "addscale$Cond $Rd, $Ra, $Rb shl 7",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl IntReg:$Rb, 7)))]>;
def ADDSCALE_8rrr : _RRR<0xc5e, "addscale$Cond $Rd, $Ra, $Rb shl 8",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl IntReg:$Rb, 8)))]>;

def ADDSCALE_5rri : _RRI<0xc58, "addscale$Cond $Rd, $Ra, $imm shl 5",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl immS6:$imm, 5)))]>;
def ADDSCALE_6rri : _RRI<0xc5a, "addscale$Cond $Rd, $Ra, $imm shl 6",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl immS6:$imm, 6)))]>;
def ADDSCALE_7rri : _RRI<0xc5c, "addscale$Cond $Rd, $Ra, $imm shl 7",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl immS6:$imm, 7)))]>;
def ADDSCALE_8rri : _RRI<0xc5e, "addscale$Cond $Rd, $Ra, $imm shl 8",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl immS6:$imm, 8)))]>;

// Subscale opcodes
def SUBSCALE_1rrr : _RRR<0xc62, "subscale$Cond $Rd, $Ra, $Rb shl 1",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 1)))]>;
def SUBSCALE_2rrr : _RRR<0xc64, "subscale$Cond $Rd, $Ra, $Rb shl 2",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 2)))]>;
def SUBSCALE_3rrr : _RRR<0xc66, "subscale$Cond $Rd, $Ra, $Rb shl 3",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 3)))]>;
def SUBSCALE_4rrr : _RRR<0xc68, "subscale$Cond $Rd, $Ra, $Rb shl 4",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 4)))]>;
def SUBSCALE_5rrr : _RRR<0xc6a, "subscale$Cond $Rd, $Ra, $Rb shl 5",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 5)))]>;
def SUBSCALE_6rrr : _RRR<0xc6c, "subscale$Cond $Rd, $Ra, $Rb shl 6",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 6)))]>;
def SUBSCALE_7rrr : _RRR<0xc6e, "subscale$Cond $Rd, $Ra, $Rb shl 7",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 7)))]>;
def SUBSCALE_8rrr : _RRR<0xc70, "subscale$Cond $Rd, $Ra, $Rb shl 8",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl IntReg:$Rb, 8)))]>;

def SUBSCALE_1rri : _RRI<0xc62, "subscale$Cond $Rd, $Ra, $imm shl 1",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 1)))]>;
def SUBSCALE_2rri : _RRI<0xc64, "subscale$Cond $Rd, $Ra, $imm shl 2",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 2)))]>;
def SUBSCALE_3rri : _RRI<0xc66, "subscale$Cond $Rd, $Ra, $imm shl 3",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 3)))]>;
def SUBSCALE_4rri : _RRI<0xc68, "subscale$Cond $Rd, $Ra, $imm shl 4",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 4)))]>;
def SUBSCALE_5rri : _RRI<0xc6a, "subscale$Cond  $Rd, $Ra, $imm shl 5",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 5)))]>;
def SUBSCALE_6rri : _RRI<0xc6c, "subscale$Cond  $Rd, $Ra, $imm shl 6",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 6)))]>;
def SUBSCALE_7rri : _RRI<0xc6e, "subscale$Cond  $Rd, $Ra, $imm shl 7",
        [(set IntReg:$Rd, (sub IntReg:$Ra, (shl immS6:$imm, 7)))]>;
def SUBSCALE_8rri : _RRI<0xc70, "subscale$Cond $Rd, $Ra, $imm shl 8",
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

// Match immediates for bit manipulation instructions
def : Pat<(and LowReg:$r, MASKi:$imm), (BMASKqi LowReg:$r, MASKi:$imm)>;
def : Pat<(and IntReg:$r, MASKi:$imm), (BMASKrri IntReg:$r, MASKi:$imm)>;

def : Pat<(or LowReg:$r, BITi:$imm), (BSETqi LowReg:$r, BITi:$imm)>;
def : Pat<(or IntReg:$r, BITi:$imm), (BSETrri IntReg:$r, BITi:$imm)>;

def : Pat<(and LowReg:$r, MASKi:$imm), (BCLRqi LowReg:$r, NOTBITi:$imm)>;
def : Pat<(and IntReg:$r, MASKi:$imm), (BCLRrri IntReg:$r, NOTBITi:$imm)>;

def : Pat<(xor LowReg:$r, MASKi:$imm), (BCHGqi LowReg:$r, BITi:$imm)>;
def : Pat<(xor IntReg:$r, MASKi:$imm), (BCHGrri IntReg:$r, BITi:$imm)>;


// llvm prefers adding negitave constants instead of using our smaller sub.
// So we match SUBqi to match additions with small negitave numbers
def : Pat<(add LowReg:$r, NEGu5:$imm), (SUBqi LowReg:$r, NEGu5:$imm)>; 
