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

  field bits<32> SoftFail = 0;
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



