//===-- VideocoreMCAsmInfo.h - Videocore asm properties --------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the VideocoreMCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef VIDEOCORETARGETASMINFO_H
#define VIDEOCORETARGETASMINFO_H

#include "llvm/MC/MCAsmInfo.h"

namespace llvm {
  class StringRef;
  class Target;

  class VideocoreMCAsmInfo : public MCAsmInfo {
    virtual void anchor();
  public:
    explicit VideocoreMCAsmInfo(const Target &T, StringRef TT);
  };

} // namespace llvm

#endif
