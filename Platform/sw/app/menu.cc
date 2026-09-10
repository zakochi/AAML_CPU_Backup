#include "menu.h"

#include <stdio.h>
#include <string.h>

#include "runtime.h"

namespace {

void menu_print(const Menu* menu) {
  char underline[80];
  size_t title_len = strlen(menu->title);
  if (title_len >= sizeof(underline)) {
    title_len = sizeof(underline) - 1;
  }

  memset(underline, '=', title_len);
  underline[title_len] = '\0';

  printf("\n%s\n%s\n", menu->title, underline);
  for (const MenuItem* item = menu->items; item->selection; ++item) {
    printf(" %c: %s\n", item->selection, item->description);
  }
  printf("%s> ", menu->prompt);
}

const MenuItem* menu_get_selection(const Menu* menu) {
  char c = '\0';
  do {
    c = uart_getc();
  } while (c == '\n' || c == '\r');

  uart_putc(c);
  for (const MenuItem* item = menu->items; item->selection; ++item) {
    if (c == item->selection) {
      putchar('\n');
      return item;
    }
  }

  printf(" *unknown*\n");
  return 0;
}

}  // namespace

void menu_run(const Menu* menu) {
  bool exit_now = false;

  while (!exit_now) {
    menu_print(menu);
    const MenuItem* item = menu_get_selection(menu);
    if (item == 0) {
      continue;
    }

    if (item->exit) {
      exit_now = true;
    } else {
      printf("\nRunning %s\n", item->description);
      item->fn();
      puts("---");
    }
  }
}
