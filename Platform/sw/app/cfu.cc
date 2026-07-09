#include "cfu.h"

#include "software_cfu.h"

namespace {

uint32_t cfu_scalar_compute_hw(CfuWord rs1, CfuWord rs2) {
#if defined(__riscv)
  uint32_t result = 0;
  __asm__ volatile(".insn r 0x0B, 0x0, 0x05, %0, %1, %2"
                   : "=r"(result)
                   : "r"(rs1), "r"(rs2));
  return result;
#else
  return software_cfu(rs1, rs2, kCfuScalarCompute);
#endif
}

uint32_t cfu_axi_read_hw(CfuWord addr) {
#if defined(__riscv)
  uint32_t result = 0;
  __asm__ volatile(".insn r 0x0B, 0x1, 0x00, %0, %1, x0"
                   : "=r"(result)
                   : "r"(addr));
  return result;
#else
  return software_cfu(addr, 0, kCfuAxiRead);
#endif
}

void cfu_axi_write_hw(CfuWord addr, CfuWord data) {
#if defined(__riscv)
  __asm__ volatile(".insn r 0x0B, 0x2, 0x00, x0, %0, %1"
                   :
                   : "r"(addr), "r"(data)
                   : "memory");
#else
  software_cfu(addr, data, kCfuAxiWrite);
#endif
}

}  // namespace

uint32_t cfu_op_hw(CfuWord rs1, CfuWord rs2, uint32_t func) {
  switch (func) {
    case kCfuScalarCompute:
      return cfu_scalar_compute_hw(rs1, rs2);
    case kCfuAxiRead:
      return cfu_axi_read_hw(rs1);
    case kCfuAxiWrite:
      cfu_axi_write_hw(rs1, rs2);
      return 0;
    default:
      return 0;
  }
}

uint32_t cfu_op(CfuWord rs1, CfuWord rs2, uint32_t func) {
#ifdef CFU_SOFTWARE_DEFINED
  return software_cfu(rs1, rs2, func);
#else
  return cfu_op_hw(rs1, rs2, func);
#endif
}
