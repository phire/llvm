//=== VideocoreInstrFormats.td - Videocore Instruction Formats ---*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

class InstVC<int sz, dag outs, dag ins, string asmstr, list<dag> pattern> : Instruction {
  field bits<48> Inst;

  let Namespace = "VC";
  int Size = sz;

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString   = asmstr;
  let Pattern = pattern;

  field bits<48> SoftFail = 0;
}

class InstVC16<dag outs, dag ins, string asmstr, list<dag> pattern> 
  : InstVC<2, outs, ins, asmstr, pattern>;

class InstVC32<dag outs, dag ins, string asmstr, list<dag> pattern> 
  : InstVC<4, outs, ins, asmstr, pattern>;

class InstVC48<dag outs, dag ins, string asmstr, list<dag> pattern> 
  : InstVC<6, outs, ins, asmstr, pattern>;


//===----------------------------------------------------------------------===//
// 16 bit instruction classes in the Videocore
//===----------------------------------------------------------------------===//

// Format 2 instructions
class LDST16<bits<2> w, bit ld_st, dag outs, dag ins, string asmstr, list<dag> pattern>
   : InstVC16<outs, ins, asmstr, pattern> {
  bits<4> Rd;
  bits<4> Rs;
  let Inst{15-11} = 0x01;
  let Inst{10-9}  = w;
  let Inst{8} = ld_st;
  let Inst{7-4} = Rs;
  let Inst{3-0} = Rd;
}

class LDST16_sp<bit ld_st, dag outs, dag ins, string asmstr, list<dag> pattern>
   : InstVC16<outs, ins, asmstr, pattern> {
  bits<4> Rd;
  bits<5> offset;
  let Inst{15-10} = 0x01;
  let Inst{9} = ld_st;
  let Inst{8-4} = offset;
  let Inst{3-0} = Rd;
}

class LEA16_sp<bit ld_st, dag outs, dag ins, string asmstr, list<dag> pattern>
   : InstVC16<outs, ins, asmstr, pattern> {
  bits<5> Rd;
  bits<6> offset;
  let Inst{15-9} = 0x02;
  let Inst{10-5} = offset;
  let Inst{4-0} = Rd;
}

class _R__<bits<12> op, dag ins, string asmstr, list<dag> pattern>
   : InstVC32<(outs IntReg:$Rd), ins, asmstr, pattern> {
  bits<5> Rd;
  bits<4> Cond;

  let Inst{31} = 1;
  let Inst{30-21} = op{10-1};
  let Inst{20-16} = Rd;
  let Inst{10-7 } = Cond;

  let isPredicable = 1;
}

class R_R<bits<12> op, string mnemonic, list<dag> pattern>
   : _R__<op, (ins IntReg:$Rb, cond_code:$Cond),
               !strconcat(mnemonic, "$Cond $Rd, $Rb"), pattern> {
  bits<5> Rb;

  let Inst{15-11} = 0;
  let Inst{6-5} = 0;
  let Inst{4-0} = Rb;
}

class R_I<bits<12> op, string mnemonic, list<dag> pattern>
   : _R__<op, (ins immS6opnd:$imm, cond_code:$Cond), 
               !strconcat(mnemonic, "$Cond $Rd, $imm"), pattern> {
  bits<6> imm;

  let Inst{15-11} = 0;
  let Inst{6} = 1;
  let Inst{5-0} = imm;
}

class RR0<bits<12> op, string mnemonic, list<dag> pattern,
          string asmstr=!strconcat(mnemonic, "$Cond $Rd, $Ra")>
  : _R__<op, (ins IntReg:$Ra, cond_code:$Cond), asmstr, pattern> {
  bits<5> Ra;

  let Inst{15-11} = Ra;
  let Inst{6-0} = 0;
}


class RRR<bits<12> op, string mnemonic, list<dag> pattern,
          string asmstr=!strconcat(mnemonic, "$Cond $Rd, $Ra, $Rb")>
  : _R__<op, (ins IntReg:$Ra, IntReg:$Rb, cond_code:$Cond), asmstr, pattern> {
  bits<5> Ra;
  bits<5> Rb;

  let Inst{15-11} = Ra;
  let Inst{6-5} = 0;
  let Inst{4-0} = Rb;
}

class RRI<bits<12> op, string mnemonic, list<dag> pattern,
          string asmstr = !strconcat(mnemonic, "$Cond $Rd, $Ra, $imm")>
  :_R__<op, (ins IntReg:$Ra, immS6opnd:$imm, cond_code:$Cond), asmstr, pattern>{
  bits<5> Ra;
  bits<6> imm;

  let Inst{15-11} = Ra;
  let Inst{6} = 1;
  let Inst{5-0} = imm;
}

// Memory with 27bit offset
class _RI27<bits<8> opc, bits<3> mod, dag ins, string asm, list<dag> pattern>
 : InstVC48<(outs IntReg:$Rd), ins, asm, pattern> {
  bits<5> Rd;
  bits<27> offset;

  let Inst{47-40} = opc;
  let Inst{39-37} = mod;
  let Inst{36-32} = Rd;
  let Inst{26-0} = offset;
}

class RI27<bits<8> opc, bits<3> mod, string asm, list<dag> pattern>
 : _RI27<opc, mod, (ins IntReg:$Ra, immS27opnd:$offset),
        !strconcat(asm, " $Rd, ($Ra + ${offset})"), pattern> {
  bits<5> Ra;

  let Inst{31-27} = Ra;
}

class PCI27<bits<8> opc, bits<3> mod, string asm, list<dag> pattern>
  : _RI27<opc, mod, (ins immS27opnd:$offset),
          !strconcat(asm, " $Rd, (pc + ${offset})"), pattern> {
  let Uses = [PC];

  let Inst{31-27} = 0b11111;
}


// Arithmetic and logic instruction formats

class _ArithLogicQQ<bits<5> op, dag ins, string asm, list<dag> pattern>
   : InstVC16<(outs LowReg:$Rd), ins, asm, pattern> {
  bits<4> Rd;
  bits<4> Rs;

  let Inst{15-13} = 2;
  let Inst{12-8} = op;
  let Inst{7-4} = Rs;
  let Inst{3-0} = Rd;
}
// Two inputs
class ArithLogicQQ<bits<5> op, string asm, list<dag> pattern>
   : _ArithLogicQQ<op, (ins LowReg:$src, LowReg:$Rs), 
                   !strconcat(asm, " $Rd, $Rs"), pattern> {
  let Constraints="$src = $Rd";
  let DisableEncoding="$src";
  let isConvertibleToThreeAddress = 1;
}
// Only one input
class ArithLogicQQ_1<bits<5> op, string asm, list<dag> pattern>
   : _ArithLogicQQ<op, (ins LowReg:$Rs), 
                   !strconcat(asm, " $Rd, $Rs"), pattern>;

class _ArithLogicQI<bits<5> op, dag ins, string asm, list<dag> pattern>
   : InstVC16<(outs LowReg:$Rd), ins, asm, pattern> {
  bits<4> Rd;
  bits<5> imm;

  let Inst{15-13} = 3;
  let Inst{12-9} = op{4-1};
  let Inst{8-4} = imm;
  let Inst{3-0} = Rd;
}
class ArithLogicQI<bits<5> op, string asm, list<dag> pattern>
   : _ArithLogicQI<op, (ins LowReg:$src, immU5opnd:$imm), 
                   !strconcat(asm, " $Rd, $imm"), pattern> {
  let Constraints="$src = $Rd";
  let DisableEncoding="$src";
  let isConvertibleToThreeAddress = 1;
}
// Only one input
class ArithLogicQI_1<bits<5> op, string asm, list<dag> pattern>
   : _ArithLogicQI<op, (ins immU5opnd:$imm),
                   !strconcat(asm, " $Rd, $imm"), pattern>;

class _ArithLogicRI<bits<5> op, dag ins, string asm, list<dag> pattern>
   : InstVC32<(outs IntReg:$Rd), ins, asm, pattern> {
  bits<5> Rd;
  bits<16> imm; // Signed

  let Inst{31-26} = 0b101100;
  let Inst{25-21} = op;
  let Inst{20-16} = Rd;
  let Inst{15-0} = imm;
}
class ArithLogicRI<bits<5> op, string asm, list<dag> pattern>
   : _ArithLogicRI<op, (ins IntReg:$src, immS16opnd:$imm), 
                   !strconcat(asm, " $Rd, $imm"), pattern> {
  let Constraints="$src = $Rd";
  let DisableEncoding="$src";
  let isConvertibleToThreeAddress = 1;
}
// Only one input
class ArithLogicRI_1<bits<5> op, string asm, list<dag> pattern>
   : _ArithLogicRI<op, (ins immS16opnd:$imm),
                   !strconcat(asm, " $Rd, $imm"), pattern>;


class _ArithLogicI32<bits<5> op, dag ins, string asm, list<dag> pattern>
   : InstVC48<(outs IntReg:$Rd), ins, asm, pattern> {
  bits<5> Rd;
  bits<32> imm;

  let Inst{47-42} = 0b111010;
  let Inst{41-37} = op;
  let Inst{36-32} = Rd;
  let Inst{31-0} = imm;
}
class ArithLogicI32<bits<5> op, string asm, list<dag> pattern>
   : _ArithLogicI32<op, (ins IntReg:$src, immU32opnd:$imm), 
                   !strconcat(asm, " $Rd, $imm"), pattern> {
  let Constraints="$src = $Rd";
  let DisableEncoding="$src";
  let isConvertibleToThreeAddress = 1;
}
// Only one input
class ArithLogicI32_1<bits<5> op, string asm, list<dag> pattern>
   : _ArithLogicI32<op, (ins immU32opnd:$imm),
                   !strconcat(asm, " $Rd, $imm"), pattern>;






