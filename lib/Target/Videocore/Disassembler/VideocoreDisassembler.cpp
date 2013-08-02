//===- VideocoreDisassembler.cpp - Disassembler for Videocore ---*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file is part of the Videocore Disassembler.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "vc-disassembler"

#include "Videocore.h"
#include "VideocoreRegisterInfo.h"
#include "VideocoreSubtarget.h"
#include "llvm/MC/MCDisassembler.h"
#include "llvm/MC/MCFixedLenDisassembler.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/MemoryObject.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

typedef MCDisassembler::DecodeStatus DecodeStatus;

namespace {

class VideocoreDisassembler : public MCDisassembler {
public:
  /// Constructor     - Initializes the disassembler.
  ///
  VideocoreDisassembler(const MCSubtargetInfo &STI, const MCRegisterInfo *Info) : 
    MCDisassembler(STI), RegInfo(Info) {}

  virtual ~VideocoreDisassembler() {}

  /// getInstruction - See MCDisassembler.
  virtual DecodeStatus getInstruction(MCInst &instr,
                                      uint64_t &size,
                                      const MemoryObject &region,
                                      uint64_t address,
                                      raw_ostream &vStream,
                                      raw_ostream &cStream) const;

  unsigned getReg(unsigned RC, unsigned RegNo) const {
    return *(RegInfo->getRegClass(RC).begin() + RegNo);
  }

private:
  const MCRegisterInfo *RegInfo;
};

// Functions used by TableGen Disassembler

static DecodeStatus DecodeLowRegRegisterClass(MCInst &Inst,
                                                 unsigned RegNo,
                                                 uint64_t Address,
                                                 const void *Decoder) {
  if (RegNo > 16)
    return MCDisassembler::Fail;

  const VideocoreDisassembler *Dis = static_cast<const VideocoreDisassembler*>(Decoder);

  unsigned Reg = Dis->getReg(VC::LowRegRegClassID, RegNo);
  Inst.addOperand(MCOperand::CreateReg(Reg));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeIntRegRegisterClass(MCInst &Inst,
                                                 unsigned RegNo,
                                                 uint64_t Address,
                                                 const void *Decoder) {
  if (RegNo > 30)
    return MCDisassembler::Fail;

  const VideocoreDisassembler *Dis = static_cast<const VideocoreDisassembler*>(Decoder);

  unsigned Reg = Dis->getReg(VC::IntRegRegClassID, RegNo);
  Inst.addOperand(MCOperand::CreateReg(Reg));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeAllRegRegisterClass(MCInst &Inst,
                                                 unsigned RegNo,
                                                 uint64_t Address,
                                                 const void *Decoder) {
  if (RegNo > 31)
    return MCDisassembler::Fail;

  const VideocoreDisassembler *Dis = static_cast<const VideocoreDisassembler*>(Decoder);

  unsigned Reg = Dis->getReg(VC::AllRegRegClassID, RegNo);
  Inst.addOperand(MCOperand::CreateReg(Reg));
  return MCDisassembler::Success;
}

// xxxx xxxo xxxd dddd ssss sooo oooo oooo
static DecodeStatus DecodeMem_5_12(MCInst &MI, 
                                   unsigned insn,
                                   uint64_t Address,
                                   const void *Decoder) {
  unsigned rd = (insn >> 16) & 0x1f;
  if (DecodeIntRegRegisterClass(MI, rd, Address, Decoder) == MCDisassembler::Fail) 
    return MCDisassembler::Fail;

  unsigned rs = (insn >> 11) & 0x1f;
  if (DecodeIntRegRegisterClass(MI, rs, Address, Decoder) == MCDisassembler::Fail) 
    return MCDisassembler::Fail;

  signed int offset = (insn & 0x7ff);
  if ((insn & 0x01000000) != 0)
    offset |= 0xfffff800; // Sign extend
  MI.addOperand(MCOperand::CreateImm(offset));

  return MCDisassembler::Success;
}

#include "VideocoreGenDisassemblerTables.inc"

  /// readInstruction - read the correct number of bytes from the 
  /// MemoryObject and the full instruction in the correct bit order
static DecodeStatus readInstruction(const MemoryObject &region,
                                      uint64_t address,
                                      uint64_t &size,
                                      uint64_t &insn) {
  uint8_t bytes[4];
  size = 2; // if we are going to fail, we need to eat at least 2 bytes

  // Read the frist 16 bytes, to determin the length of the instruction
  if (region.readBytes(address, 2, (uint8_t*)bytes, NULL) == -1) {
    return MCDisassembler::Fail;
  }
  uint16_t word = bytes[0] | bytes[1] << 8;

  if ((word & 0x8000) == 0x0000) { // 0xxx xxxx xxxx xxxx - 16 bits
    insn = word;
    size = 2;
    return MCDisassembler::Success;
  }
  if ((word & 0xa000) == 0x8000) { // 1x0x xxxx xxxx xxxx - 32 bits
    if (region.readBytes(address+2, 2, (uint8_t*)bytes, NULL) != -1) {
      insn = (uint32_t)(word << 16 | bytes[1] << 8 | bytes[0]);
      size = 4;
      return MCDisassembler::Success;
    }
  }
  if ((word & 0xf000) == 0xe000) { // 1110 xxxx xxxx xxxx - 48 bits
    if (region.readBytes(address+2, 4, (uint8_t*)bytes, NULL) != -1) {
      insn = bytes[3] << 24 | bytes[2] << 16 | bytes[1] << 8 | bytes[0];
      insn |= ((uint64_t)word) << 32;
      size = 6;
      return MCDisassembler::Success;
    }
  }
  if ((word & 0xf000) == 0xf000) { // 1111 xxxx xxxx xxxx - vector 48/80 bits
    // Vector instruction
    size = (word & 0x01000) ? 10 : 6;
    return MCDisassembler::Fail; // Unimplemented
  }

  return MCDisassembler::Fail; // readBytes failed
}

DecodeStatus
VideocoreDisassembler::getInstruction(MCInst &instr,
                                 uint64_t &Size,
                                 const MemoryObject &Region,
                                 uint64_t Address,
                                 raw_ostream &vStream,
                                 raw_ostream &cStream) const {
  uint64_t Insn = 0;
 
  DecodeStatus Result = readInstruction(Region, Address, Size, Insn);

  if (Result == MCDisassembler::Fail)
    return MCDisassembler::Fail;

  // Calling the auto-generated decoder function.
  const uint8_t *DecodeTable;
  switch(Size) {
    case 2: DecodeTable = llvm::DecoderTable16; break;
    case 4: DecodeTable = llvm::DecoderTable32; break;
    case 6: DecodeTable = llvm::DecoderTable48; break;
  }

  Result = llvm::decodeInstruction(DecodeTable, instr, Insn, Address, this, STI);

  if (Result != MCDisassembler::Fail) {
    return Result;
  }

  return MCDisassembler::Fail;
}

} //namespace

namespace llvm {
static MCDisassembler *createVideocoreDisassembler(const Target &T,
                                                const MCSubtargetInfo &STI) {
  return new VideocoreDisassembler(STI, T.createMCRegInfo(""));
}

extern "C" void LLVMInitializeVideocoreDisassembler() { 
  // Register the disassembler.
  TargetRegistry::RegisterMCDisassembler(TheVideocoreTarget, 
                                         createVideocoreDisassembler);
}
} // namespace llvm
