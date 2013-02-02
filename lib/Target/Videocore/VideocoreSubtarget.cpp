//===-- VideocoreSubtarget.cpp - Videocore Subtarget Information ----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the Videocore specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#include "VideocoreSubtarget.h"
#include "Videocore.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "VideocoreGenSubtargetInfo.inc"

using namespace llvm;

void VideocoreSubtarget::anchor() { }

VideocoreSubtarget::VideocoreSubtarget(const std::string &TT, const std::string &CPU,
                             const std::string &FS, bool little) :
  VideocoreGenSubtargetInfo(TT, CPU, FS),
  VideocoreABI(UnknownABI), IsLittle(little)
{
  std::string CPUName = CPU;
  if (CPUName.empty())
    CPUName = "videocore4";

  // Parse features string.
  ParseSubtargetFeatures(CPUName, FS);

  // Initialize scheduling itinerary for the specified CPU.
  InstrItins = getInstrItineraryForCPU(CPUName);

  // Set VideocoreABI if it hasn't been set yet.
  if (VideocoreABI == UnknownABI)
    VideocoreABI = VC4;
}

