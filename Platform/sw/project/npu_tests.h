#ifndef PLATFORM_SW_PROJECT_NPU_TESTS_H_
#define PLATFORM_SW_PROJECT_NPU_TESTS_H_

#include "accel_tests.h"

static inline void npu_run_functional_test(void) {
  accel_run_functional_test();
}

static inline void npu_run_mixed_stress_test(void) {
  accel_run_mixed_stress_test();
}

#endif  // PLATFORM_SW_PROJECT_NPU_TESTS_H_
