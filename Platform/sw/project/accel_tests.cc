#include "accel_tests.h"

#include <stdint.h>
#include <stdio.h>

#include "cbo.h"
#include "accel_ops.h"
#include "perf.h"
#include "platform_config.h"

namespace {

volatile uint8_t memory_pool[ACCEL_TEST_MEMORY_BYTES]
    __attribute__((aligned(ACCEL_TEST_MEMORY_ALIGN)));

static_assert(ACCEL_TEST_FUNCTIONAL_OFFSET + sizeof(uint32_t) <=
                  ACCEL_TEST_MEMORY_BYTES,
              "accelerator functional test address is outside memory_pool");
static_assert(ACCEL_TEST_STRESS_OFFSET + sizeof(uint32_t) <=
                  ACCEL_TEST_MEMORY_BYTES,
              "accelerator stress test address is outside memory_pool");

}  // namespace

void accel_run_functional_test(void) {
  printf("\n>>> STARTING ACCELERATOR FUNCTIONAL TEST...\n");
  int test_errors = 0;
  volatile uint32_t* test_addr =
      (uint32_t*)&memory_pool[ACCEL_TEST_FUNCTIONAL_OFFSET];

  printf("[TEST 1/3] Scalar Math... ");
  uint32_t sum = accel_scalar_compute(100, 200);
  if (sum == 305) {
    printf("PASS\n");
  } else {
    printf("FAIL (%u)\n", (unsigned)sum);
    ++test_errors;
  }

  printf("[TEST 2/3] AXI Write... ");
  *test_addr = 0;
  cbo_clean(test_addr);
  accel_axi_write(test_addr, 0x55AA1234);
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
  if (accel_axi_read(test_addr) == 0xCAFE9999) {
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

void accel_run_scalar_benchmark(void) {
  const uint32_t loops = ACCEL_BENCH_LOOPS;
  volatile uint32_t checksum = 0;

  printf("\n>>> STARTING SCALAR CUSTOM INSTRUCTION BENCHMARK (%u loops)...\n",
         (unsigned)loops);
  uint64_t start = perf_get_mcycle64();

  for (uint32_t i = 0; i < loops; ++i) {
    checksum += accel_scalar_compute(i, i + 1);
  }

  uint64_t elapsed = perf_get_mcycle64() - start;
  printf("[SUCCESS] Scalar benchmark complete! checksum=%u cycles=",
         (unsigned)checksum);
  perf_print_cycles(elapsed);
  if (loops != 0) {
    printf(" cycles/op=");
    perf_print_cycles(elapsed / loops);
  }
  putchar('\n');
  perf_print_time_ms(elapsed);
}

void accel_run_mixed_stress_test(void) {
  const uint32_t loops = ACCEL_STRESS_LOOPS;
  volatile uint32_t* test_addr =
      (uint32_t*)&memory_pool[ACCEL_TEST_STRESS_OFFSET];

  printf("\n>>> STARTING MIXED STRESS TEST (%u loops)...\n", (unsigned)loops);
  uint64_t start = perf_get_mcycle64();

  for (uint32_t i = 0; i < loops; ++i) {
    uint32_t op = i % 3;
    uint32_t val1 = i;
    uint32_t val2 = i + 1;

    if (op == 0) {
      if (accel_scalar_compute(val1, val2) != (val1 + val2 + 5)) {
        printf("Error at Compute loop %u\n", (unsigned)i);
        return;
      }
    } else if (op == 1) {
      accel_axi_write(test_addr, val1);
      cbo_invalidate(test_addr);
      if (*test_addr != val1) {
        printf("Error at Write loop %u: Expected 0x%08X, Got 0x%08X\n",
               (unsigned)i, (unsigned)val1, (unsigned)*test_addr);
        return;
      }
    } else {
      *test_addr = val1;
      cbo_clean(test_addr);
      if (accel_axi_read(test_addr) != val1) {
        printf("Error at Read loop %u: Expected 0x%08X\n", (unsigned)i,
               (unsigned)val1);
        return;
      }
    }

#if ACCEL_STRESS_PROGRESS_INTERVAL > 0
    if ((i % ACCEL_STRESS_PROGRESS_INTERVAL) == 0) {
      printf("Progress: %u/%u...\n", (unsigned)i, (unsigned)loops);
    }
#endif
  }

  uint64_t elapsed = perf_get_mcycle64() - start;
  printf("[SUCCESS] Mixed Stress Test complete! cycles=");
  perf_print_cycles(elapsed);
  putchar('\n');
}
