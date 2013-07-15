//===- VideocoreSelectionDAGInfo.h - Videocore SelectionDAG Info *- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the Videocore subclass for TargetSelectionDAGInfo.
//
//===----------------------------------------------------------------------===//

#ifndef VIDEOCORESELECTIONDAGINFO_H
#define VIDEOCORESELECTIONDAGINFO_H

#include "llvm/Target/TargetSelectionDAGInfo.h"

namespace llvm {

class VideocoreTargetMachine;

class VideocoreSelectionDAGInfo : public TargetSelectionDAGInfo {
public:
  explicit VideocoreSelectionDAGInfo(const VideocoreTargetMachine &TM);
  ~VideocoreSelectionDAGInfo();
};

}

#endif
