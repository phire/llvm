//===-- VideocoreSelectionDAGInfo.cpp - Videocore SelectionDAG Info -------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the VideocoreSelectionDAGInfo class.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "videocore-selectiondag-info"
#include "VideocoreTargetMachine.h"
using namespace llvm;

VideocoreSelectionDAGInfo::
VideocoreSelectionDAGInfo(const VideocoreTargetMachine &TM)
  : TargetSelectionDAGInfo(TM) {
}

VideocoreSelectionDAGInfo::~VideocoreSelectionDAGInfo() {
}
