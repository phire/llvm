//=== VideocoreAsmPrinter.h - Videocore LLVM Assembly Printer --*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef VideocoreASMPRINTER_H
#define VideocoreASMPRINTER_H

//#include "VideocoreMachineFunction.h"
#include "VideocoreMCInstLower.h"
//#include "VideocoreSubtarget.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {
    class MCStreamer;
    class MachineInstr;
    class MachineBasicBlock;
    class Module;
    class raw_ostream;

    class LLVM_LIBRARY_VISIBILITY VideocoreAsmPrinter : public AsmPrinter {
    public:
        explicit VideocoreAsmPrinter(TargetMachine &TM, MCStreamer &Streamer)
            : AsmPrinter(TM, Streamer), MCInstLowering(*this) {}

        VideocoreMCInstLower MCInstLowering;

        virtual const char *getPassName() const {
            return "Videocore Assembly Printer";
        }

        void EmitInstruction(const MachineInstr *MI);
        virtual void EmitFunctionBodyStart();

    protected:
        void PrintDebugValueComment(const MachineInstr *MI, raw_ostream &OS);

    };
}

#endif
