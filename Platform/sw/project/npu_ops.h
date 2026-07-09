#ifndef PLATFORM_SW_PROJECT_NPU_OPS_H_
#define PLATFORM_SW_PROJECT_NPU_OPS_H_

#include "accel_ops.h"

static inline uint32_t npu_scalar_compute(uint32_t src1, uint32_t src2) {
  return accel_scalar_compute(src1, src2);
}

static inline uint32_t npu_axi_read(const volatile uint32_t* addr) {
  return accel_axi_read(addr);
}

static inline void npu_axi_write(volatile uint32_t* addr, uint32_t data) {
  accel_axi_write(addr, data);
}

#endif  // PLATFORM_SW_PROJECT_NPU_OPS_H_
