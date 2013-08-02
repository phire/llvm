//===-- VideocoreMCCodeEmitter.cpp - Convert Videocore Code to Machine Code ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the VideocoreMCCodeEmitter class.
//
//===----------------------------------------------------------------------===//
//
#define DEBUG_TYPE "mccodeemitter"
#include "MCTargetDesc/VideocoreBaseInfo.h"
#include "MCTargetDesc/VideocoreFixupKinds.h"
#include "MCTargetDesc/VideocoreMCTargetDesc.h"
#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

namespace {
class VideocoreMCCodeEmitter : public MCCodeEmitter {
  VideocoreMCCodeEmitter(const VideocoreMCCodeEmitter &); // DO NOT IMPLEMENT
  void operator=(const VideocoreMCCodeEmitter &); // DO NOT IMPLEMENT
  const MCInstrInfo &MCII;
  const MCSubtargetInfo &STI;
  MCContext &Ctx;

public:
  VideocoreMCCodeEmitter(const MCInstrInfo &mcii, const MCSubtargetInfo &sti,
                    MCContext &ctx) :
            MCII(mcii), STI(sti) , Ctx(ctx) {}

  ~VideocoreMCCodeEmitter() {}

  void EmitShort(unsigned short S, raw_ostream &OS) const {
    OS << (char)(S & 0xff);
    OS << (char)(S >> 8);
  }

  void EmitInstruction(uint64_t Val, unsigned Size, raw_ostream &OS) const {
    // Output the instruction encoding in little endian byte order.
    for (unsigned i = Size/2; i > 0;) {
      unsigned Shift =  --i * 16;
      EmitShort((Val >> Shift) & 0xffff, OS);
    }
  }

  void EncodeInstruction(const MCInst &MI, raw_ostream &OS,
                         SmallVectorImpl<MCFixup> &Fixups) const;
  // getBinaryCodeForInstr - TableGen'erated function for getting the
  // binary encoding for an instruction.
  uint64_t getBinaryCodeForInstr(const MCInst &MI,
                                 SmallVectorImpl<MCFixup> &Fixups) const;
   // getMachineOpValue - Return binary encoding of operand. If the machin
   // operand requires relocation, record the relocation and return zero.
  unsigned getMachineOpValue(const MCInst &MI,const MCOperand &MO,
                             SmallVectorImpl<MCFixup> &Fixups) const;

  unsigned getMemEncoding(const MCInst &MI, unsigned OpNo,
                          SmallVectorImpl<MCFixup> &Fixups) const;
}; // class VideocoreMCCodeEmitter
}  // namespace

MCCodeEmitter *llvm::createVideocoreMCCodeEmitter(const MCInstrInfo &MCII,
                                               const MCRegisterInfo &RI,
                                               const MCSubtargetInfo &STI,
                                               MCContext &Ctx)
{
  return new VideocoreMCCodeEmitter(MCII, STI, Ctx);
}

/// EncodeInstruction - Emit the instruction.
/// Size the instruction (currently only 4 bytes
void VideocoreMCCodeEmitter::
EncodeInstruction(const MCInst &MI, raw_ostream &OS,
                  SmallVectorImpl<MCFixup> &Fixups) const
{
  uint64_t Binary = getBinaryCodeForInstr(MI, Fixups);

  // Check for unimplemented opcodes.
  unsigned Opcode = MI.getOpcode();
  if (!Binary)
    llvm_unreachable("unimplemented opcode in EncodeInstruction()");

  const MCInstrDesc &Desc = MCII.get(MI.getOpcode());
  uint64_t TSFlags = Desc.TSFlags;

  // Pseudo instructions don't get encoded and shouldn't be here
  // in the first place!
  //if ((TSFlags & VideocoreII::FormMask) == VideocoreII::Pseudo)
    //llvm_unreachable("Pseudo opcode found in EncodeInstruction()");

  EmitInstruction(Binary, Desc.Size, OS);
}

/// getMachineOpValue - Return binary encoding of operand. If the machine
/// operand requires relocation, record the relocation and return zero.
unsigned VideocoreMCCodeEmitter::
getMachineOpValue(const MCInst &MI, const MCOperand &MO,
                  SmallVectorImpl<MCFixup> &Fixups) const {
  if (MO.isReg()) {
    unsigned Reg = MO.getReg();
    unsigned RegNo = getVideocoreRegisterNumbering(Reg);
    return RegNo;
  } else if (MO.isImm()) {
    return static_cast<unsigned>(MO.getImm());
  } else if (MO.isFPImm()) {
    return static_cast<unsigned>(APFloat(MO.getFPImm())
        .bitcastToAPInt().getHiBits(32).getLimitedValue());
  } 

  // MO must be an Expr.
  assert(MO.isExpr());

  const MCExpr *Expr = MO.getExpr();
  MCExpr::ExprKind Kind = Expr->getKind();

  if (Kind == MCExpr::Binary) {
    Expr = static_cast<const MCBinaryExpr*>(Expr)->getLHS();
    Kind = Expr->getKind();
  }

  assert (Kind == MCExpr::SymbolRef);

  // All of the information is in the fixup.
  return 0;
}

/// getMemEncoding - Return binary encoding of memory related operand.
/// If the offset operand requires relocation, record the relocation.
unsigned
VideocoreMCCodeEmitter::getMemEncoding(const MCInst &MI, unsigned OpNo,
                                  SmallVectorImpl<MCFixup> &Fixups) const {
  llvm_unreachable("Unimplemented");
  // Base register is encoded in bits 20-16, offset is encoded in bits 15-0.
  assert(MI.getOperand(OpNo).isReg());
  unsigned RegBits = getMachineOpValue(MI, MI.getOperand(OpNo),Fixups) << 16;
  unsigned OffBits = getMachineOpValue(MI, MI.getOperand(OpNo+1), Fixups);

  return (OffBits & 0xFFFF) | RegBits;
}

#include "VideocoreGenMCCodeEmitter.inc"

