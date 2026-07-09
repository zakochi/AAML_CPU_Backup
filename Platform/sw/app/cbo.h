#ifndef PLATFORM_SW_APP_CBO_H_
#define PLATFORM_SW_APP_CBO_H_

#include <stddef.h>
#include <stdint.h>

#include "platform_config.h"

static inline void cbo_clean(const volatile void* addr) {
#if defined(__riscv)
  register uintptr_t a0 asm("a0") = (uintptr_t)addr;
  __asm__ volatile(".balign 4\n\t.word 0x0015200F"
                   : "+r"(a0)
                   :
                   : "memory");
#else
  (void)addr;
#endif
}

static inline void cbo_invalidate(const volatile void* addr) {
#if defined(__riscv)
  register uintptr_t a0 asm("a0") = (uintptr_t)addr;
  __asm__ volatile(".balign 4\n\t.word 0x0005200F"
                   : "+r"(a0)
                   :
                   : "memory");
#else
  (void)addr;
#endif
}

static inline void cbo_clean_range(const volatile void* addr, size_t bytes) {
  uintptr_t start = (uintptr_t)addr & ~(uintptr_t)(CBO_BLOCK_BYTES - 1);
  uintptr_t end = ((uintptr_t)addr + bytes + CBO_BLOCK_BYTES - 1) &
                  ~(uintptr_t)(CBO_BLOCK_BYTES - 1);

  for (uintptr_t p = start; p < end; p += CBO_BLOCK_BYTES) {
    cbo_clean((const void*)p);
  }
#if defined(__riscv)
  __asm__ volatile("fence rw, rw" ::: "memory");
#endif
}

static inline void cbo_invalidate_range(const volatile void* addr,
                                        size_t bytes) {
  uintptr_t start = (uintptr_t)addr & ~(uintptr_t)(CBO_BLOCK_BYTES - 1);
  uintptr_t end = ((uintptr_t)addr + bytes + CBO_BLOCK_BYTES - 1) &
                  ~(uintptr_t)(CBO_BLOCK_BYTES - 1);

  for (uintptr_t p = start; p < end; p += CBO_BLOCK_BYTES) {
    cbo_invalidate((const void*)p);
  }
#if defined(__riscv)
  __asm__ volatile("fence rw, rw" ::: "memory");
#endif
}

#endif  // PLATFORM_SW_APP_CBO_H_
