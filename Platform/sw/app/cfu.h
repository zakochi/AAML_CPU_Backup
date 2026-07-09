#ifndef PLATFORM_SW_APP_CFU_H_
#define PLATFORM_SW_APP_CFU_H_

#include <stdint.h>

typedef uintptr_t CfuWord;

enum CfuFunction {
  kCfuScalarCompute = 0,
  kCfuAxiRead = 1,
  kCfuAxiWrite = 2,
};

uint32_t cfu_op(CfuWord rs1, CfuWord rs2, uint32_t func);
uint32_t cfu_op_hw(CfuWord rs1, CfuWord rs2, uint32_t func);

#endif  // PLATFORM_SW_APP_CFU_H_
