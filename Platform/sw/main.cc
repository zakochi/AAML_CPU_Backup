#include <cstdio>
#include <cstring>
#include <cmath>

extern "C" {
    int printf(const char* format, ...);
    uint64_t get_system_cycles();
    void uart_putc(char c);
    char uart_getc();
}

// -----------------------------------------------------------------
// RISC-V Zicbom 快取管理巨集
// -----------------------------------------------------------------
#define CBO_CLEAN(addr) do { \
    register uint32_t a0 asm("a0") = (uint32_t)(addr); \
    __asm__ volatile (".balign 4\n\t.word 0x0015200F" : : "r" (a0) : "memory"); \
} while(0)

#define CBO_INVAL(addr) do { \
    register uint32_t a0 asm("a0") = (uint32_t)(addr); \
    __asm__ volatile (".balign 4\n\t.word 0x0005200F" : : "r" (a0) : "memory"); \
} while(0)

// -----------------------------------------------------------------
// NPU 指令封裝
// -----------------------------------------------------------------
inline uint32_t npu_scalar_compute(uint32_t src1, uint32_t src2, uint32_t funct7_val) {
    uint32_t result;
    __asm__ volatile (
        ".insn r 0x0B, 0x0, 0x05, %0, %1, %2"
        : "=r" (result)
        : "r" (src1), "r" (src2)
    );
    return result;
}

inline uint32_t npu_axi_read(volatile uint32_t* addr) {
    uint32_t result;
    __asm__ volatile (
        ".insn r 0x0B, 0x1, 0x00, %0, %1, x0"
        : "=r" (result)
        : "r" (addr)
    );
    return result;
}

inline void npu_axi_write(volatile uint32_t* addr, uint32_t data) {
    __asm__ volatile (
        ".insn r 0x0B, 0x2, 0x00, x0, %0, %1"
        :
        : "r" (addr), "r" (data)
        : "memory"
    );
}

// -----------------------------------------------------------------
// 測試區塊
// -----------------------------------------------------------------
volatile uint8_t memory_pool[65536] __attribute__((aligned(16384)));

void run_npu_hardware_test() {
    printf("\n>>> STARTING NPU FUNCTIONAL TEST...\n");
    int test_errors = 0;
    volatile uint32_t* test_addr = (uint32_t*)&memory_pool[0x2000];

    // 1. 純量運算
    printf("[TEST 1/3] Scalar Math... ");
    uint32_t sum = npu_scalar_compute(100, 200, 0);
    if (sum == 305) printf("PASS\n"); else { printf("FAIL (%u)\n", sum); test_errors++; }

    // 2. AXI Write
    printf("[TEST 2/3] AXI Write... ");
    *test_addr = 0; CBO_CLEAN(test_addr);
    npu_axi_write(test_addr, 0x55AA1234);
    CBO_INVAL(test_addr);
    if (*test_addr == 0x55AA1234) printf("PASS\n"); else { printf("FAIL (0x%08X)\n", *test_addr); test_errors++; }

    // 3. AXI Read
    printf("[TEST 3/3] AXI Read... ");
    *test_addr = 0xCAFE9999; CBO_CLEAN(test_addr);
    if (npu_axi_read(test_addr) == 0xCAFE9999) printf("PASS\n"); else { printf("FAIL\n"); test_errors++; }

    if (test_errors == 0) printf("[SUCCESS] All functional tests passed!\n");
}

void run_npu_mixed_stress_test() {
    printf("\n>>> STARTING MIXED STRESS TEST (10,000 loops)...\n");
    volatile uint32_t* test_addr = (uint32_t*)&memory_pool[0x3000];
    
    for (uint32_t i = 0; i < 10000; i++) {
        uint32_t op = i % 3;
        uint32_t val1 = i;
        uint32_t val2 = i + 1;

        if (op == 0) {
            if (npu_scalar_compute(val1, val2, 0) != (val1 + val2 + 5)) {
                printf("Error at Compute loop %d\n", i); return;
            }
        } 
        else if (op == 1) {
            npu_axi_write(test_addr, val1);
            CBO_INVAL(test_addr);
            if (*test_addr != val1) {
                printf("Error at Write loop %d: Expected 0x%08X, Got 0x%08X\n", i, val1, *test_addr); return;
            }
        } 
        else {
            *test_addr = val1;
            CBO_CLEAN(test_addr);
            if (npu_axi_read(test_addr) != val1) {
                printf("Error at Read loop %d: Expected 0x%08X\n", i, val1); return;
            }
        }

        if ((i % 2500) == 0) printf("Progress: %d/10000...\n", i);
    }
    printf("[SUCCESS] Mixed Stress Test complete!\n");
}

void bios_menu() {
    while (1) {
        printf("\n--- NPU TEST MENU ---\n");
        printf("1. Functional Test (3-step)\n");
        printf("2. Mixed Stress Test (10k loops)\n");
        printf("3. System Info\n");
        printf("4. Reboot\n");
        printf("> ");

        char cmd = uart_getc();
        uart_putc(cmd); 
        printf("\n");

        if (cmd == '1') run_npu_hardware_test();
        else if (cmd == '2') run_npu_mixed_stress_test(); // 修正了這裡
        else if (cmd == '3') printf("[INFO] NPU V1.0\n");
        else if (cmd == '4') ((void (*)(void))0x00000000)();
    }
}

int main(int argc, char* argv[]) {
    bios_menu();
    return 0;
}
