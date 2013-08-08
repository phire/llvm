//===-- VideocoreBinaryInstr.h ----------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains a representation of the raw binary of a variable length
// videocore instruction and methods to read/write in the correct endiness.
//
//===----------------------------------------------------------------------===//

#ifndef VIDEOCOREBINARYINSTRUCTION_H
#define VIDEOCOREBINARYINSTRYCTION_H

#include "Videocore.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/MemoryObject.h"

using namespace llvm;

static inline uint64_t le_short(const MemoryObject &region, uint64_t address) {
  uint8_t bytes[2];

  int ret = region.readBytes(address, 2, (uint8_t*)bytes, NULL);
  assert(ret != -1); // FIXME We need to fail better

  return bytes[0] | bytes[1] << 8;
}
static inline uint64_t le_int(const MemoryObject &region, uint64_t address) {
  uint8_t bytes[4];

  int ret = region.readBytes(address, 4, (uint8_t*)bytes, NULL);
  assert(ret != -1);

  return bytes[0] | bytes[1] << 8 | bytes[2] << 16 | uint64_t(bytes[3]) << 24;
}

class VideocoreBinaryInstr {
private:
  // uint32_t + uint64_t = 96 bits
  uint64_t lo; // 64 bits low
  uint16_t hi; // 16 bits high

public: // constructors
  VideocoreBinaryInstr()               : lo(0), hi(0) {}
  VideocoreBinaryInstr(uint32_t value) : lo(value), hi(0) {}
  VideocoreBinaryInstr(uint64_t value) : lo(value), hi(0) {}
  VideocoreBinaryInstr(int32_t value)  : lo(value), hi(0) { if(value < 0) hi = uint16_t(-1); }
  VideocoreBinaryInstr(long long int value): lo(value), hi(0) { if(value < 0) hi = uint16_t(-1); }
  VideocoreBinaryInstr(uint16_t hi, uint64_t lo): lo(lo), hi(hi) {}

  VideocoreBinaryInstr(const MemoryObject &region, uint64_t address) {
    hi = 0;
    uint16_t word = le_short(region, address);
    if ((word & 0x8000) == 0x0000) {
      lo = word;
    } else if ((word & 0xf000) < 0xe000) {
      lo = le_short(region, address+2) |
           uint64_t(word) << 16;
    } else if ((word & 0xf000) == 0xe000) {
      lo = le_int(region, address+2) |
           uint64_t(word) << 32;
    } else if ((word & 0xf800) == 0xf000) {
      lo = le_short(region, address+2) << 16 |
           le_short(region, address+4) |
           uint64_t(word) << 32;
    } else if ((word & 0xf800) == 0xf800) {
      lo = le_short(region, address+2) << 48 |
           le_short(region, address+4) << 32 |
           le_short(region, address+6) << 16 |
           le_short(region, address+8);
      hi = word;
    }
  }

public:
  enum Type {
    Invalid,
    Scalar16,
    Scalar32,
    Scalar48,
    Vector48,
    Vector80
  };

  Type type() {
    if ((hi & 0xf800) == 0xf800)
      return Vector80;
    else if (hi != 0)
      return Invalid;
    else if ((lo >> 43) == 0x1e)
      return Vector48;
    else if ((lo >> 44) == 0xe)
      return Scalar48;
    else if ((lo & 0x80000000) && (lo >> 28) < 0xe)
      return Scalar32;
    else if ((lo >> 15) == 0)
      return Scalar16;
    else
      return Invalid;
  }

  size_t size() {
    switch (type()) {
      case Scalar16: return 2;
      case Scalar32: return 4;
      case Scalar48:
      case Vector48: return 6;
      case Vector80: return 10;
      default: return 2;
    }
  }

  VideocoreBinaryInstr &operator=(const VideocoreBinaryInstr &other) {
    if(&other != this) {
      lo = other.lo;
      hi = other.hi;
    }
    return *this;
  }

// This class gets passed into TableGen'ed Dissassember code which treats it as
// an unsigned interger. So we overload enough math operators to let the
// Disassembler do it's work.
public: // comparison operators
  template<typename T>
  bool operator==(const T &rhs) const {
    VideocoreBinaryInstr o = static_cast<VideocoreBinaryInstr>(rhs);
    return hi == o.hi && lo == o.lo;
  }

  template<typename T>
  bool operator!=(const T &rhs) const {
    VideocoreBinaryInstr o = static_cast<VideocoreBinaryInstr>(rhs);
    return hi != o.hi || lo != o.lo;
  }

public: // unary operators
  bool operator!() const {
    return !(hi != 0 || lo != 0);
  }

  VideocoreBinaryInstr operator-() const {
    // standard 2's compliment negation
    return ~VideocoreBinaryInstr(*this) + 1;
  }

  VideocoreBinaryInstr operator~() const {
    VideocoreBinaryInstr t(*this);
    t.lo = ~t.lo;
    t.hi = ~t.hi;
    return t;
  }

public: // basic math operators
  template<typename otherType>
  VideocoreBinaryInstr &operator+=(const otherType &rhs) {
    VideocoreBinaryInstr b = static_cast<VideocoreBinaryInstr>(rhs);
    uint64_t old_lo = lo;

    lo += b.lo;
    hi += b.hi;

    if(lo < old_lo) {
      ++hi;
    }

    return *this;
  }

  template<typename otherType>
  VideocoreBinaryInstr &operator-=(const otherType &rhs) {
    // it happens to be way easier to write it
    // this way instead of make a subtraction algorithm
    return *this += -rhs;
  }

  template<typename otherType>
  VideocoreBinaryInstr &operator|=(const otherType &rhs) {
    VideocoreBinaryInstr b = static_cast<VideocoreBinaryInstr>(rhs);
    hi |= b.hi;
    lo |= b.lo;
    return *this;
  }

  template<typename otherType>
  VideocoreBinaryInstr &operator&=(const otherType &b) {
    hi &= b.hi;
    lo &= b.lo;
    return *this;
  }

  template<typename otherType>
  VideocoreBinaryInstr &operator^=(const otherType &b) {
    hi ^= b.hi;
    lo ^= b.lo;
    return *this;
  }

  template<typename otherType>
  VideocoreBinaryInstr &operator<<=(const otherType &rhs) {
    uint32_t n = uint32_t(rhs);

    if (n >= 80) {
      hi = 0;
      lo = 0;
    } else {
      if (n >= 64) {
        n -= 64;
        hi = lo;
        lo = 0;
      }

      if (n != 0) {
        hi <<= n;
        uint64_t mask = ~(uint64_t(-1) >> n);
        hi |= (lo & mask) >> (64 - n);
        lo <<= n;
      }
    }
    return *this;
  }

  template<typename otherType>
  VideocoreBinaryInstr &operator>>=(const otherType &rhs) {
    uint32_t n = uint32_t(rhs);

    if (n >= 80) {
      hi = 0;
      lo = 0;
    } else {
      if (n >= 64) {
        n -= 64;
        lo = hi;
        hi = 0;
      }
      if (n != 0) {
        lo >>= n;
        uint64_t mask = ~(uint64_t(-1) << n);
        lo |= (hi & mask) >> (64 - n);
        hi >>= n;
      }
    }
    return *this;
  }

public:
  template<typename otherType>
  VideocoreBinaryInstr operator|(const otherType &rhs) {
    VideocoreBinaryInstr t(*this);
    t ^= rhs;
    return t;
  }

  template<typename otherType>
  VideocoreBinaryInstr operator&(const otherType &rhs) {
    VideocoreBinaryInstr t(*this);
    t &= rhs;
    return t;
  }

  template<typename otherType>
  VideocoreBinaryInstr operator^(const otherType &rhs) {
    VideocoreBinaryInstr t(*this);
    t ^= rhs;
    return t;
  }

  template<typename otherType>
  VideocoreBinaryInstr operator+(const otherType &rhs) {
    VideocoreBinaryInstr t(*this);
    t += rhs;
    return t;
  }

  template<typename otherType>
  VideocoreBinaryInstr operator-(const otherType &rhs) {
    VideocoreBinaryInstr t(*this);
    t -= rhs;
    return t;
  }

  template<typename otherType>
  VideocoreBinaryInstr operator<<(const otherType &rhs) {
    VideocoreBinaryInstr t(*this);
    t <<= rhs;
    return t;
  }

  template<typename otherType>
  VideocoreBinaryInstr operator>>(const otherType &rhs) {
    VideocoreBinaryInstr t(*this);
    t >>= rhs;
    return t;
  }

public: // casting
  operator uint64_t() const {
    assert(hi == 0);
    return lo;
  }
  //operator uint32_t() const {
  //  assert(hi == 0 && (lo & 0xffffffff00000000) == 0);
  //  return lo;
  //}
};

// Reverse equality operators
template<typename T>
bool operator!=(T &lhs, VideocoreBinaryInstr &rhs) {
  return rhs != lhs;
}
template<typename T>
bool operator==(T &lhs, VideocoreBinaryInstr &rhs) {
  return rhs == lhs;
}

// Printing
raw_ostream &operator<<(raw_ostream &O, VideocoreBinaryInstr &b) {
  // FIXME: writeout the whole 80bit value, in hex?
  return O << uint64_t(b);
}


#endif
