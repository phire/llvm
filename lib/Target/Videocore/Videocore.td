//===-- Videocore.td - Describe Videoore Target Machine 000-*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This is the top level entry point for the Videocore target.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Target-independent interfaces which we are implementing
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

//===----------------------------------------------------------------------===//
// Descriptions
//===----------------------------------------------------------------------===//

include "VideocoreRegisterInfo.td"
include "VideocoreInstrInfo.td"
include "VideocoreCallingConv.td"

def VideocoreInstrInfo : InstrInfo;

//===----------------------------------------------------------------------===//
// Videocore processors supported.
//===----------------------------------------------------------------------===//

class Proc<string Name, list<SubtargetFeature> Features>
 : Processor<Name, NoItineraries, Features>;

def : Proc<"generic",      []>;

//===----------------------------------------------------------------------===//
// Assembly parser
//===----------------------------------------------------------------------===//

def VideocoreAsmParser : AsmParser {
  let ShouldEmitMatchRegisterName = 1;
}

//===----------------------------------------------------------------------===//
// Assembly writer
//===----------------------------------------------------------------------===//

def VideocoreAsmWriter : AsmWriter {
    string AsmWriterClassName = "InstPrinter";
    bit isMCAsmWriter = 1;
}

//===----------------------------------------------------------------------===//
// Declare the target which we are implementing
//===----------------------------------------------------------------------===//

def Videocore : Target {
  // Pull in Instruction Info:
  let InstructionSet = VideocoreInstrInfo;
  let AssemblyParsers = [VideocoreAsmParser];
  let AssemblyWriters = [VideocoreAsmWriter];
}
