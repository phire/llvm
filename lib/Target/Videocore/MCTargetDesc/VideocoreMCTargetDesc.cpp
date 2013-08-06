//===-- VideocoreMCTargetDesc.cpp - Videocore Target Descriptions ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides Videocore specific target descriptions.
//
//===----------------------------------------------------------------------===//

#include "VideocoreMCTargetDesc.h"
#include "VideocoreMCAsmInfo.h"
#include "InstPrinter/VideocoreInstPrinter.h"
#include "llvm/MC/MCCodeGenInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_INSTRINFO_MC_DESC
#include "VideocoreGenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "VideocoreGenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "VideocoreGenRegisterInfo.inc"

using namespace llvm;

static MCInstrInfo *createVideocoreMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitVideocoreMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createVideocoreMCRegisterInfo(StringRef TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitVideocoreMCRegisterInfo(X, VC::LR);
  return X;
}

static MCSubtargetInfo *createVideocoreMCSubtargetInfo(StringRef TT,
                                                       StringRef CPU,
                                                       StringRef FS) {
  MCSubtargetInfo *X = new MCSubtargetInfo();
  InitVideocoreMCSubtargetInfo(X, TT, CPU, FS);
  return X;
}

static MCAsmInfo *createVideocoreMCAsmInfo(const Target &T, StringRef TT) {
  MCAsmInfo *MAI = new VideocoreMCAsmInfo(T, TT);

  // Initial state of the frame pointer is SP.
  MachineLocation Dst(MachineLocation::VirtualFP);
  MachineLocation Src(VC::SP, 0);
  MAI->addInitialFrameState(0, Dst, Src);

  return MAI;
}

static MCCodeGenInfo *createVideocoreMCCodeGenInfo(StringRef TT,
                                                   Reloc::Model RM,
                                                   CodeModel::Model CM,
                                                   CodeGenOpt::Level OL) {
  MCCodeGenInfo *X = new MCCodeGenInfo();
  X->InitMCCodeGenInfo(RM, CM, OL);
  return X;
}

static MCInstPrinter *createVideocoreMCInstPrinter(const Target &T,
                                                 unsigned SyntaxVariant,
                                                 const MCAsmInfo &MAI,
                                                 const MCInstrInfo &MII,
                                                 const MCRegisterInfo &MRI,
                                                 const MCSubtargetInfo &STI) {
  return new VideocoreInstPrinter(MAI, MII, MRI);
}

static MCStreamer *createMCStreamer(const Target &T, StringRef TT,
                                    MCContext &Ctx, MCAsmBackend &MAB,
                                    raw_ostream &_OS,
                                    MCCodeEmitter *_Emitter,
                                    bool RelaxAll,
                                    bool NoExecStack) {
  Triple TheTriple(TT);

  return createELFStreamer(Ctx, MAB, _OS, _Emitter, RelaxAll, NoExecStack);
}


// Force static initialization.
extern "C" void LLVMInitializeVideocoreTargetMC() {
  // Register the MC asm info.
  RegisterMCAsmInfoFn X(TheVideocoreTarget, createVideocoreMCAsmInfo);

  // Register the MC codegen info.
  TargetRegistry::RegisterMCCodeGenInfo(TheVideocoreTarget,
                                        createVideocoreMCCodeGenInfo);

  // Register the MC instruction info.
  TargetRegistry::RegisterMCInstrInfo(TheVideocoreTarget,
                                      createVideocoreMCInstrInfo);

  // Register the MC register info.
  TargetRegistry::RegisterMCRegInfo(TheVideocoreTarget,
                                    createVideocoreMCRegisterInfo);

  // Register the MC code emitter
  TargetRegistry::RegisterMCCodeEmitter(TheVideocoreTarget,
                                        createVideocoreMCCodeEmitter);

  // Register the MC object streamer
  TargetRegistry::RegisterMCObjectStreamer(TheVideocoreTarget,
                                           createMCStreamer);

  // Register the asm backend.
  TargetRegistry::RegisterMCAsmBackend(TheVideocoreTarget,
                                       createVideocoreAsmBackend);


  // Register the MC subtarget info.
  TargetRegistry::RegisterMCSubtargetInfo(TheVideocoreTarget,
                                          createVideocoreMCSubtargetInfo);
  TargetRegistry::RegisterMCInstPrinter(TheVideocoreTarget,
                                        createVideocoreMCInstPrinter);
}
