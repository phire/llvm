//===-- VideocoreTargetInfo.cpp - Videocore Target Implementation ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "Videocore.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

Target llvm::TheVideocoreTarget;

extern "C" void LLVMInitializeVideocoreTargetInfo() {
  RegisterTarget<Triple::videocore> X(TheVideocoreTarget,
                                      "videocore", "Videocore");
}
