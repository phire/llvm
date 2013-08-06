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
def VMOVr : InstVC48<(outs Vector:$Rd),
                    (ins Vector:$Ra, Vector:$Rb, Scalar8:$Rs),
                    "vmov $Rd, $Ra, $Rb", []> {
  bits<3>  Rs;
  bits<10> Rd;
  bits<10> Ra;
  bits<10> Rb;
  bits<1>  z;

  let Inst{47-42} = 0b111101;
  let Inst{41}    = 0;
  let Inst{40-35} = 0;
  let Inst{34-32} = Rs;
  let Inst{31-22} = Rd;
  let Inst{21-12} = Ra;
  let Inst{11}    = z;
  let Inst{10}    = 0;
  let Inst{9-0}   = Rb;
}

//   44   40   36   32   28   24   20   16   12    8    4    0
// 1111 01Xp pppp psss dddd dddd ddaa aaaa aaaa z1PP PFii iiii
def VMOVi : InstVC48<(outs Vector:$Rd),
                    (ins Vector:$Ra, immS6opnd:$imm, VectorPred:$P, SetF:$F, Scalar8:$Rs),
                    "vmov $Rd, $Ra, $imm$F$P", []> {
  bits<3>  Rs;
  bits<10> Rd;
  bits<10> Ra;
  bits<1>  z;
  bits<3>  P;
  bits<1>  F;
  bits<6>  imm;

  let Inst{47-42} = 0b111101;
  let Inst{41}    = 0;
  let Inst{40-35} = 0;
  let Inst{34-32} = Rs;
  let Inst{31-22} = Rd;
  let Inst{21-12} = Ra;
  let Inst{11}    = z;
  let Inst{10}    = 1;
  let Inst{9-7}   = P;
  let Inst{6}     = F;
  let Inst{5-0}   = imm;
}

def VLDW : InstVC80<(outs), (ins), "vldw", []> {

  let Inst{79-72} = 0b111101;
  let Inst{71} = 0;

}
