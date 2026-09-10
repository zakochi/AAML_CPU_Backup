#include "accelerator_test.h"

#include <stdint.h>
#include <stdio.h>

#include "cbo.h"
#include "cfu.h"

namespace {

const uint32_t kGolden[] = {
    0x00000000u, 0xffffffffu, 0x55555555u, 0xaaaaaaaau,
    0x00000001u, 0x80000000u, 0x01234567u, 0x89abcdefu,
    0x13579bdfu, 0x2468ace0u, 0x00ff00ffu, 0xff00ff00u,
    0x0000ffffu, 0xffff0000u, 0x55aa1234u, 0xcafe9999u,
};
const unsigned kWordCount = sizeof(kGolden) / sizeof(kGolden[0]);

alignas(32) volatile uint32_t test_words[kWordCount];

unsigned check_word(const char* operation, unsigned index, uint32_t actual,
                    uint32_t golden) {
  const bool pass = actual == golden;
  printf("[%s] AXI %s[%u]: actual=0x%08x golden=0x%08x\n",
         pass ? "PASS" : "FAIL", operation, index,
         (unsigned)actual, (unsigned)golden);
  return pass ? 0 : 1;
}

}  // namespace

void accelerator_test(void) {
  printf("\n=== Accelerator AXI Test ===\n");
#if defined(CFU_SOFTWARE_DEFINED) || !defined(__riscv)
  printf("[AXI] Backend: software CFU (no AXI transactions).\n");
#else
  printf("[AXI] Backend: hardware CUSTOM-0.\n");
#endif
  printf("[AXI] %u aligned 32-bit words; exact golden comparison.\n",
         kWordCount);
  unsigned failures = 0;

  for (unsigned i = 0; i < kWordCount; ++i) {
    test_words[i] = kGolden[i];
  }
#if defined(__riscv) && !defined(CFU_SOFTWARE_DEFINED)
  for (unsigned i = 0; i < kWordCount; ++i) {
    cbo_clean(&test_words[i]);
  }
#endif
  for (unsigned i = 0; i < kWordCount; ++i) {
    const uint32_t actual =
        cfu_op1(CFU_FUNCT7_AXI, (CfuWord)&test_words[i], 0);
    failures += check_word("read", i, actual, kGolden[i]);
  }

  for (unsigned i = 0; i < kWordCount; ++i) {
    (void)cfu_op2(CFU_FUNCT7_AXI, (CfuWord)&test_words[i], ~kGolden[i]);
  }
#if defined(__riscv) && !defined(CFU_SOFTWARE_DEFINED)
  for (unsigned i = 0; i < kWordCount; ++i) {
    cbo_invalidate(&test_words[i]);
  }
#endif
  for (unsigned i = 0; i < kWordCount; ++i) {
    failures += check_word("write", i, test_words[i], ~kGolden[i]);
  }

  if (failures == 0) {
    printf("[AXI] ALL PASS (%u checks).\n", 2 * kWordCount);
  } else {
    printf("[AXI] FAIL (%u/%u checks).\n", failures, 2 * kWordCount);
  }
}
