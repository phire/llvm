

#define DEBUG_TYPE "asm-printer"
#include "VideocoreAsmPrinter.h"
#include "VideocoreTargetMachine.h"
#include "InstPrinter/VideocoreInstPrinter.h"
#include "VideocoreMCInstLower.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCInst.h"
#include "llvm/Support/TargetRegistry.h"
#include "VideocoreISelLowering.h"

using namespace llvm;


void VideocoreAsmPrinter::EmitInstruction(const MachineInstr *MI) {
    if (MI->isDebugValue()) {
        SmallString<128> Str;
        raw_svector_ostream O(Str);

        PrintDebugValueComment(MI, O);
        return;
    }

    MCInst TmpInst;
    MCInstLowering.Lower(MI, TmpInst);
    OutStreamer.EmitInstruction(TmpInst);
}

void VideocoreAsmPrinter::PrintDebugValueComment(const MachineInstr *MI,
                                           raw_ostream &OS) {
  // TODO: implement
  OS << "PrintDebugValueComment()";
}

extern "C" void LLVMInitializeVideocoreAsmPrinter() {
    RegisterAsmPrinter<VideocoreAsmPrinter> X(TheVideocoreTarget);
}
