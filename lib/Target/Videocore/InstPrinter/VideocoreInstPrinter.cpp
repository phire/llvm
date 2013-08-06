//===- VideocoreInstPrinter.cpp - Convert Videocore MCInst to asm syntax --===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints an Videocore MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "asm-printer"
#include "VideocoreInstPrinter.h"
#include "MCTargetDesc/VideocoreBaseInfo.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
using namespace llvm;

#include "VideocoreGenAsmWriter.inc"

void VideocoreInstPrinter::printRegName(raw_ostream &OS, unsigned RegNo) const {
    OS << StringRef(getRegisterName(RegNo)).lower();
}

void VideocoreInstPrinter::printInst(const MCInst *MI, raw_ostream &OS, 
                                                            StringRef Annot) {
    printInstruction(MI, OS);
    printAnnotation(OS, Annot);
}

static void printExpr(const MCExpr *Expr, raw_ostream &OS) {
  int Offset = 0;
  const MCSymbolRefExpr *SRE;

  if (const MCBinaryExpr *BE = dyn_cast<MCBinaryExpr>(Expr)) {
    SRE = dyn_cast<MCSymbolRefExpr>(BE->getLHS());
    const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(BE->getRHS());
    assert(SRE && CE && "Binary expression must be sym+const.");
    Offset = CE->getValue();
  }
  else if (!(SRE = dyn_cast<MCSymbolRefExpr>(Expr)))
    assert(false && "Unexpected MCExpr type.");

  MCSymbolRefExpr::VariantKind Kind = SRE->getKind();

  switch (Kind) {
  default:                                 llvm_unreachable("Invalid kind!");
  case MCSymbolRefExpr::VK_None:           break;
  }

  OS << SRE->getSymbol();

  if (Offset) {
    if (Offset > 0)
      OS << '+';
    OS << Offset;
  }

  if (Kind != MCSymbolRefExpr::VK_None)
    OS << ')';
}

void VideocoreInstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &O) {
  assert(OpNo < MI->getNumOperands() && "Not enough operands");

  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isReg()) {
    printRegName(O, Op.getReg());
    return;
  }

  if (Op.isImm()) {
    O << Op.getImm();
    return;
  }

  assert(Op.isExpr() && "unknown operand kind in printOperand");
  printExpr(Op.getExpr(), O);
}

void VideocoreInstPrinter::printUnsignedImm(const MCInst *MI, int opNum,
                                       raw_ostream &O) {
  const MCOperand &MO = MI->getOperand(opNum);
  if (MO.isImm())
    O << (unsigned short int)MO.getImm();
  else
    printOperand(MI, opNum, O);
}

void VideocoreInstPrinter::printU5ImmOperand(const MCInst *MI, int OpNo,
                                               raw_ostream &O) {
    unsigned int Value = MI->getOperand(OpNo).getImm();
    assert(Value <= 31 && "Invalid u5imm argument!");
    O << (unsigned int)Value;
}

void VideocoreInstPrinter::printU6ImmOperand(const MCInst *MI, int OpNo,
                                               raw_ostream &O) {
    unsigned int Value = MI->getOperand(OpNo).getImm();
    assert(Value <= 63 && "Invalid u6imm argument!");
    O << (unsigned int)Value;
}


void VideocoreInstPrinter::printSignedImmOperand(const MCInst *MI, int OpNo,
                                               raw_ostream &O) {
    unsigned int Value = MI->getOperand(OpNo).getImm();
    O << (int)Value;
}

void VideocoreInstPrinter::printSignedShl2Operand(const MCInst *MI, int OpNo,
                                               raw_ostream &O) {
    unsigned int Value = MI->getOperand(OpNo).getImm();
    O << ((int)Value << 2);
}

void VideocoreInstPrinter::printU32ImmOperand(const MCInst *MI, int OpNo,
                                               raw_ostream &O) {
    unsigned int Value = MI->getOperand(OpNo).getImm();
    O << (unsigned int)Value;
}


void VideocoreInstPrinter::
printMemOperand(const MCInst *MI, int opNum, raw_ostream &O) {
  // Load/Store memory operands -- imm($reg)
  // If PIC target the target is loaded as the
  // pattern ld $t9,%call24($gp)
  O << "(";
  printOperand(MI, opNum, O);

  MCOperand opnd2 = MI->getOperand(opNum+1);

  if(opnd2.isImm() && opnd2.getImm() < 0) {
    O << "-";
    O << (int) opnd2.getImm() * -1;
  } else {
    O << "+";
    printOperand(MI, opNum+1, O);
  }
  O << ")";
}

void VideocoreInstPrinter::
printCondCodeOperand(const MCInst *MI, int opNum, raw_ostream &O) {
  const MCOperand &MO = MI->getOperand(opNum);

  O << VCCondCodeToString(static_cast<VCCC::CondCodes>(MO.getImm()));
}
