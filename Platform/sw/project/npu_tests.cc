#include "npu_tests.h"

#include <stdint.h>
#include <stdio.h>

#include "cbo.h"
#include "npu_ops.h"
#include "perf.h"
#include "platform_config.h"

namespace {

volatile uint8_t memory_pool[NPU_TEST_MEMORY_BYTES]
    __attribute__((aligned(NPU_TEST_MEMORY_ALIGN)));

static_assert(NPU_TEST_FUNCTIONAL_OFFSET + sizeof(uint32_t) <=
                  NPU_TEST_MEMORY_BYTES,
              "NPU functional test address is outside memory_pool");
static_assert(NPU_TEST_STRESS_OFFSET + sizeof(uint32_t) <=
                  NPU_TEST_MEMORY_BYTES,
              "NPU stress test address is outside memory_pool");

}  // namespace

void npu_run_functional_test(void) {
  printf("\n>>> STARTING NPU FUNCTIONAL TEST...\n");
  int test_errors = 0;
  volatile uint32_t* test_addr =
      (uint32_t*)&memory_pool[NPU_TEST_FUNCTIONAL_OFFSET];

  printf("[TEST 1/3] Scalar Math... ");
  uint32_t sum = npu_scalar_compute(100, 200);
  if (sum == 305) {
    printf("PASS\n");
  } else {
    printf("FAIL (%u)\n", (unsigned)sum);
    ++test_errors;
  }

  printf("[TEST 2/3] AXI Write... ");
  *test_addr = 0;
  cbo_clean(test_addr);
  npu_axi_write(test_addr, 0x55AA1234);
  cbo_invalidate(test_addr);
  if (*test_addr == 0x55AA1234) {
    printf("PASS\n");
  } else {
    printf("FAIL (0x%08X)\n", (unsigned)*test_addr);
    ++test_errors;
  }

  printf("[TEST 3/3] AXI Read... ");
  *test_addr = 0xCAFE9999;
  cbo_clean(test_addr);
  if (npu_axi_read(test_addr) == 0xCAFE9999) {
    printf("PASS\n");
  } else {
    printf("FAIL\n");
    ++test_errors;
  }

  if (test_errors == 0) {
    printf("[SUCCESS] All functional tests passed!\n");
  } else {
    printf("[FAIL] %d functional tests failed.\n", test_errors);
  }
}

void npu_run_mixed_stress_test(void) {
  const uint32_t loops = NPU_STRESS_LOOPS;
  volatile uint32_t* test_addr =
      (uint32_t*)&memory_pool[NPU_TEST_STRESS_OFFSET];

  printf("\n>>> STARTING MIXED STRESS TEST (%u loops)...\n", (unsigned)loops);
  uint64_t start = perf_get_mcycle64();

  for (uint32_t i = 0; i < loops; ++i) {
    uint32_t op = i % 3;
    uint32_t val1 = i;
    uint32_t val2 = i + 1;

    if (op == 0) {
      if (npu_scalar_compute(val1, val2) != (val1 + val2 + 5)) {
        printf("Error at Compute loop %u\n", (unsigned)i);
        return;
      }
    } else if (op == 1) {
      npu_axi_write(test_addr, val1);
      cbo_invalidate(test_addr);
      if (*test_addr != val1) {
        printf("Error at Write loop %u: Expected 0x%08X, Got 0x%08X\n",
               (unsigned)i, (unsigned)val1, (unsigned)*test_addr);
        return;
      }
    } else {
      *test_addr = val1;
      cbo_clean(test_addr);
      if (npu_axi_read(test_addr) != val1) {
        printf("Error at Read loop %u: Expected 0x%08X\n", (unsigned)i,
               (unsigned)val1);
        return;
      }
    }

#if NPU_STRESS_PROGRESS_INTERVAL > 0
    if ((i % NPU_STRESS_PROGRESS_INTERVAL) == 0) {
      printf("Progress: %u/%u...\n", (unsigned)i, (unsigned)loops);
    }
#endif
  }

  uint64_t elapsed = perf_get_mcycle64() - start;
  printf("[SUCCESS] Mixed Stress Test complete! cycles=");
  perf_print_cycles(elapsed);
  putchar('\n');
}
