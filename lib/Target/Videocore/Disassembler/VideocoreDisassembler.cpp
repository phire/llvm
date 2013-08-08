//===-- VideocoreDisassembler.cpp - Disassembler for Videocore ------------===//
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

#include "MCTargetDesc/VideocoreBinaryInstruction.h"
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
  VideocoreDisassembler(const MCSubtargetInfo &STI, const MCRegisterInfo *Info)
    : MCDisassembler(STI), RegInfo(Info) {}

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
static DecodeStatus DecodeAllRegRegisterClass(MCInst &Inst,
                                                 unsigned RegNo,
                                                 uint64_t Address,
                                                 const void *Decoder) {
  if (RegNo > 31)
    return MCDisassembler::Fail;

  const VideocoreDisassembler *Dis =
                     static_cast<const VideocoreDisassembler*>(Decoder);

  unsigned Reg = Dis->getReg(VC::AllRegRegClassID, RegNo);
  Inst.addOperand(MCOperand::CreateReg(Reg));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeLowRegRegisterClass(MCInst &Inst,
                                              unsigned RegNo,
                                              uint64_t Address,
                                              const void *Decoder) {
  if (RegNo > 16)
    return MCDisassembler::Fail;

  return DecodeAllRegRegisterClass(Inst, RegNo, Address, Decoder);
}

static DecodeStatus DecodeIntRegRegisterClass(MCInst &Inst,
                                                 unsigned RegNo,
                                                 uint64_t Address,
                                                 const void *Decoder) {
  if (RegNo > 30)
    return MCDisassembler::Fail;

  return DecodeAllRegRegisterClass(Inst, RegNo, Address, Decoder);
}

static DecodeStatus DecodeScalar8RegisterClass(MCInst &Inst,
                                                 unsigned RegNo,
                                                 uint64_t Address,
                                                 const void *Decoder) {
  if (RegNo > 7)
    return MCDisassembler::Fail;

  return DecodeAllRegRegisterClass(Inst, RegNo, Address, Decoder);
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

DecodeStatus
VideocoreDisassembler::getInstruction(MCInst &instr,
                                 uint64_t &Size,
                                 const MemoryObject &Region,
                                 uint64_t Address,
                                 raw_ostream &vStream,
                                 raw_ostream &cStream) const {
  DecodeStatus Result;
  VideocoreBinaryInstr Insn(Region, Address);
  Size = Insn.size();

  if (Insn.type() == VideocoreBinaryInstr::Invalid)
    return MCDisassembler::Fail;

  // Calling the auto-generated decoder function.
  const uint8_t *Table;
  switch(Size) {
    case 2:  Table = llvm::DecoderTable16; break;
    case 4:  Table = llvm::DecoderTable32; break;
    case 6:  Table = llvm::DecoderTable48; break;
    case 10: Table = llvm::DecoderTable80; break;
  }

  Result = llvm::decodeInstruction(Table, instr, Insn, Address, this, STI);

  if (Result != MCDisassembler::Fail) {
    return Result;
  }

  switch(Insn.type()) {
  case VideocoreBinaryInstr::Scalar16:
    instr.setOpcode(VC::SCALAR16); break;
  case VideocoreBinaryInstr::Scalar32:
    instr.setOpcode(VC::SCALAR32); break;
  case VideocoreBinaryInstr::Scalar48:
    instr.setOpcode(VC::SCALAR48); break;
  case VideocoreBinaryInstr::Vector48:
    instr.setOpcode(VC::VECTOR48); break;
  case VideocoreBinaryInstr::Vector80:
    instr.setOpcode(VC::VECTOR80); break;
  default:
    return MCDisassembler::Fail;
  }

  return MCDisassembler::SoftFail;
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
