//===-- VideocoreMCAsmInfo.cpp - Videocore asm properties -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "VideocoreMCAsmInfo.h"
#include "llvm/ADT/StringRef.h"
using namespace llvm;

void VideocoreMCAsmInfo::anchor() { }

VideocoreMCAsmInfo::VideocoreMCAsmInfo(const Target &T, StringRef TT) {
  MaxInstLength = 10;

}

