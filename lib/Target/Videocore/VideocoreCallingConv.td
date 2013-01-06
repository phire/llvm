//===-- VideocoreCallingConv.td - Calling Conventions Videocore ----*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This describes the calling conventions for the Videocore architectures.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Return Value Calling Conventions
//===----------------------------------------------------------------------===//

// VC4 32-bit C return-value convention.
def RetCC_VC4 : CallingConv<[
  CCIfType<[i1, i8, i16], CCPromoteToType<i32>>,

  CCIfType<[f32], CCBitConvertToType<i32>>,
  CCIfType<[i32], CCAssignToReg<[R0, R1, R2, R3]>>
]>;

// VC4 32-bit C Calling convention.
def CC_VC4 : CallingConv<[
  // i32 f32 arguments get passed in integer registers if there is space.

  CCIfByVal<CCPassByVal<4, 4>>,
  CCIfType<[i1, i8, i16], CCPromoteToType<i32>>,

  CCIfType<[f32], CCBitConvertToType<i32>>,
  CCIfType<[i32], CCAssignToReg<[R0, R1, R2, R3, R4, R5]>>,

  // Alternatively, they are assigned to the stack in 4-byte aligned units.
  CCAssignToStack<4, 4>
]>;

def CSR_VC4 : CalleeSavedRegs<(add (sequence "R%u", 6, 24), SP, LR, R27, R28, R29)>;
