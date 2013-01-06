//===-- VideocoreMCTargetDesc.h - Videocore Target Descriptions -*- C++ -*-===//
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

#ifndef VIDEOCOREMCTARGETDESC_H
#define VIDEOCOREMCTARGETDESC_H

namespace llvm {
class Target;

extern Target TheVideocoreTarget;

} // End llvm namespace

// Defines symbolic names for Videocore registers.  This defines a mapping from
// register name to register number.
//
#define GET_REGINFO_ENUM
#include "VideocoreGenRegisterInfo.inc"

// Defines symbolic names for the Videocore instructions.
//
#define GET_INSTRINFO_ENUM
#include "VideocoreGenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "VideocoreGenSubtargetInfo.inc"

#endif
