#ifndef PLATFORM_SW_APP_RUNTIME_H_
#define PLATFORM_SW_APP_RUNTIME_H_

#ifdef __cplusplus
extern "C" {
#endif

void uart_putc(char c);
char uart_getc(void);

#ifdef __cplusplus
}
#endif

static inline void runtime_reboot(void) {
  ((void (*)(void))0x00000000)();
}

#endif  // PLATFORM_SW_APP_RUNTIME_H_
