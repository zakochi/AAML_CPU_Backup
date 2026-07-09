#ifndef PLATFORM_SW_APP_SOFTWARE_CFU_H_
#define PLATFORM_SW_APP_SOFTWARE_CFU_H_

#include <stdint.h>

#include "cfu.h"

uint32_t software_cfu(CfuWord rs1, CfuWord rs2, uint32_t func);

#endif  // PLATFORM_SW_APP_SOFTWARE_CFU_H_
