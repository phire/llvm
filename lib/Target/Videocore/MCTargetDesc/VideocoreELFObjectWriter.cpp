//===-- VideocoreELFObjectWriter.cpp - Videocore ELF Writer -------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/VideocoreBaseInfo.h"
#include "MCTargetDesc/VideocoreFixupKinds.h"
#include "MCTargetDesc/VideocoreMCTargetDesc.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCSection.h"
#include "llvm/MC/MCValue.h"
#include "llvm/Support/ErrorHandling.h"
#include <list>

using namespace llvm;

namespace {
  struct RelEntry {
    RelEntry(const ELFRelocationEntry &R, const MCSymbol *S, int64_t O) :
      Reloc(R), Sym(S), Offset(O) {}
    ELFRelocationEntry Reloc;
    const MCSymbol *Sym;
    int64_t Offset;
  };

  typedef std::list<RelEntry> RelLs;
  typedef RelLs::iterator RelLsIter;

  class VideocoreELFObjectWriter : public MCELFObjectTargetWriter {
  public:
    VideocoreELFObjectWriter(uint8_t OSABI);

    virtual ~VideocoreELFObjectWriter();

    virtual unsigned GetRelocType(const MCValue &Target, const MCFixup &Fixup,
                                  bool IsPCRel, bool IsRelocWithSymbol,
                                  int64_t Addend) const;
    virtual unsigned getEFlags() const;
    virtual const MCSymbol *ExplicitRelSym(const MCAssembler &Asm,
                                           const MCValue &Target,
                                           const MCFragment &F,
                                           const MCFixup &Fixup,
                                           bool IsPCRel) const;
    virtual void sortRelocs(const MCAssembler &Asm,
                            std::vector<ELFRelocationEntry> &Relocs);
  };
}

VideocoreELFObjectWriter::VideocoreELFObjectWriter(uint8_t OSABI)
  : MCELFObjectTargetWriter(/*_is64Bit=false*/ false, OSABI, ELF::EM_VIDEOCORE,
                            /*HasRelocationAddend*/ false) {}

VideocoreELFObjectWriter::~VideocoreELFObjectWriter() {}

// FIXME: get the real EABI Version from the Subtarget class.
unsigned VideocoreELFObjectWriter::getEFlags() const {

  // FIXME: We can't tell if we are PIC (dynamic) or CPIC (static)
  unsigned Flag = 0; //= ELF::EF_VIDEOCORE_NOREORDER;

  //Flag |= ELF::EF_VIDEOCORE_ARCH_32R2;
  return Flag;
}

const MCSymbol *VideocoreELFObjectWriter::ExplicitRelSym(const MCAssembler &Asm,
                                                    const MCValue &Target,
                                                    const MCFragment &F,
                                                    const MCFixup &Fixup,
                                                    bool IsPCRel) const {
  assert(Target.getSymA() && "SymA cannot be 0.");
  const MCSymbol &Sym = Target.getSymA()->getSymbol().AliasedSymbol();

  if (Sym.getSection().getKind().isMergeableCString() ||
      Sym.getSection().getKind().isMergeableConst())
    return &Sym;

  return NULL;
}

unsigned VideocoreELFObjectWriter::GetRelocType(const MCValue &Target,
                                           const MCFixup &Fixup,
                                           bool IsPCRel,
                                           bool IsRelocWithSymbol,
                                           int64_t Addend) const {
  // determine the type of the relocation
  //unsigned Type = (unsigned)ELF::R_VIDEOCORE_NONE;
  unsigned Kind = (unsigned)Fixup.getKind();

  //switch (Kind) {
  //default:
    llvm_unreachable("invalid fixup kind!");
  /*case FK_Data_4:
    Type = ELF::R_VIDEOCORE_32;
    break;
  case FK_GPRel_4:
    Type = ELF::R_VIDEOCORE_GPREL32;
    break;
  case Videocore::fixup_Videocore_GPREL16:
    Type = ELF::R_VIDEOCORE_GPREL16;
    break;
  case Videocore::fixup_Videocore_24:
    Type = ELF::R_VIDEOCORE_24;
    break;
  case Videocore::fixup_Videocore_CALL24:
    Type = ELF::R_VIDEOCORE_CALL24;
    break;
  case Videocore::fixup_Videocore_GOT_Global:
  case Videocore::fixup_Videocore_GOT_Local:
    Type = ELF::R_VIDEOCORE_GOT16;
    break;
  case Videocore::fixup_Videocore_HI16:
    Type = ELF::R_VIDEOCORE_HI16;
    break;
  case Videocore::fixup_Videocore_LO16:
    Type = ELF::R_VIDEOCORE_LO16;
    break;
  case Videocore::fixup_Videocore_TLSGD:
    Type = ELF::R_VIDEOCORE_TLS_GD;
    break;
  case Videocore::fixup_Videocore_GOTTPREL:
    Type = ELF::R_VIDEOCORE_TLS_GOTTPREL;
    break;
  case Videocore::fixup_Videocore_TPREL_HI:
    Type = ELF::R_VIDEOCORE_TLS_TPREL_HI16;
    break;
  case Videocore::fixup_Videocore_TPREL_LO:
    Type = ELF::R_VIDEOCORE_TLS_TPREL_LO16;
    break;
  case Videocore::fixup_Videocore_TLSLDM:
    Type = ELF::R_VIDEOCORE_TLS_LDM;
    break;
  case Videocore::fixup_Videocore_DTPREL_HI:
    Type = ELF::R_VIDEOCORE_TLS_DTPREL_HI16;
    break;
  case Videocore::fixup_Videocore_DTPREL_LO:
    Type = ELF::R_VIDEOCORE_TLS_DTPREL_LO16;
    break;
  case Videocore::fixup_Videocore_Branch_PCRel:
  case Videocore::fixup_Videocore_PC24:
    Type = ELF::R_VIDEOCORE_PC24;
    break;
  }

  return Type;*/
}

static bool HasSameSymbol(const RelEntry &R0, const RelEntry &R1) {
  return R0.Sym == R1.Sym;
}

static int CompareOffset(const RelEntry &R0, const RelEntry &R1) {
  return (R0.Offset > R1.Offset) ? 1 : ((R0.Offset == R1.Offset) ? 0 : -1);
}

void VideocoreELFObjectWriter::sortRelocs(const MCAssembler &Asm,
                                     std::vector<ELFRelocationEntry> &Relocs) {
  // Call the defualt function first. Relocations are sorted in descending
  // order of r_offset.
  MCELFObjectTargetWriter::sortRelocs(Asm, Relocs);
  
  RelLs RelocLs;
  std::vector<RelLsIter> Unmatched;

  // Fill RelocLs. Traverse Relocs backwards so that relocations in RelocLs
  // are in ascending order of r_offset.
  for (std::vector<ELFRelocationEntry>::reverse_iterator R = Relocs.rbegin();
       R != Relocs.rend(); ++R) {
     std::pair<const MCSymbolRefExpr*, int64_t> P =
       VideocoreGetSymAndOffset(*R->Fixup);
     RelocLs.push_back(RelEntry(*R, P.first ? &P.first->getSymbol() : 0,
                                P.second));
  }

  // Put the sorted list back in reverse order.
  assert(Relocs.size() == RelocLs.size());
  unsigned I = RelocLs.size();

  for (RelLsIter R = RelocLs.begin(); R != RelocLs.end(); ++R)
    Relocs[--I] = R->Reloc;
}

MCObjectWriter *llvm::createVideocoreELFObjectWriter(raw_ostream &OS,
                                                uint8_t OSABI,
                                                bool IsLittleEndian) {
  MCELFObjectTargetWriter *MOTW = new VideocoreELFObjectWriter(OSABI);
  return createELFObjectWriter(MOTW, OS, IsLittleEndian);
}
