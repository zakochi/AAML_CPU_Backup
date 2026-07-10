#include <stdio.h>

#include "menu.h"
#include "perf.h"
#include "platform_config.h"
#include "proj_menu.h"
#include "runtime.h"

#ifndef MODEL_NAME
#define MODEL_NAME "unknown"
#endif

namespace {

void do_system_info(void) {
  printf("[INFO] MicroBlaze V RISC-V SoC (DRAM Mode)\n");
  printf("[INFO] DDR2 Range: 0x60000000 - 0x67FFFFFF\n");
  printf("[INFO] Custom accelerator interface: CUSTOM-0\n");
  printf("[INFO] Clock: %u Hz\n", (unsigned)PLATFORM_CLOCK_HZ);
  printf("[INFO] Active model: %s\n", MODEL_NAME);
  perf_print_now();
}

const MenuItem kMainItems[] = {
    MENU_ITEM('1', "Project menu", do_proj_menu),
    MENU_ITEM('2', "Performance counter tests", perf_test_menu),
    MENU_ITEM('i', "System info", do_system_info),
    MENU_SENTINEL,
};

const Menu kMainMenu = {
    "CUSTOM SoC Platform",
    "main",
    kMainItems,
};

}  // namespace

int main(void) {
  printf("\nCUSTOM SoC Platform software\n");
  menu_run(&kMainMenu);
  return 0;
}
