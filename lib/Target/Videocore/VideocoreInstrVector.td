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

def SextOperand : AsmOperandClass {
  let Name = "Sext";
  let ParserMethod = "parseSext";
  let RenderMethod = "addSext";
}

def Sext : Operand<i32> {
  let PrintMethod = "printSext";
  let ParserMatchClass = SextOperand;
}


class VectorMemory48<bits<7> opc, dag ins, string asmstr>
 : InstVC48<(outs Vector:$Rd), ins, asmstr, []> {
  bits<3>  Rs;
  bits<10> Rd;
  bits<10> Ra;
  bits<1>  z;

  let Inst{47-42} = 0b111100;
  let Inst{41-35} = opc;
  let Inst{34-32} = Rs;
  let Inst{31-22} = Rd;
  let Inst{21-12} = Ra;
  let Inst{11}    = z; // FIXME: isn't used
}

multiclass VectorMemory<bits<7> opc, string asm> {
  // replicate scalar register Rb over all lanes
  def 48sr : VectorMemory48<opc,
        (ins Vector:$Ra, IntReg:$Rb, Scalar8:$Rs, SetF:$F),
        !strconcat(asm, " $Rd, $Ra, (${Rb})$F")> {
    bits<1>  F;
    bits<6> Rb; // FIXME: you ahould only need 4/5 bits to encode Rb, this has 6

    let Inst{10}    = 0;
    let Inst{9-7}   = 0b111;
    let Inst{6}     = F;
    let Inst{5-4}   = 0; // zero out upper bits, to see if they are used.
    let Inst{3-0}   = Rb{3-0};
  }

  def 48r : VectorMemory48<opc, (ins Vector:$Ra, Vector:$Rb, Scalar8:$Rs),
                         !strconcat(asm, " $Rd, $Ra, $Rb")> {
    bits<10> Rb;

    let Inst{10}    = 0;
    let Inst{9-0}   = Rb;
  }

  def 48i : VectorMemory48<opc,
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

defm LD8 : VectorMemory<0x00, "ld8">;
defm LD16 : VectorMemory<0x01, "ld16">;
defm LD32 : VectorMemory<0x02, "ld32">;

defm VLOOKUPMH8  : VectorMemory<0x04, "vlookupmh8">;
defm VLOOKUPMH16 : VectorMemory<0x05, "vlookupmh16">;
defm VLOOKUPMH32 : VectorMemory<0x06, "vlookupmh32">;

defm VLOOKUPML8  : VectorMemory<0x08, "vlookupml8">;
defm VLOOKUPML16 : VectorMemory<0x09, "vlookupml16">;
defm VLOOKUPML32 : VectorMemory<0x0a, "vlookupml32">;

defm VST8  : VectorMemory<0x10, "vst8">;
defm VST16 : VectorMemory<0x11, "vst16">;
defm VST32 : VectorMemory<0x12, "vst32">;

defm VINDEXWRITEMH8  : VectorMemory<0x14, "vindexwritemh8">;
defm VINDEXWRITEMH16 : VectorMemory<0x15, "vindexwritemh16">;
defm VINDEXWRITEMH32 : VectorMemory<0x16, "vindexwritemh32">;

defm VINDEXWRITEML8  : VectorMemory<0x18, "vindexwriteml8">;
defm VINDEXWRITEML16 : VectorMemory<0x19, "vindexwriteml16">;
defm VINDEXWRITEML32 : VectorMemory<0x1a, "vindexwriteml32">;

defm VREADLUT8  : VectorMemory<0x20, "vreadlut8">;
defm VREADLUT16 : VectorMemory<0x21, "vreadlut16">;
defm VREADLUT32 : VectorMemory<0x22, "vreadlut32">;

defm VWRITELUT8  : VectorMemory<0x24, "vwritelut8">;
defm VWRITELUT16 : VectorMemory<0x25, "vwritelut16">;
defm VWRITELUT32 : VectorMemory<0x26, "vwritelut32">;

defm VREADACC    : VectorMemory<0x60, "vreadacc">;
defm VREADACCS32 : VectorMemory<0x61, "vreadaccs32">;
defm VREADACCS16 : VectorMemory<0x63, "vreadaccs16">;


class VectorData48<bits<6> opc, dag ins, string asmstr>
 : InstVC48<(outs Vector:$Rd), ins, asmstr, []> {
  bits<3>  Rs;
  bits<10> Rd;
  bits<10> Ra;
  bits<1>  X;
  bits<1>  z;

  let Inst{47-42} = 0b111101;
  let Inst{41}    = X;
  let Inst{40-35} = opc;
  let Inst{34-32} = Rs;
  let Inst{31-22} = Rd;
  let Inst{21-12} = Ra;
  let Inst{11}    = z; // FIXME: isn't used
}

multiclass VectorData<bits<6> opc, string asm> {
  // replicate scalar register Rb over all lanes
  def 48sr : VectorData48<opc,
        (ins Vector:$Ra, IntReg:$Rb, Scalar8:$Rs, SetF:$F, Sext:$X),
        !strconcat(asm, "$X $Rd, $Ra, (${Rb})$F")> {
    bits<1>  F;
    bits<6> Rb; // FIXME: you should only need 4/5 bits to encode Rb, this has 6

    let Inst{10}    = 0;
    let Inst{9-7}   = 0b111;
    let Inst{6}     = F;
    let Inst{5-4}   = 0; // zero out upper bits, to see if they are used.
    let Inst{3-0}   = Rb{3-0};
  }

  def 48r : VectorData48<opc,
        (ins Vector:$Ra, Vector:$Rb, Scalar8:$Rs, Sext:$X),
        !strconcat(asm, "$X $Rd, $Ra, $Rb")> {
    bits<10> Rb;

    let Inst{10}    = 0;
    let Inst{9-0}   = Rb;
  }

  def 48i : VectorData48<opc,
        (ins Vector:$Ra, immS6opnd:$imm, VectorPred:$P, SetF:$F,
        Scalar8:$Rs, Sext:$X),
        !strconcat(asm, "$X $Rd, $Ra, $imm$F$P")> {
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

  let Inst{79-72} = 0b11111000;
  let Inst{71} = 0;

}
