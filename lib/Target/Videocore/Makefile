##===- lib/Target/VC4/Makefile ---------------------------*- Makefile -*-===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
##===----------------------------------------------------------------------===##

LEVEL = ../../..
LIBRARYNAME = LLVMVC4CodeGen
TARGET = Videocore

# Make sure that tblgen is run, first thing.
BUILT_SOURCES = VideocoreGenRegisterInfo.inc \
		VideocoreGenInstrInfo.inc \
		VideocoreGenAsmWriter.inc 
		VideocoreGenAsmMatcher.inc \
		VideocoreGenCodeEmitter.inc \
		VideocoreGenMCCodeEmitter.inc \
		VideocoreGenDAGISel.inc \
		VideocoreGenSubtargetInfo.inc \
		VideocoreGenCallingConv.inc

DIRS = InstPrinter AsmParser TargetInfo MCTargetDesc

include $(LEVEL)/Makefile.common
