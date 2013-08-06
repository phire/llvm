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

def immU5_asmoperand : AsmOperandClass {
  let Name = "ImmU5";
}

def immU5 : PatLeaf<(imm), [{
  return (uint32_t)N->getZExtValue() < (1 << 5);
}]>;

def immU5opnd : Operand<i32> {
      let PrintMethod = "printU5ImmOperand";
      let ParserMatchClass = immU5_asmoperand;
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

def immS6_asmoperand : AsmOperandClass {
  let Name = "ImmS6";
}

def immS6 : PatLeaf<(imm), [{ return isInt<6>(N->getSExtValue()); }]>;

def immS6opnd : Operand<i32> {
      let PrintMethod = "printSignedImmOperand";
      let ParserMatchClass = immS6_asmoperand;
}

def immS16_asmoperand : AsmOperandClass {
  let Name = "ImmS16";
}

def immS16 : PatLeaf<(imm), [{ return isInt<16>(N->getSExtValue()); }]>;

def immS16opnd : Operand<i32> {
      let PrintMethod = "printSignedImmOperand";
      let ParserMatchClass = immS16_asmoperand;
}

def immS27_asmoperand : AsmOperandClass {
  let Name = "ImmS27";
}

def immS27 : PatLeaf<(imm), [{ return isInt<27>(N->getSExtValue()); }]>;

def immS27opnd : Operand<i32> {
      let PrintMethod = "printSignedImmOperand";
      let ParserMatchClass = immS27_asmoperand;
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

class MemOperand<string Type=""> : AsmOperandClass {
  let Name = "Mem"#Type;
  let ParserMethod = "parseMem";
  let RenderMethod = "addMemOperands";
}
def MemOperandOffset : MemOperand<"Offset"> {
  let RenderMethod = "addMemOffsetOperands";
}

// Address operands
let PrintMethod = "printMemOperand" in {
  def MEMrr : Operand<i32> {
    let MIOperandInfo = (ops IntReg, IntReg);
    let ParserMatchClass = MemOperandOffset;
  }
  def MEMri : Operand<i32> {
    let MIOperandInfo = (ops IntReg, i32imm);
    let DecoderMethod = "DecodeMEMri";
    let ParserMatchClass = MemOperandOffset;
  }
  def MEMdec : Operand<i32> {
    let MIOperandInfo = (ops IntReg);
    let ParserMatchClass = MemOperand<"Dec">;
  }
  def MEMinc : Operand<i32> {
    let MIOperandInfo = (ops IntReg);
    let ParserMatchClass = MemOperand<"Inc">;
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
  def qq : ArithLogicQQ<opc, asmstr,
        [(set LowReg:$Rd, (node LowReg:$src, LowReg:$Rs))]>;
  def ri : ArithLogicRI<opc, asmstr,
		[(set IntReg:$Rd, (immnode IntReg:$src, (i32 immS16:$imm)))]>;
  def i48 : ArithLogicI32<opc, asmstr,
		[(set IntReg:$Rd, (immnode IntReg:$src, (i32 immU32:$imm)))]>;
  def rrr : RRR<!add(0xc00, !shl(opc, 1)), asmstr,
        [(set IntReg:$Rd, (node IntReg:$Ra, IntReg:$Rb))]>;
  def rri : RRI<!add(0xc00, !shl(opc, 1)), asmstr, 
		[(set IntReg:$Rd, (immnode IntReg:$Ra, (i32 immS6:$imm)))]>;
}

// Even numbered, two input operations
multiclass ArithLogicE3<int opc, string asmstr, SDPatternOperator node,
                        SDPatternOperator immnode=node> 
 : ArithLogicO3<opc, asmstr, node, immnode> {
  def qi : ArithLogicQI<opc, asmstr,
        [(set LowReg:$Rd, (immnode LowReg:$src, (i32 immU5:$imm)))]>;
}

// Odd numbered, one input operations
multiclass ArithLogicO2<int opc, string asmstr, SDPatternOperator node, 
                        SDPatternOperator immnode=node> {
  def qq : ArithLogicQQ_1<opc, asmstr,
        [(set LowReg:$Rd, (node LowReg:$Rs))]>;
  def ri : ArithLogicRI_1<opc, asmstr,
		[(set IntReg:$Rd, (immnode (i32 immS16:$imm)))]>;
  def i32 : ArithLogicI32_1<opc, asmstr,
		[(set IntReg:$Rd, (immnode (i32 immU32:$imm)))]>;
  def r_r : R_R<!add(0xc00, !shl(opc, 1)), asmstr,
        [(set IntReg:$Rd, (node IntReg:$Rb))]>;
  def r_i : R_I<!add(0xc00, !shl(opc, 1)), asmstr, 
		[(set IntReg:$Rd, (immnode (i32 immS6:$imm)))]>;
}

// Even numbered, one input operations
multiclass ArithLogicE2<int opc, string asmstr, SDPatternOperator node, 
                        SDPatternOperator immnode=node> 
 : ArithLogicO2<opc, asmstr, node, immnode> {
  def qi : ArithLogicQI_1<opc, asmstr,
        [(set LowReg:$Rd, (immnode (i32 immU5:$imm)))]>;
}

// Add Scale operations
multiclass AddScale<int opc, int shift> {
  let Constraints="$src = $Rd", DisableEncoding="$src" in {
  def qq : _ArithLogicQQ<opc, (ins LowReg:$src, LowReg:$Rs), 
		"addscale $Rd, $Rs shl "#shift,
        [(set LowReg:$Rd, (add LowReg:$src, (shl LowReg:$Rs, shift)))]> {
    let isConvertibleToThreeAddress = 1;
  }
  def ri : _ArithLogicRI<opc, (ins IntReg:$src, immS16opnd:$imm), 
		"addscale $Rd, $imm shl "#shift,
		[(set IntReg:$Rd, (add IntReg:$src, (shl (i32 immS16:$imm), shift)))]>;
  def i32 : _ArithLogicI32<opc, (ins IntReg:$src, immU32opnd:$imm),
		"addscale $Rd, $imm shl "#shift,
		[(set IntReg:$Rd, (add IntReg:$src, (shl (i32 immU32:$imm), shift)))]>;
  }
  def rr : RRR<!add(0xc00, !shl(opc, 1)), "addscale",
        [(set IntReg:$Rd, (add IntReg:$Ra, (shl IntReg:$Rb, shift)))], 
        "addscale$Cond $Rd, $Ra, $Rb shl "#shift>;
  def rri : RRI<!add(0xc00, !shl(opc, 1)), "addscale",
		[(set IntReg:$Rd, (add IntReg:$Ra, (shl (i32 immS6:$imm), shift)))],
        "addscale$Cond $Rd, $Ra, $imm shl "#shift>;
}
// For the single even numbered addscale operation
multiclass AddScale_E<int opc, int shift> : AddScale<opc, shift> {
  let Constraints="$src = $Rd", DisableEncoding="$src" in {
  def qi : _ArithLogicQI<opc, (ins LowReg:$src, immU5opnd:$imm),
		"addscale $Rd, $imm shl "#shift,
        [(set LowReg:$Rd, (add LowReg:$src, (shl (i32 immU5:$imm), shift)))]> {
            let isConvertibleToThreeAddress = 1;
		}
  }
}

// the remaining scale instructions
multiclass Scale<bits<12> op, string asm, int shift, SDPatternOperator node> {
  def rrr : RRR<op, asm,
        [(set IntReg:$Rd, (node IntReg:$Ra, (shl IntReg:$Rb, shift)))],
        !strconcat(asm, "$Cond $Rd, $Ra, $Rb shl "#shift)>;
  def rri : RRI<op, asm,
        [(set IntReg:$Rd, (node IntReg:$Ra, (shl immS6:$imm, shift)))],
        !strconcat(asm, "$Cond $Rd, $Ra, $imm shl "#shift)>;
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

/*
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
}*/


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

def STWrri12 : InstVC32<(outs), (ins IntReg:$src, MEMri:$addr), "st $src, $addr",
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

def LDWrri12 : InstVC32<(outs IntReg:$dst), (ins MEMri:$addr), "ld $dst, $addr",
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
def MOVqq : ArithLogicQQ_1<0, "mov", []>;
def MOVrr : R_R<0xc00, "mov", []>;
let isMoveImm=1 in {
  def MOVqi : ArithLogicQI_1<0, "mov", [(set LowReg:$Rd, (i32 immU5:$imm))]>;
  def MOVri : ArithLogicRI_1<0, "mov", [(set IntReg:$Rd, (i32 immS16:$imm))]>;
  def MOVrri : R_I<0xc00, "mov", [(set IntReg:$Rd, (i32 immS6:$imm))]>;
  def MOVi32 : ArithLogicI32_1<0, "mov", [(set IntReg:$Rd, (i32 immU32:$imm))]>;
}

// FIXME: cmn is completly wrong, for disassembly/assembly  No Codegen
defm CMN  : ArithLogicO3<1, "cmn", null_frag>;
defm ADD  : ArithLogicE3<2, "add", add>;
defm BIC  : ArithLogicO3<3, "bic", bic>;
defm MUL  : ArithLogicE3<4, "mul", mul>;
defm XOR  : ArithLogicO3<5, "xor", xor>;
defm SUB  : ArithLogicE3<6, "sub", sub>;
defm AND  : ArithLogicO3<7, "and", and>;
defm NOT  : ArithLogicE2<8, "and", not>;
defm ROR  : ArithLogicO3<9, "ror", rotr>;
// FIXME: cmp is completly wrong and doesn't work with codegen above
defm CMP  : ArithLogicE3<10, "cmp", null_frag>;
defm RSUB : ArithLogicO3<11, "rsub", rsub>;
// FIXME: btest is completly wrong, for disassembly/assembly  No Codegen
defm BTEST: ArithLogicE3<12, "btest", null_frag>;
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
def ADDrri32 : InstVC48<(outs IntReg:$Rd), (ins IntReg:$Rs, immU32opnd:$imm),
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
def ADDrPCi32 : InstVC48<(outs IntReg:$Rd), (ins immU32opnd:$imm),
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
def MULHDSSrrr : RRR<0xc40, "mulhd", [], "mulhd${Cond}.ss $Rd, $Ra, $Rb">; 
def MULHDSSrri : RRI<0xc40, "mulhd", [], "mulhd${Cond}.ss $Rd, $Ra, $imm">;
def MULHDSUrrr : RRR<0xc42, "mulhd", [], "mulhd${Cond}.su $Rd, $Ra, $Rb">;
def MULHDSUrri : RRI<0xc42, "mulhd", [], "mulhd${Cond}.su $Rd, $Ra, $imm">;
def MULHDUSrrr : RRR<0xc44, "mulhd", [], "mulhd${Cond}.us $Rd, $Ra, $Rb">;
def MULHDUSrri : RRI<0xc44, "mulhd", [], "mulhd${Cond}.us $Rd, $Ra, $imm">;
def MULHDUUrrr : RRR<0xc46, "mulhd", [], "mulhd${Cond}.uu $Rd, $Ra, $Rb">;
def MULHDUUrri : RRI<0xc46, "mulhd", [], "mulhd${Cond}.uu $Rd, $Ra, $imm">;

// Conditional Divide Instructions   FIXME: no codegen
def DIVSSrrr : RRR<0xc48, "div", [], "div${Cond}.ss $Rd, $Ra, $Rb">;
def DIVSSrri : RRI<0xc48, "div", [], "div${Cond}.ss $Rd, $Ra, $imm">;
def DIVSUrrr : RRR<0xc4a, "div", [], "div${Cond}.su $Rd, $Ra, $Rb">;
def DIVSUrri : RRI<0xc4a, "div", [], "div${Cond}.su $Rd, $Ra, $imm">;
def DIVUSrrr : RRR<0xc4c, "div", [], "div${Cond}.us $Rd, $Ra, $Rb">;
def DIVUSrri : RRI<0xc4c, "div", [], "div${Cond}.us $Rd, $Ra, $imm">;
def DIVUUrrr : RRR<0xc4e, "div", [], "div${Cond}.uu $Rd, $Ra, $Rb">;
def DIVUUrri : RRI<0xc4e, "div", [], "div${Cond}.uu $Rd, $Ra, $imm">;

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
defm ADDSCALE_5 : Scale<0xc58, "addscale", 5, add>;
defm ADDSCALE_6 : Scale<0xc5a, "addscale", 6, add>;
defm ADDSCALE_7 : Scale<0xc5c, "addscale", 7, add>;
defm ADDSCALE_8 : Scale<0xc5e, "addscale", 8, add>;

defm SUBSCALE_1 : Scale<0xc62, "subscale", 1, sub>;
defm SUBSCALE_2 : Scale<0xc64, "subscale", 2, sub>;
defm SUBSCALE_3 : Scale<0xc66, "subscale", 3, sub>;
defm SUBSCALE_4 : Scale<0xc68, "subscale", 4, sub>;
defm SUBSCALE_5 : Scale<0xc6a, "subscale", 5, sub>;
defm SUBSCALE_6 : Scale<0xc6c, "subscale", 6, sub>;
defm SUBSCALE_7 : Scale<0xc6e, "subscale", 7, sub>;
defm SUBSCALE_8 : Scale<0xc70, "subscale", 8, sub>;

// Memory Instructions - No Codegen
// Conditional with indexed/displacement
def LDWrrr : RRR<0xa00, "ld", []>;
def LDWrri : RRI<0xa00, "ld", []>; // FIXME: Docs say the offset is unsigned,
                                    // but I've done signed here. Is this right?
def STWrrr : RRR<0xa02, "st", []>;
def STWrri : RRI<0xa02, "st", []>; 

def LDHrrr : RRR<0xa04, "ldh", []>;
def LDHrri : RRI<0xa04, "ldh", []>; 
def STHrrr : RRR<0xa06, "sth", []>;
def STHrri : RRI<0xa06, "sth", []>; 

def LDBrrr : RRR<0xa08, "ldb", []>;
def LDBrri : RRI<0xa08, "ldb", []>; 
def STBrrr : RRR<0xa0a, "stb", []>;
def STBrri : RRI<0xa0a, "stb", []>; 

def LDHSrrr : RRR<0xa0c, "ldhs", []>;
def LDHSrri : RRI<0xa0c, "ldhs", []>; 
def STHSrrr : RRR<0xa0e, "sths", []>;
def STHSrri : RRI<0xa0e, "sths", []>;

// Condtional with pre-decrement
def LDWdec  : MEMupdate<0xa40, "ld",   [], MEMdec>;
def STWdec  : MEMupdate<0xa42, "st",   [], MEMdec>;
def LDHdec  : MEMupdate<0xa44, "ldh",  [], MEMdec>;
def STHdec  : MEMupdate<0xa46, "sth",  [], MEMdec>;
def LDBdec  : MEMupdate<0xa48, "ldb",  [], MEMdec>;
def STBdec  : MEMupdate<0xa4a, "stb",  [], MEMdec>;
def LDHSdec : MEMupdate<0xa4c, "ldhs", [], MEMdec>;
def STHSdec : MEMupdate<0xa4e, "sths", [], MEMdec>;

// Conditional with post-increment
def LDWinc  : MEMupdate<0xa50, "ld",   [], MEMinc>;
def STWinc  : MEMupdate<0xa52, "st",   [], MEMinc>;
def LDHinc  : MEMupdate<0xa54, "ldh",  [], MEMinc>;
def STHinc  : MEMupdate<0xa56, "sth",  [], MEMinc>;
def LDBinc  : MEMupdate<0xa58, "ldb",  [], MEMinc>;
def STBinc  : MEMupdate<0xa5a, "stb",  [], MEMinc>;
def LDHSinc : MEMupdate<0xa5c, "ldhs", [], MEMinc>;
def STHSinc : MEMupdate<0xa5e, "sths", [], MEMinc>;

// 27 bit offsets
def LDWri27  : RI27<0xe6, 0, "ld", []>;
def STWri27  : RI27<0xe6, 1, "st", []>;
def LDHri27  : RI27<0xe6, 2, "ldh", []>;
def STHri27  : RI27<0xe6, 3, "sth", []>;
def LDBri27  : RI27<0xe6, 4, "ldb", []>;
def STBri27  : RI27<0xe6, 5, "stb", []>;
def LDHSri27 : RI27<0xe6, 6, "ldhs", []>;
def STHSri27 : RI27<0xe6, 7, "sths", []>;

def LDW_PCi27  : PCI27<0xe7, 0, "ld", []>;
def STW_PCi27  : PCI27<0xe7, 1, "st", []>;
def LDH_PCi27  : PCI27<0xe7, 2, "ldh", []>;
def STH_PCi27  : PCI27<0xe7, 3, "sth", []>;
def LDB_PCi27  : PCI27<0xe7, 4, "ldb", []>;
def STB_PCi27  : PCI27<0xe7, 5, "stb", []>;
def LDHS_PCi27 : PCI27<0xe7, 6, "ldhs", []>;
def STHS_PCi27 : PCI27<0xe7, 7, "sths", []>;

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

// For our disassembler
def SCALAR16 : InstVC<2, (outs), (ins), "<Scalar16>", []>;
def SCALAR32 : InstVC<4, (outs), (ins), "<Scalar32>", []>;
def SCALAR48 : InstVC<6, (outs), (ins), "<Scalar48>", []>;
def VECTOR48 : InstVC<6, (outs), (ins), "<Vector48>", []>;
def VECTOR80 : InstVC<10, (outs), (ins), "<Vector80>", []>;


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
