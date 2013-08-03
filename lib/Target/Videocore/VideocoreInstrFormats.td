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

class _RRR<bits<12> op, string asmstr, list<dag> pattern>
  : _R__<op, (ins IntReg:$Ra, IntReg:$Rb, cond_code:$Cond), asmstr, pattern> {
  bits<5> Ra;
  bits<5> Rb;

  let Inst{15-11} = Ra;
  let Inst{6-5} = 0;
  let Inst{4-0} = Rb;
}
class RRR<bits<12> op, string mnemonic, list<dag> pattern> 
   : _RRR<op, !strconcat(mnemonic, "$Cond $Rd, $Ra, $Rb"), pattern>;

class _RRI<bits<12> op, string asmstr, list<dag> pattern>
  : _R__<op, (ins IntReg:$Ra, immS6opnd:$imm, cond_code:$Cond), asmstr, pattern> {
  bits<5> Ra;
  bits<6> imm;

  let Inst{15-11} = Ra;
  let Inst{6} = 1;
  let Inst{5-0} = imm;
}
class RRI<bits<12> op, string mnemonic, list<dag> pattern>
   : _RRI<op, !strconcat(mnemonic, "$Cond $Rd, $Ra, $imm"), pattern>;


// Arithmetic and logic instruction formats

class ArithLogicQQ<bits<5> op, dag ins, string asmstr, list<dag> pattern>
   : InstVC16<(outs LowReg:$Rd), ins, asmstr, pattern> {
  bits<4> Rd;
  bits<4> Rs;

  let Inst{15-13} = 2;
  let Inst{12-8} = op;
  let Inst{7-4} = Rs;
  let Inst{3-0} = Rd;
}

class ArithLogicRR<bits<5> op, dag ins, string asmstr, list<dag> pattern>
   : InstVC32<(outs IntReg:$Rd), ins, asmstr, pattern> {
  bits<5> Rd;
  bits<5> Ra;
  bits<4> Cond;

  let Inst{31-26} = 0x30;
  let Inst{25-21} = op;
  let Inst{20-16} = Rd;
  let Inst{15-11} = Ra;
  let Inst{10-7 } = Cond;
  let Inst{6-5} = 0;
  let Inst{4-0} = 0;
}

class ArithLogicRRR<bits<5> op, dag ins, string asmstr, list<dag> pattern>
   : InstVC32<(outs IntReg:$Rd), ins, asmstr, pattern> {
  bits<5> Rd;
  bits<5> Ra;
  bits<5> Rb;
  bits<4> Cond;

  let Inst{31-26} = 0x30;
  let Inst{25-21} = op;
  let Inst{20-16} = Rd;
  let Inst{15-11} = Ra;
  let Inst{10-7 } = Cond;
  let Inst{6-5} = 0;
  let Inst{4-0} = Rb;

  let isPredicable = 1;
}

class ArithLogicQI<bits<5> op, dag ins, string asmstr, list<dag> pattern>
   : InstVC16<(outs LowReg:$Rd), ins, asmstr, pattern> {
  bits<4> Rd;
  bits<5> imm;

  let Inst{15-13} = 3;
  let Inst{12-9} = op{4-1};
  let Inst{8-4} = imm;
  let Inst{3-0} = Rd;
}

class ArithLogicRI<bits<5> op, dag ins, string asmstr, list<dag> pattern>
   : InstVC32<(outs IntReg:$Rd), ins, asmstr, pattern> {
  bits<5> Rd;
  bits<16> imm; // Signed

  let Inst{31-26} = 0b101100;
  let Inst{25-21} = op;
  let Inst{20-16} = Rd;
  let Inst{15-0} = imm;
}

class ArithLogicRRI<bits<5> op, dag ins, string asmstr, list<dag> pattern>
   : InstVC32<(outs IntReg:$Rd), ins, asmstr, pattern> {
  bits<5> Rd;
  bits<5> Rs;
  bits<4> Cond;
  bits<6> imm; // Signed

  let Inst{31-26} = 0b110000;
  let Inst{25-21} = op;
  let Inst{20-16} = Rd;
  let Inst{15-11} = Rs;
  let Inst{10-7} = Cond;
  let Inst{6} = 1;
  let Inst{5-0} = imm;

  let isPredicable = 1;
}

class ArithLogic48<bits<5> op, dag ins, string asmstr, list<dag> pattern>
   : InstVC48<(outs IntReg:$Rd), ins, asmstr, pattern> {
  bits<5> Rd;
  bits<32> imm;

  let Inst{47-42} = 0b111010;
  let Inst{41-37} = op;
  let Inst{36-32} = Rd;
  let Inst{31-0} = imm;
}





