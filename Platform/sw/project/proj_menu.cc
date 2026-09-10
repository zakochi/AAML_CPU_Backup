#include "proj_menu.h"

#include "accelerator_test.h"
#include "menu.h"

namespace {

const MenuItem kLabItems[] = {
    MENU_ITEM('a', "Accelerator AXI test", accelerator_test),
    MENU_END,
};

const Menu kLabMenu = {
    "Lab 0: Simple Accelerator Tests",
    "lab0",
    kLabItems,
};

}  // namespace

void lab_menu_run(void) { menu_run(&kLabMenu); }
