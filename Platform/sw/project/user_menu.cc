#include "user_menu.h"

#include <stdio.h>

#include "accel_ops.h"
#include "menu.h"
#include "perf.h"

namespace {

void do_hello(void) {
  puts("Hello from the user extension menu.");
}

void do_sample_cfu_op(void) {
  const uint32_t a = 100;
  const uint32_t b = 200;
  const uint64_t start = perf_get_mcycle64();
  const uint32_t result = accel_scalar_compute(a, b);
  const uint64_t elapsed = perf_get_mcycle64() - start;

  printf("accel_scalar_compute(%u, %u) = %u, cycles=", (unsigned)a,
         (unsigned)b, (unsigned)result);
  perf_print_cycles(elapsed);
  putchar('\n');
}

const MenuItem kUserItems[] = {
    MENU_ITEM('h', "hello from user menu", do_hello),
    MENU_ITEM('c', "sample custom instruction call", do_sample_cfu_op),
    MENU_END,
};

const Menu kUserMenu = {
    "User Extension Menu",
    "user",
    kUserItems,
};

}  // namespace

void user_menu_run(void) { menu_run(&kUserMenu); }
