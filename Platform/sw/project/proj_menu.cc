#include "proj_menu.h"

#include "menu.h"
#include "npu_tests.h"
#include "tflm_runner.h"
#include "user_menu.h"

namespace {

const MenuItem kProjectItems[] = {
    MENU_ITEM('1', "NPU functional test", npu_run_functional_test),
    MENU_ITEM('2', "NPU mixed stress test", npu_run_mixed_stress_test),
    MENU_ITEM('3', "TFLM inference and verification", tflm_run_inference),
    MENU_ITEM('u', "User extension menu", user_menu_run),
    MENU_END,
};

const Menu kProjectMenu = {
    "Project Menu",
    "project",
    kProjectItems,
};

}  // namespace

extern "C" void do_proj_menu(void) { menu_run(&kProjectMenu); }
