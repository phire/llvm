//==---- VideocoreInstPrinter.h - Convert X86 MCInst to assembly syntax -----=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints an Videocore MCInst to AT&T style .s file syntax.
//
//===----------------------------------------------------------------------===//

#ifndef VIDEOCORE_INST_PRINTER_H
#define VIDEOCORE_INST_PRINTER_H

#include "llvm/MC/MCInstPrinter.h"

namespace llvm {

  class TargetMachine;

    class VideocoreInstPrinter : public MCInstPrinter {
public:
  VideocoreInstPrinter(const MCAsmInfo &MAI, const MCInstrInfo &MII,
                  const MCRegisterInfo &MRI)
    : MCInstPrinter(MAI, MII, MRI) {}

  // Autogenerated by tblgen.
  void printInstruction(const MCInst *MI, raw_ostream &O);
  static const char *getRegisterName(unsigned RegNo);

  virtual void printRegName(raw_ostream &OS, unsigned RegNo) const;
  virtual void printInst(const MCInst *MI, raw_ostream &O, StringRef Annot);

private:
  void printOperand(const MCInst *MI, unsigned OpNo, raw_ostream &O);
  void printUnsignedImm(const MCInst *MI, int opNum, raw_ostream &O);
  void printU5ImmOperand(const MCInst *MI, int opNum, raw_ostream &O);
  void printS16ImmOperand(const MCInst *MI, int opNum, raw_ostream &O);
  void printU32ImmOperand(const MCInst *MI, int opNum, raw_ostream &O);
  void printMemOperand(const MCInst *MI, int opNum, raw_ostream &O);
};
}

#endif
