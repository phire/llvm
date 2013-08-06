//===-- VideocoreBaseInfo.h - definitions for Videocore MC ------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains small standalone helper functions and enum definitions for
// the Videocore target useful for the compiler back-end and the MC libraries.
//
//===----------------------------------------------------------------------===//
#ifndef VIDEOCOREBASEINFO_H
#define VIDEOCOREBASEINFO_H

#include "VideocoreFixupKinds.h"
#include "VideocoreMCTargetDesc.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/Support/DataTypes.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {

// Enums corresponding to Videocore condition codes
namespace VCCC {
  // The CondCodes constants map directly to the 4-bit encoding of the
  // condition field for predicated instructions.
  // Almost the same as ARM condition codes, but LO and HS are swapped.
  // FIXME: floating point meaning untested on videocore
  enum CondCodes { // Meaning (integer)          Meaning (floating-point)
    EQ,            // Equal                      Equal
    NE,            // Not equal                  Not equal, or unordered
    LO,            // Carry set                  >, ==, or unordered
    HS,            // Carry clear                Less than
    MI,            // Minus, negative            Less than
    PL,            // Plus, positive or zero     >, ==, or unordered
    VS,            // Overflow                   Unordered
    VC,            // No overflow                Not unordered
    HI,            // Unsigned higher            Greater than, or unordered
    LS,            // Unsigned lower or same     Less than or equal
    GE,            // Greater than or equal      Greater than or equal
    LT,            // Less than                  Less than, or unordered
    GT,            // Greater than               Greater than
    LE,            // Less than or equal         <, ==, or unordered
    AL             // Always (unconditional)     Always (unconditional)
  };

  inline static CondCodes getOppositeCondition(CondCodes CC) {
  // It turns out that the condition codes have been designed so that in order
  // to reverse the intent of the condition you only have to invert the low bit:

  return static_cast<VCCC::CondCodes>(static_cast<unsigned>(CC) ^ 0x1);
  }
} // namespace VCCC

inline static const char *VCCondCodeToString(VCCC::CondCodes CC) {
  switch (CC) {
  case VCCC::EQ:  return "eq";
  case VCCC::NE:  return "ne";
  case VCCC::HS:  return "hs";
  case VCCC::LO:  return "lo";
  case VCCC::MI:  return "mi";
  case VCCC::PL:  return "pl";
  case VCCC::VS:  return "vs";
  case VCCC::VC:  return "vc";
  case VCCC::HI:  return "hi";
  case VCCC::LS:  return "ls";
  case VCCC::GE:  return "ge";
  case VCCC::LT:  return "lt";
  case VCCC::GT:  return "gt";
  case VCCC::LE:  return "le";
  case VCCC::AL:  return "al";
  }
  llvm_unreachable("Unknown condition code");
}

/// VideocoreII - This namespace holds all of the target specific flags that
/// instruction info tracks.
///
namespace VideocoreII {
  /// Target Operand Flag enum.
  enum TOF {
    //===------------------------------------------------------------------===//
    // Videocore Specific MachineOperand flags.

    MO_NO_FLAG,

    /// MO_GOT16 - Represents the offset into the global offset table at which
    /// the address the relocation entry symbol resides during execution.
    MO_GOT16,
    MO_GOT,

    /// MO_GOT_CALL - Represents the offset into the global offset table at
    /// which the address of a call site relocation entry symbol resides
    /// during execution. This is different from the above since this flag
    /// can only be present in call instructions.
    MO_GOT_CALL,

    /// MO_GPREL - Represents the offset from the current gp value to be used
    /// for the relocatable object file being produced.
    MO_GPREL,

    /// MO_ABS_HI/LO - Represents the hi or low part of an absolute symbol
    /// address.
    MO_ABS_HI,
    MO_ABS_LO,

    /// MO_TLSGD - Represents the offset into the global offset table at which
    // the module ID and TSL block offset reside during execution (General
    // Dynamic TLS).
    MO_TLSGD,

    /// MO_TLSLDM - Represents the offset into the global offset table at which
    // the module ID and TSL block offset reside during execution (Local
    // Dynamic TLS).
    MO_TLSLDM,
    MO_DTPREL_HI,
    MO_DTPREL_LO,

    /// MO_GOTTPREL - Represents the offset from the thread pointer (Initial
    // Exec TLS).
    MO_GOTTPREL,

    /// MO_TPREL_HI/LO - Represents the hi and low part of the offset from
    // the thread pointer (Local Exec TLS).
    MO_TPREL_HI,
    MO_TPREL_LO,

    // N32/64 Flags.
    MO_GPOFF_HI,
    MO_GPOFF_LO,
    MO_GOT_DISP,
    MO_GOT_PAGE,
    MO_GOT_OFST
  };

  enum {
    //===------------------------------------------------------------------===//
    // Instruction encodings.  These are the standard/most common forms for
    // Videocore instructions.
    //

    // Pseudo - This represents an instruction that is a pseudo instruction
    // or one that has not been implemented yet.  It is illegal to code generate
    // it, but tolerated for intermediate implementation stages.
    Pseudo   = 0,

    /// FrmR - This form is for instructions of the format R.
    FrmR  = 1,
    /// FrmI - This form is for instructions of the format I.
    FrmI  = 2,
    /// FrmJ - This form is for instructions of the format J.
    FrmJ  = 3,
    /// FrmFR - This form is for instructions of the format FR.
    FrmFR = 4,
    /// FrmFI - This form is for instructions of the format FI.
    FrmFI = 5,
    /// FrmOther - This form is for instructions that have no specific format.
    FrmOther = 6,

    FormMask = 15
  };
}

/// getVideocoreRegisterNumbering - Given the enum value for some register,
/// return the number that it corresponds to.
inline static unsigned getVideocoreRegisterNumbering(unsigned RegEnum)
{
  switch (RegEnum) {
  case VC::R0:
    return 0;
  case VC::R1:
    return 1;
  case VC::R2:
    return 2;
  case VC::R3:
    return 3;
  case VC::R4:
    return 4;
  case VC::R5:
    return 5;
  case VC::R6:
    return 6;
  case VC::R7:
    return 7;
  case VC::R8:
    return 8;
  case VC::R9:
    return 9;
  case VC::R10:
    return 10;
  case VC::R11:
    return 11;
  case VC::R12:
    return 12;
  case VC::R13:
    return 13;
  case VC::R14:
    return 14;
  case VC::R15:
    return 15;
  case VC::R16:
    return 16;
  case VC::R17:
    return 17;
  case VC::R18:
    return 18;
  case VC::R19:
    return 19;
  case VC::R20:
    return 20;
  case VC::R21:
    return 21;
  case VC::R22:
    return 22;
  case VC::R23:
    return 23;
  case VC::R24:
    return 24;
  case VC::SP:
    return 25;
  case VC::LR:
    return 26;
  case VC::R27:
    return 27;
  case VC::R28:
    return 28;
  case VC::R29:
    return 29;
  case VC::SR:
    return 30;
  case VC::PC:
    return 31;
  default: llvm_unreachable("Unknown register number!");
  }
}

inline static std::pair<const MCSymbolRefExpr*, int64_t>
VideocoreGetSymAndOffset(const MCFixup &Fixup) {
  MCFixupKind FixupKind = Fixup.getKind();

  if ((FixupKind < FirstTargetFixupKind) ||
      (FixupKind >= MCFixupKind(Videocore::LastTargetFixupKind)))
    return std::make_pair((const MCSymbolRefExpr*)0, (int64_t)0);

  const MCExpr *Expr = Fixup.getValue();
  MCExpr::ExprKind Kind = Expr->getKind();

  if (Kind == MCExpr::Binary) {
    const MCBinaryExpr *BE = static_cast<const MCBinaryExpr*>(Expr);
    const MCExpr *LHS = BE->getLHS();
    const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(BE->getRHS());

    if ((LHS->getKind() != MCExpr::SymbolRef) || !CE)
      return std::make_pair((const MCSymbolRefExpr*)0, (int64_t)0);

    return std::make_pair(cast<MCSymbolRefExpr>(LHS), CE->getValue());
  }

  if (Kind != MCExpr::SymbolRef)
    return std::make_pair((const MCSymbolRefExpr*)0, (int64_t)0);

  return std::make_pair(cast<MCSymbolRefExpr>(Expr), 0);
}
}

#endif
