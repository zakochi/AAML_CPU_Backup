#include "software_cfu.h"

uint32_t software_cfu(CfuWord rs1, CfuWord rs2, uint32_t func) {
  switch (func) {
    case kCfuScalarCompute:
      return (uint32_t)rs1 + (uint32_t)rs2 + 5;
    case kCfuAxiRead:
      return *reinterpret_cast<volatile uint32_t*>(rs1);
    case kCfuAxiWrite:
      *reinterpret_cast<volatile uint32_t*>(rs1) = (uint32_t)rs2;
      return 0;
    default:
      return 0;
  }
}
