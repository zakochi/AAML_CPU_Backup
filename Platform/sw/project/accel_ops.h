#ifndef PLATFORM_SW_PROJECT_ACCEL_OPS_H_
#define PLATFORM_SW_PROJECT_ACCEL_OPS_H_

#include <stdint.h>

#include "cfu.h"

static inline uint32_t accel_scalar_compute(uint32_t src1, uint32_t src2) {
  return cfu_op(src1, src2, kCfuScalarCompute);
}

static inline uint32_t accel_axi_read(const volatile uint32_t* addr) {
  return cfu_op((CfuWord)addr, 0, kCfuAxiRead);
}

static inline void accel_axi_write(volatile uint32_t* addr, uint32_t data) {
  cfu_op((CfuWord)addr, data, kCfuAxiWrite);
}

#endif  // PLATFORM_SW_PROJECT_ACCEL_OPS_H_
