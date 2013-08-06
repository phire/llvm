//===-- VideocoreRegisterInfo.td - Videocore Register defs -*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the VideoCore 4 register file
//===----------------------------------------------------------------------===//

class VideocoreReg<string n, list<string> alt> : Register<n, alt> {
  field bits<5> Num;
  let Namespace = "VC";
}

class Ri<bits<5> num, string n, list<string> alt = []> : VideocoreReg<n, alt> {
  let Num = num;
}

// Integer registers
foreach i = 0-15 in
    def R#i : Ri< i, "r"#i >, DwarfRegNum<[i]>;
// Not all instruction encodings can access these registers
let CostPerUse = 1 in {
  foreach i = [16,17,18,19,20,21,22,23,24,27,28,29] in
    def R#i : Ri< i, "r"#i >, DwarfRegNum<[i]>;

  def SP  : Ri<25, "sp", ["R25"]>, DwarfRegNum<[25]>;
  def LR  : Ri<26, "lr", ["R26"]>, DwarfRegNum<[26]>;
  def SR  : Ri<30, "sr", ["R30"]>, DwarfRegNum<[30]>;
  def PC  : Ri<31, "pc", ["R31"]>, DwarfRegNum<[31]>;
}

// Register classes.
def AllReg : RegisterClass<"VC", [i32], 32,
                            (add R0, R1, R2, R3, R4, R5, R6,
                                 R7, R8, R9, R10, R11, R12, R13,
                                 R14, R15, R16, R17, R18, R19, R20,
                                 R21, R22, R23, R24, SP, LR, R27,
                                 R28, R29, SR, PC)>;

def IntReg : RegisterClass<"VC", [i32], 32,
                            (add R0, R1, R2, R3, R4, R5, R6,
                                 R7, R8, R9, R10, R11, R12, R13,
                                 R14, R15, R16, R17, R18, R19, R20,
                                 R21, R22, R23, R24, SP, LR, R27,
                                 R28, R29, SR)>; // excluding PC

def LowReg : RegisterClass<"VC", [i32], 32,
                            (add R0, R1, R2, R3, R4, R5, R6,
                                 R7, R8, R9, R10, R11, R12, R13,
                                 R14, R15)>;

def FloatReg : RegisterClass<"VC", [f32], 32,
                            (add R0, R1, R2, R3, R4, R5, R6,
                                 R7, R8, R9, R10, R11, R12, R13,
                                 R14, R15, R16, R17, R18, R19, R20,
                                 R21, R22, R23, R24, R27, R28, R29)>;

// Flags register
def NZCV : Register<"nzcv"> {
  let Namespace = "VC";
}

def FlagClass : RegisterClass<"VC", [i32], 32, (add NZCV)> {
  let CopyCost = -1;
  let isAllocatable = 0;
}
