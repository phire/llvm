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

def immU4 : PatLeaf<(imm), [{
  return (uint32_t)N->getZExtValue() < (1 << 4);
}]>;


def immU16 : PatLeaf<(imm), [{
  return (uint32_t)N->getZExtValue() < (1 << 16);
}]>;

def immS16 : PatLeaf<(imm), [{ return isInt<16>(N->getSExtValue()); }]>;

def immS16opnd : Operand<i32> {
      let PrintMethod = "printS16ImmOperand";
}

def immU32 : PatLeaf<(imm), [{ return isInt<32>(N->getZExtValue()); }]>;

def immU32opnd : Operand<i32> {
      let PrintMethod = "printU32ImmOperand";
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
  let Constraints="$src = $Rd" in {
  def qq : ArithLogicQQ<opc, (ins LowReg:$src, LowReg:$Rb), 
		!strconcat(asmstr, " $Rd, $Rb"),
        [(set LowReg:$Rd, (node LowReg:$src, LowReg:$Rb))]> {
            let isConvertibleToThreeAddress = 1;
		}
  def qi : ArithLogicQI<opc, (ins LowReg:$src, immU5opnd:$imm),
		!strconcat(asmstr, " $Rd, $imm"),
        [(set LowReg:$Rd, (node LowReg:$src, (i32 immU5:$imm)))]>;
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
}

// Even numbered operations
multiclass ArithLogicE2<int opc, string asmstr, SDNode node> {
  def qq : ArithLogicQQ<opc, (ins LowReg:$Ra), 
		!strconcat(asmstr, " $Rd, $Ra"),
        [(set LowReg:$Rd, (node LowReg:$Ra))]>;
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
}

// Odd numbered operations
multiclass ArithLogicO3<int opc, string asmstr, SDNode node> {
  let Constraints="$src = $Rd" in {
  def qq : ArithLogicQQ<opc, (ins LowReg:$src, LowReg:$Rb), 
		!strconcat(asmstr, " $Rd, $Rb"),
        [(set LowReg:$Rd, (node LowReg:$src, LowReg:$Rb))]> {
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
}


def CMPqq : InstVC16<(outs), (ins LowReg:$Ra, LowReg:$Rb), "cmp $Ra, $Rb",
	[(set NZCV, (VCcmp LowReg:$Ra, LowReg:$Rb))]> {
	bits<4> Ra;
	bits<4> Rb;

	let Inst{15-13} = 2;
	let Inst{12-8} = 0xa;
	let Inst{7-4} = Rb;
	let Inst{3-0} = Ra;
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
  def MOVi48 : ArithLogic48<0, (ins immU32opnd:$imm), "mov $Rd, $imm",
		[(set IntReg:$Rd, (i32 immU32:$imm))]>;
}

defm ADD  : ArithLogicO3<2, "add", add>;

let Constraints="$src = $Rd" in {
  let isConvertibleToThreeAddress = 1 in
  def BICqq : ArithLogicQQ<3, (ins LowReg:$src, LowReg:$Rb), 
		"bic $Rd, $Rb",
        [(set LowReg:$Rd, (and LowReg:$src, (xor LowReg:$Rb, -1)))]>;
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

defm MUL  : ArithLogicE3<4, "mul", mul>;
defm XOR  : ArithLogicO3<5, "xor", xor>;
defm SUB  : ArithLogicO3<6, "sub", sub>; // use O3, so SUBqi isn't created

// llvm prefers adding negitave constants instead of using our smaller sub.
// So we override SUBqi to match additions with small negitave numbers
def SUBqi : ArithLogicQI<6, (ins LowReg:$src, immU5opnd:$imm),
		"sub $Rd, $imm",
        [(set LowReg:$Rd, (add LowReg:$src, NEGu5:$imm))]>;

defm AND  : ArithLogicO3<7, "and", and>;

def MVNqq : ArithLogicQQ<8, (ins LowReg:$Ra), "mvn $Rd, $Ra",
		[(set LowReg:$Rd, (xor LowReg:$Ra, -1))]>;
def MVNrr : ArithLogicRR<8, (ins IntReg:$Ra), "mvn $Rd, $Ra",
		[(set IntReg:$Rd, (xor IntReg:$Ra, -1))]>;
def MVNqi : ArithLogicQI<8, (ins immU5opnd:$imm), "mvn $Rd, $imm",
		[(set LowReg:$Rd, (xor (i32 immU5:$imm), -1))]>;
// MVNri and MVNi48 are pointless to implement

defm ROR  : ArithLogicO3<9, "ror", rotr>;

let Constraints="$src = $Rd" in {
  let isConvertibleToThreeAddress = 1 in
  def RSBqq : ArithLogicQQ<11, (ins LowReg:$src, LowReg:$Rb), 
		"rsb $Rd, $Rb",
        [(set LowReg:$Rd, (sub LowReg:$Rb, LowReg:$src))]>;
  def RSBri : ArithLogicRI<11, (ins IntReg:$src, immS16opnd:$imm), 
		"rsb $Rd, $imm",
		[(set IntReg:$Rd, (sub (i32 immS16:$imm), IntReg:$src))]>;
  def RSBi48 : ArithLogic48<11, (ins IntReg:$src, immU32opnd:$imm),
		"rsb $Rd, $imm",
		[(set IntReg:$Rd, (sub (i32 immU32:$imm), IntReg:$src))]>;
}
def RSBrr : ArithLogicRRR<11, (ins IntReg:$Ra, IntReg:$Rb),
		"rsb $Rd, $Ra, $Rb",
        [(set IntReg:$Rd, (sub IntReg:$Rb, IntReg:$Ra))]>;


defm OR   : ArithLogicO3<13, "or", or>;

let Constraints="$src = $Rd" in {
  let isConvertibleToThreeAddress = 1 in
  def EXTUqq : ArithLogicQQ<14, (ins LowReg:$src, LowReg:$Rb), 
		"extu $Rd, $Rb",
        [(set LowReg:$Rd, (and LowReg:$src, (add (shl 1, LowReg:$Rb), -1)))]>;
  def EXTUqi : ArithLogicQI<14, (ins LowReg:$src, immU5opnd:$imm),
		"extu $Rd, $imm",
        [(set LowReg:$Rd, (and LowReg:$src, MASKi:$imm))]>;
  def EXTUri : ArithLogicRI<14, (ins IntReg:$src, immS16opnd:$imm), 
		"extu $Rd, $imm",
		[(set IntReg:$Rd, (and IntReg:$src, MASKi:$imm))]>;
  def EXTUi48 : ArithLogic48<14, (ins IntReg:$src, immU32opnd:$imm), // useless
		"extu $Rd, $imm",
		[(set IntReg:$Rd, (and IntReg:$src, MASKi:$imm))]>;
}
def EXTUrr : ArithLogicRRR<14, (ins IntReg:$Ra, IntReg:$Rb),
		"extu $Rd, $Ra, $Rb",
        [(set IntReg:$Rd, (and IntReg:$Ra, (add (shl 1, IntReg:$Rb), -1)))]>;


let Constraints="$src = $Rd" in {
  let isConvertibleToThreeAddress = 1 in
  def BSETqq : ArithLogicQQ<16, (ins LowReg:$src, LowReg:$Rb), 
		"bset $Rd, $Rb",
        [(set LowReg:$Rd, (or LowReg:$src, (shl 1, LowReg:$Rb)))]>;
  def BSETqi : ArithLogicQI<16, (ins LowReg:$src, immU5opnd:$imm),
		"bset $Rd, $imm",
        [(set LowReg:$Rd, (or LowReg:$src, BITi:$imm))]>;
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

let Constraints="$src = $Rd" in {
  let isConvertibleToThreeAddress = 1 in
  def BCLRqq : ArithLogicQQ<18, (ins LowReg:$src, LowReg:$Rb), 
		"bclr $Rd, $Rb",
        [(set LowReg:$Rd, (and LowReg:$src, (xor (shl 1, LowReg:$Rb), -1)))]>;
  def BCLRqi : ArithLogicQI<18, (ins LowReg:$src, immU5opnd:$imm),
		"bclr $Rd, $imm",
        [(set LowReg:$Rd, (and LowReg:$src, NOTBITi:$imm))]>;
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

let Constraints="$src = $Rd" in {
  let isConvertibleToThreeAddress = 1 in
  def BCHGqq : ArithLogicQQ<20, (ins LowReg:$src, LowReg:$Rb), 
		"bchg $Rd, $Rb",
        [(set LowReg:$Rd, (xor LowReg:$src, (shl 1, LowReg:$Rb)))]>;
  def BCHGqi : ArithLogicQI<20, (ins LowReg:$src, immU5opnd:$imm),
		"bchg $Rd, $imm",
        [(set LowReg:$Rd, (xor LowReg:$src, BITi:$imm))]>;
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


defm LSR  : ArithLogicE3<26, "lsr", srl>;
defm LSL  : ArithLogicE3<28, "lsl", shl>;
defm ASR  : ArithLogicE3<30, "asr", sra>;



let isReturn=1, isTerminator=1, isBarrier=1, hasCtrlDep=1 in
    def BLR : InstVC16<(outs), (ins), "blr",
                [(retflag)]> {
        let Inst{15-0} = 0x5a;
}

//===----------------------------------------------------------------------===//
// Non-Instruction Patterns
//===----------------------------------------------------------------------===//

