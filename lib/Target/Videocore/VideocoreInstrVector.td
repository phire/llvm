//=== VideooreInstrVector.td - Vector Instructions ---------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the Videocore's vector instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

def VectorOperand : AsmOperandClass {
  let Name = "Vector";
  let ParserMethod = "parseVector";
  let RenderMethod = "addVector";
}

def Vector : Operand<i32> {
    let PrintMethod = "printVector";
    let ParserMatchClass = VectorOperand;
}

def VectorPredOperand : AsmOperandClass {
  let Name = "VectorPred";
  let ParserMethod = "parseVectorPred";
  let RenderMethod = "addVectorPred";
}

def VectorPred : Operand<i32> {
  let PrintMethod = "printVectorPred";
  let ParserMatchClass = VectorPredOperand;
}

def SetFOperand : AsmOperandClass {
  let Name = "SetF";
  let ParserMethod = "parseSetF";
  let RenderMethod = "addSetF";
}

def SetF : Operand<i32> {
  let PrintMethod = "printSetF";
  let ParserMatchClass = SetFOperand;
}



// Just a test for 80 bit vectors
//   44   40   36   32   28   24   20   16   12    8    4    0
// 1111 01Xp pppp psss dddd dddd ddaa aaaa aaaa z0bb bbbb bbbb
class VectorData48<bits<6> opc, dag ins, string asmstr>
 : InstVC48<(outs Vector:$Rd), ins, asmstr, []> {
  bits<3>  Rs;
  bits<10> Rd;
  bits<10> Ra;
  bits<1>  z;

  let Inst{47-42} = 0b111101;
  let Inst{41}    = 0;
  let Inst{40-35} = opc;
  let Inst{34-32} = Rs;
  let Inst{31-22} = Rd;
  let Inst{21-12} = Ra;
  let Inst{11}    = z; // FIXME: isn't used
}

multiclass VectorData<bits<6> opc, string asm> {
  // replicate scalar register Rb over all lanes
  def 48sr : VectorData48<opc,
        (ins Vector:$Ra, IntReg:$Rb, Scalar8:$Rs, SetF:$F),
        !strconcat(asm, " $Rd, $Ra, (${Rb})$F")> {
    bits<1>  F;
    bits<6> Rb; // FIXME: you only need 5 bits to encode Rb, this has 6

    let Inst{10}    = 0;
    let Inst{9-7}   = 0b111;
    let Inst{6}     = F;
    let Inst{5-0}   = Rb;
  }

  def 48r : VectorData48<opc, (ins Vector:$Ra, Vector:$Rb, Scalar8:$Rs),
                         !strconcat(asm, " $Rd, $Ra, $Rb")> {
    bits<10> Rb;

    let Inst{10}    = 0;
    let Inst{9-0}   = Rb;
  }

  def 48i : VectorData48<opc,
        (ins Vector:$Ra, immS6opnd:$imm, VectorPred:$P, SetF:$F, Scalar8:$Rs),
        !strconcat(asm, " $Rd, $Ra, $imm$F$P")> {
    bits<3>  P;
    bits<1>  F;
    bits<6>  imm;

    let Inst{10}    = 1;
    let Inst{9-7}   = P;
    let Inst{6}     = F;
    let Inst{5-0}   = imm;
  }
}

defm VMOV       : VectorData<0, "vmov">;
defm VMASK      : VectorData<1, "vmask">;
defm VEVEN      : VectorData<2, "veven">;
defm VODD       : VectorData<3, "vodd">;
defm VALTL      : VectorData<4, "valtl">;
defm VALTU      : VectorData<5, "valtu">;
defm VBREV      : VectorData<6, "vbrev">;
defm VROR       : VectorData<7, "vror">;

defm VSHL       : VectorData<8, "vshl">;
defm VASLS      : VectorData<9, "vasls">;
defm VLSR       : VectorData<10, "vlsr">;
defm VASR       : VectorData<11, "vasr">;
defm VSSHL      : VectorData<12, "vsshl">;
// unused
defm VSASL      : VectorData<14, "vsasl">;
defm VSASLS     : VectorData<15, "vsasls">;

defm VAND       : VectorData<16, "vand">;
defm VOR        : VectorData<17, "vor">;
defm VEOR       : VectorData<18, "veor">;
defm VBIC       : VectorData<19, "vbic">;
defm VPOPCNT    : VectorData<20, "vpopcnt">;
defm VMSB       : VectorData<21, "vmsb">;
// unused
// unused

defm VMIN       : VectorData<24, "vmin">;
defm VMAX       : VectorData<25, "vmax">;
defm VDIST      : VectorData<26, "vdist">;
defm VDISTS     : VectorData<27, "vdists">;
defm VCLAMP     : VectorData<28, "vclamp">;
defm VSNG       : VectorData<29, "vsng">;
// unused
defm VCMPGE     : VectorData<31, "vcmpge">;

defm VADD       : VectorData<32, "vadd">;
defm VADDS      : VectorData<33, "vadds">;
defm VADDC      : VectorData<34, "vaddc">;
defm VADDSC     : VectorData<35, "vaddsc">;
defm VSUB       : VectorData<36, "vsub">;
defm VSUBS      : VectorData<37, "vsubs">;
defm VSUBC      : VectorData<38, "vsubc">;
defm VSUBSC     : VectorData<39, "vsubsc">;

defm VRSUB      : VectorData<40, "vrsub">;
defm VRSUBS     : VectorData<41, "vrsubs">;
defm VRSUBC     : VectorData<42, "vrsubc">;
defm VRSUBSC    : VectorData<43, "vrsubsc">;
// unused
// unused
// unused
// unused

defm VMULss     : VectorData<48, "vmull.ss">;
defm VMULSss    : VectorData<49, "vmulls.ss">;
defm VMULMDss   : VectorData<50, "vmulmd.ss">;
defm VMULMDSss  : VectorData<51, "vmulmds.ss">;
defm VMULHDss   : VectorData<52, "vmulhd.ss">;
defm VMULHDsu   : VectorData<53, "vmulhd.su">;
defm VMULHDus   : VectorData<54, "vmulhd.us">;
defm VMULHDuu   : VectorData<55, "vmulhd.uu">;

defm VMULHDRss  : VectorData<56, "vmulhdr.ss">;
defm VMULHDRsu  : VectorData<57, "vmulhdr.su">;
defm VMULHDRus  : VectorData<58, "vmulhdr.us">;
defm VMULHDRuu  : VectorData<59, "vmulhdr.uu">;
defm VMULHDTss  : VectorData<60, "vmulhdt.ss">;
defm VMULHDTsu  : VectorData<61, "vmulhdt.su">;
// unused
// unused

def VLDW : InstVC80<(outs), (ins), "vldw", []> {

  let Inst{79-72} = 0b111101;
  let Inst{71} = 0;

}
