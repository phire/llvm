//=== VideocoreFixupKinds.h -- Videocore Specific Fixup Entries -*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_VIDEOCORE_VIDEOCOREFIXUPKINDS_H
#define LLVM_VIDEOCORE_VIDEOCOREFIXUPKINDS_H

#include "llvm/MC/MCFixup.h"

namespace llvm {
namespace Videocore {
  // Although most of the current fixup types reflect a unique relocation
  // one can have multiple fixup types for a given relocation and thus need
  // to be uniquely named.
  //
  // This table *must* be in the save order of
  // MCFixupKindInfo Infos[Videocore::NumTargetFixupKinds]
  // in VideocoreAsmBackend.cpp.
  //
  enum Fixups {
    // Branch fixups resulting in R_VIDEOCORE_16.
    fixup_Videocore_16 = FirstTargetFixupKind,

    // Pure 32 bit data fixup resulting in - R_VIDEOCORE_32.
    fixup_Videocore_32,

    // Full 32 bit data relative data fixup resulting in - R_VIDEOCORE_REL32.
    fixup_Videocore_REL32,

    // Jump 26 bit fixup resulting in - R_VIDEOCORE_26.
    fixup_Videocore_24,

    // Pure upper 16 bit fixup resulting in - R_VIDEOCORE_HI16.
    fixup_Videocore_HI16,

    // Pure lower 16 bit fixup resulting in - R_VIDEOCORE_LO16.
    fixup_Videocore_LO16,

    // 16 bit fixup for GP offest resulting in - R_VIDEOCORE_GPREL16.
    fixup_Videocore_GPREL16,

    // 16 bit literal fixup resulting in - R_VIDEOCORE_LITERAL.
    fixup_Videocore_LITERAL,

    // Global symbol fixup resulting in - R_VIDEOCORE_GOT16.
    fixup_Videocore_GOT_Global,

    // Local symbol fixup resulting in - R_VIDEOCORE_GOT16.
    fixup_Videocore_GOT_Local,

    // PC relative branch fixup resulting in - R_VIDEOCORE_PC24.
    // cpu0 PC24, e.g. jeq
    fixup_Videocore_PC24,

    // resulting in - R_VIDEOCORE_CALL24.
    fixup_Videocore_CALL24,

    // resulting in - R_VIDEOCORE_GPREL32.
    fixup_Videocore_GPREL32,

    // resulting in - R_VIDEOCORE_SHIFT5.
    fixup_Videocore_SHIFT5,

    // resulting in - R_VIDEOCORE_SHIFT6.
    fixup_Videocore_SHIFT6,

    // Pure 64 bit data fixup resulting in - R_VIDEOCORE_64.
    fixup_Videocore_64,

    // resulting in - R_VIDEOCORE_TLS_GD.
    fixup_Videocore_TLSGD,

    // resulting in - R_VIDEOCORE_TLS_GOTTPREL.
    fixup_Videocore_GOTTPREL,

    // resulting in - R_VIDEOCORE_TLS_TPREL_HI16.
    fixup_Videocore_TPREL_HI,

    // resulting in - R_VIDEOCORE_TLS_TPREL_LO16.
    fixup_Videocore_TPREL_LO,

    // resulting in - R_VIDEOCORE_TLS_LDM.
    fixup_Videocore_TLSLDM,

    // resulting in - R_VIDEOCORE_TLS_DTPREL_HI16.
    fixup_Videocore_DTPREL_HI,

    // resulting in - R_VIDEOCORE_TLS_DTPREL_LO16.
    fixup_Videocore_DTPREL_LO,

    // PC relative branch fixup resulting in - R_VIDEOCORE_PC16
    fixup_Videocore_Branch_PCRel,

    // Marker
    LastTargetFixupKind,
    NumTargetFixupKinds = LastTargetFixupKind - FirstTargetFixupKind
  };
} // namespace Videocore
} // namespace llvm


#endif // LLVM_VIDEOCORE_VIDEOCOREFIXUPKINDS_H
