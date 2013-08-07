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

void VideocoreInstPrinter::
printVector(const MCInst *MI, int opNum, raw_ostream &O) {
  const MCOperand &MO = MI->getOperand(opNum);

  unsigned bits = MO.getImm();
  //assert(bits < 0x3bf && "Vector Operand too large");

  unsigned type = (bits & 0x3c0) >> 6;
  if (type == 0xe) { // Nop vector operand
    O << "-";
    return;
  }
  if (type == 0xf) {
    O << "<invalid>";
    return;
  }

  unsigned X, Y, width;
  char Dir;
  if ((type & 1) == 0) {
    // Horizontal
    Dir = 'H';
    Y = bits & 0x3f;
    switch (type >> 1) {
      case 0: width = 8;  X = 0;  break;
      case 1: width = 8;  X = 16; break;
      case 2: width = 8;  X = 32; break;
      case 3: width = 8;  X = 48; break;
      case 4: width = 16; X = 0;  break;
      case 5: width = 16; X = 32; break;
      case 6: width = 32; X = 0;  break;
    }
  } else {
    // Vertical
    Dir = 'Y';
    unsigned column = bits & 0xf;
    Y = (bits & 0x30);
    switch (type >> 1) {
      case 0: width = 8;  X = 0  + column; break;
      case 1: width = 8;  X = 16 + column; break;
      case 2: width = 8;  X = 32 + column; break;
      case 3: width = 8;  X = 48 + column; break;
      case 4: width = 16; X = 0  + column; break;
      case 5: width = 16; X = 32 + column; break;
      case 6: width = 32; X = 0  + column; break;
    }
  }

  O << Dir;
  if (width != 8)
    O << width;
  O << "(" << Y << ", " << X << ")";
}

void VideocoreInstPrinter::
printVectorPred(const MCInst *MI, int opNum, raw_ostream &O) {
  const MCOperand &MO = MI->getOperand(opNum);

  switch (MO.getImm()) {
    case 0: break;
    case 2: O << " IFZ";  break;
    case 3: O << " IFNZ"; break;
    case 4: O << " IFN";  break;
    case 5: O << " IFNN"; break;
    case 6: O << " IFC";  break;
    case 7: O << " IFNC"; break;
    default: llvm_unreachable("Invalid Vector Predicate");
  }
}

void VideocoreInstPrinter::
printSetF(const MCInst *MI, int opNum, raw_ostream &O) {
  const MCOperand &MO = MI->getOperand(opNum);

  if (MO.getImm()) {
    O << " SETF";
  }
}

void VideocoreInstPrinter::
printSext(const MCInst *MI, int opNum, raw_ostream &O) {
  const MCOperand &MO = MI->getOperand(opNum);

  if (MO.getImm()) {
    // get the destination vector type
    unsigned DestType = (MI->getOperand(0).getImm() & 0x380) >> 7;
    if (DestType == 6) {
      // destination is a 32 bit vector
      O << "L";
    } else if (DestType == 4 || DestType == 5) {
      // destination is a 16 bit vector
      O << "H";
    } else {
      O << "<invalid>";
    }
  }
}

