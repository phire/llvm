//===-- VideocoreASMBackend.cpp - Videocore Asm Backend  ----------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the VideocoreAsmBackend and VideocoreELFObjectWriter classes.
//
//===----------------------------------------------------------------------===//
//

#include "VideocoreFixupKinds.h"
#include "MCTargetDesc/VideocoreMCTargetDesc.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCDirectives.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCFixupKindInfo.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

// Prepare value for the target space for it
static unsigned adjustFixupValue(unsigned Kind, uint64_t Value) {
    /*
  // Add/subtract and shift
  switch (Kind) {
  default:
    return 0;
  case FK_GPRel_4:
  case FK_Data_4:
  case Videocore::fixup_Videocore_LO16:
    break;
  case Videocore::fixup_Videocore_PC24:
    // So far we are only using this type for branches.
    // For branches we start 1 instruction after the branch
    // so the displacement will be one instruction size less.
    Value -= 4;
    break;
  case Videocore::fixup_Videocore_24:
    // So far we are only using this type for jumps.
    break;
  case Videocore::fixup_Videocore_HI16:
  case Videocore::fixup_Videocore_GOT_Local:
    // Get the higher 16-bits. Also add 1 if bit 15 is 1.
    Value = ((Value + 0x8000) >> 16) & 0xffff;
    break;
  }*/

  return Value;
}

namespace {
class VideocoreAsmBackend : public MCAsmBackend {
  Triple::OSType OSType;

public:
  VideocoreAsmBackend(const Target &T,  Triple::OSType _OSType)
    :MCAsmBackend(), OSType(_OSType) {}

  MCObjectWriter *createObjectWriter(raw_ostream &OS) const {
    return createVideocoreELFObjectWriter(OS, OSType, true);
  }

  /// ApplyFixup - Apply the \arg Value for given \arg Fixup into the provided
  /// data fragment, at the offset specified by the fixup and following the
  /// fixup kind as appropriate.
  void applyFixup(const MCFixup &Fixup, char *Data, unsigned DataSize,
                  uint64_t Value) const {
    MCFixupKind Kind = Fixup.getKind();
    Value = adjustFixupValue((unsigned)Kind, Value);

    if (!Value)
      return; // Doesn't change encoding.

    // Where do we start in the object
    unsigned Offset = Fixup.getOffset();
    // Number of bytes we need to fixup
    unsigned NumBytes = (getFixupKindInfo(Kind).TargetSize + 7) / 8;
    // Used to point to big endian bytes
    unsigned FullSize;

//    switch ((unsigned)Kind) {
 //   case Videocore::fixup_Videocore_16:
//      FullSize = 2;
//      break;
//    default:
      FullSize = 4;
//      break;
//    }

    // Grab current value, if any, from bits.
    uint64_t CurVal = 0;

    for (unsigned i = 0; i != NumBytes; ++i) {
      unsigned Idx = i;
      CurVal |= (uint64_t)((uint8_t)Data[Offset + Idx]) << (i*8);
    }

    uint64_t Mask = ((uint64_t)(-1) >> (64 - getFixupKindInfo(Kind).TargetSize));
    CurVal |= Value & Mask;

    // Write out the fixed up bytes back to the code/data bits.
    for (unsigned i = 0; i != NumBytes; ++i) {
      unsigned Idx = i;
      Data[Offset + Idx] = (uint8_t)((CurVal >> (i*8)) & 0xff);
    }
  }

  unsigned getNumFixupKinds() const { return Videocore::NumTargetFixupKinds; }

  const MCFixupKindInfo &getFixupKindInfo(MCFixupKind Kind) const {
    const static MCFixupKindInfo Infos[Videocore::NumTargetFixupKinds] = {
      // This table *must* be in same the order of fixup_* kinds in
      // VideocoreFixupKinds.h.
      //
      // name                    offset  bits  flags
      { "fixup_Videocore_16",           0,     16,   0 },
      { "fixup_Videocore_32",           0,     32,   0 },
      { "fixup_Videocore_REL32",        0,     32,   0 },
      { "fixup_Videocore_24",           0,     24,   0 },
      { "fixup_Videocore_HI16",         0,     16,   0 },
      { "fixup_Videocore_LO16",         0,     16,   0 },
      { "fixup_Videocore_GPREL16",      0,     16,   0 },
      { "fixup_Videocore_LITERAL",      0,     16,   0 },
      { "fixup_Videocore_GOT_Global",   0,     16,   0 },
      { "fixup_Videocore_GOT_Local",    0,     16,   0 },
      { "fixup_Videocore_PC24",         0,     24,  MCFixupKindInfo::FKF_IsPCRel },
      { "fixup_Videocore_CALL16",       0,     16,   0 },
      { "fixup_Videocore_GPREL32",      0,     32,   0 },
      { "fixup_Videocore_SHIFT5",       6,      5,   0 },
      { "fixup_Videocore_SHIFT6",       6,      5,   0 },
      { "fixup_Videocore_64",           0,     64,   0 },
      { "fixup_Videocore_TLSGD",        0,     16,   0 },
      { "fixup_Videocore_GOTTPREL",     0,     16,   0 },
      { "fixup_Videocore_TPREL_HI",     0,     16,   0 },
      { "fixup_Videocore_TPREL_LO",     0,     16,   0 },
      { "fixup_Videocore_TLSLDM",       0,     16,   0 },
      { "fixup_Videocore_DTPREL_HI",    0,     16,   0 },
      { "fixup_Videocore_DTPREL_LO",    0,     16,   0 },
      { "fixup_Videocore_Branch_PCRel", 0,     16,  MCFixupKindInfo::FKF_IsPCRel }
    };

    if (Kind < FirstTargetFixupKind)
      return MCAsmBackend::getFixupKindInfo(Kind);

    assert(unsigned(Kind - FirstTargetFixupKind) < getNumFixupKinds() &&
           "Invalid kind!");
    return Infos[Kind - FirstTargetFixupKind];
  }

  /// @name Target Relaxation Interfaces
  /// @{

  /// MayNeedRelaxation - Check whether the given instruction may need
  /// relaxation.
  ///
  /// \param Inst - The instruction to test.
  bool mayNeedRelaxation(const MCInst &Inst) const {
    return false;
  }

  /// fixupNeedsRelaxation - Target specific predicate for whether a given
  /// fixup requires the associated instruction to be relaxed.
  bool fixupNeedsRelaxation(const MCFixup &Fixup,
                            uint64_t Value,
                            const MCRelaxableFragment *DF,
                            const MCAsmLayout &Layout) const {
    // FIXME.
    assert(0 && "RelaxInstruction() unimplemented");
    return false;
  }

  /// RelaxInstruction - Relax the instruction in the given fragment
  /// to the next wider instruction.
  ///
  /// \param Inst - The instruction to relax, which may be the same
  /// as the output.
  /// \parm Res [output] - On return, the relaxed instruction.
  void relaxInstruction(const MCInst &Inst, MCInst &Res) const {
  }

  /// @}

  /// WriteNopData - Write an (optimal) nop sequence of Count bytes
  /// to the given output. If the target cannot generate such a sequence,
  /// it should return an error.
  ///
  /// \return - True on success.
  bool writeNopData(uint64_t Count, MCObjectWriter *OW) const {
    return true;
  }
}; // class VideocoreAsmBackend

} // namespace

// MCAsmBackend
MCAsmBackend *llvm::createVideocoreAsmBackend(const Target &T, StringRef TT, StringRef CPU) {
  return new VideocoreAsmBackend(T, Triple(TT).getOS());
}


