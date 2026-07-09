#ifndef PLATFORM_SW_PROJECT_ACCEL_OPS_H_
#define PLATFORM_SW_PROJECT_ACCEL_OPS_H_

#include <stdint.h>

#include "cfu.h"

static inline uint32_t accel_scalar_compute(uint32_t src1, uint32_t src2) {
  return cfu_op0(CFU_FUNCT7_SCALAR_COMPUTE, src1, src2);
}

static inline uint32_t accel_axi_read(const volatile uint32_t* addr) {
  return cfu_op1(CFU_FUNCT7_AXI, (CfuWord)addr, 0);
}

static inline void accel_axi_write(volatile uint32_t* addr, uint32_t data) {
  (void)cfu_op2(CFU_FUNCT7_AXI, (CfuWord)addr, data);
}

// Add project-specific wrappers here, then call those wrappers from tests,
// menus, or TFLM kernels instead of scattering raw funct3/funct7 values.

#endif  // PLATFORM_SW_PROJECT_ACCEL_OPS_H_
