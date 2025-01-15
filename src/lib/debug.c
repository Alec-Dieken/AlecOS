#include "debug.h"
#include "print.h"  // Ensure this header provides declarations for `printk` and `vprintk`
#include <stdarg.h>

// ----------------------------------------------------------------------------
//  debug.c
// ----------------------------------------------------------------------------
//  Implements debugging functions for AlecOS, including logging, assertion
//  handling, stack tracing, and memory dumping.
// ----------------------------------------------------------------------------

/**
 * @brief Logs a formatted message with a specified log level.
 *
 * This function prints a formatted message to the screen with a prefix indicating
 * the severity level. It can be extended to log to additional interfaces like
 * serial ports.
 *
 * @param level The severity level of the log message.
 * @param format The format string (printf-style).
 * @param ... Variable arguments corresponding to the format string.
 */
void log_message(log_level_t level, const char *format, ...) {
    va_list args;
    va_start(args, format);

    // Print log level prefix
    switch (level) {
        case LOG_INFO:
            printk("[INFO] ");
            break;
        case LOG_WARN:
            printk("[WARN] ");
            break;
        case LOG_ERROR:
            printk("[ERROR] ");
            break;
        case LOG_PANIC:
            printk("[PANIC] ");
            break;
        default:
            printk("[UNKNOWN] ");
            break;
    }

    // Print the formatted message using vprintk
    vprintk(format, args);

    va_end(args);
}

/**
 * @brief Handles failed assertions by displaying an error message and halting.
 *
 * This function prints a critical error message indicating where the assertion
 * failed, dumps the CPU registers and memory, disables interrupts, and halts
 * the system by entering an infinite loop.
 *
 * @param file The name of the file where the assertion failed.
 * @param line The line number where the assertion failed.
 */
void error_check(const char *file, uint64_t line) {
    // Print panic header
    log_message(LOG_PANIC, "------------------------------------------\n");
    log_message(LOG_PANIC, "                 PANIC\n");
    log_message(LOG_PANIC, "------------------------------------------\n");

    // Print assertion failure details
    log_message(LOG_PANIC, "Assertion Failed: %s:%u\n", file, line);

    // Dump CPU registers and memory for debugging
    dump_registers();
    // dump_memory(0x200000, 256); // Example: dump 256 bytes starting at 0x200000

    // Disable interrupts to prevent any further operations
    __asm__ volatile ("cli");

    // Enter an infinite loop to halt the system
    while (1) { }
}

/**
 * @brief Dumps the current CPU registers for debugging purposes.
 *
 * This function captures and prints the values of critical CPU registers.
 * It's useful for diagnosing the state of the system at the time of an error.
 */
void dump_registers(void) {
    uint64_t rax, rbx, rcx, rdx, rsi, rdi, rbp, rsp;
    uint64_t r8, r9, r10, r11, r12, r13, r14, r15;

    // Inline assembly to capture register values
    __asm__ volatile (
        "mov %%rax, %0 \n"
        "mov %%rbx, %1 \n"
        "mov %%rcx, %2 \n"
        "mov %%rdx, %3 \n"
        "mov %%rsi, %4 \n"
        "mov %%rdi, %5 \n"
        "mov %%rbp, %6 \n"
        "mov %%rsp, %7 \n"
        "mov %%r8,  %8 \n"
        "mov %%r9,  %9 \n"
        "mov %%r10, %10 \n"
        "mov %%r11, %11 \n"
        "mov %%r12, %12 \n"
        "mov %%r13, %13 \n"
        "mov %%r14, %14 \n"
        "mov %%r15, %15 \n"
        : "=m" (rax), "=m" (rbx), "=m" (rcx), "=m" (rdx),
          "=m" (rsi), "=m" (rdi), "=m" (rbp), "=m" (rsp),
          "=m" (r8), "=m" (r9), "=m" (r10), "=m" (r11),
          "=m" (r12), "=m" (r13), "=m" (r14), "=m" (r15)
        :
        : "memory"
    );

    // Print register values using %llu for 64-bit
    log_message(LOG_INFO, "Register Dump:\n");
    log_message(LOG_INFO, "RAX: 0x%u\n", rax);
    log_message(LOG_INFO, "RBX: 0x%u\n", rbx);
    log_message(LOG_INFO, "RCX: 0x%u\n", rcx);
    log_message(LOG_INFO, "RDX: 0x%u\n", rdx);
    log_message(LOG_INFO, "RSI: 0x%u\n", rsi);
    log_message(LOG_INFO, "RDI: 0x%u\n", rdi);
    log_message(LOG_INFO, "RBP: 0x%u\n", rbp);
    log_message(LOG_INFO, "RSP: 0x%u\n", rsp);
    log_message(LOG_INFO, "R8 : 0x%u\n", r8);
    log_message(LOG_INFO, "R9 : 0x%u\n", r9);
    log_message(LOG_INFO, "R10: 0x%u\n", r10);
    log_message(LOG_INFO, "R11: 0x%u\n", r11);
    log_message(LOG_INFO, "R12: 0x%u\n", r12);
    log_message(LOG_INFO, "R13: 0x%u\n", r13);
    log_message(LOG_INFO, "R14: 0x%u\n", r14);
    log_message(LOG_INFO, "R15: 0x%u\n", r15);
}

/**
 * @brief Formats a single byte as two hexadecimal characters.
 *
 * @param byte The byte to format.
 * @param buffer The buffer to append the formatted characters.
 * @param position The current position in the buffer.
 * @return The new position in the buffer after appending.
 */
static int format_byte_hex(uint8_t byte, char *buffer, int position) {
    const char hex_map[16] = "0123456789ABCDEF";
    buffer[position++] = hex_map[(byte >> 4) & 0x0F];
    buffer[position++] = hex_map[byte & 0x0F];
    buffer[position++] = ' '; // Add space after each byte
    return position;
}

/**
 * @brief Dumps a section of memory for debugging purposes.
 *
 * This function prints a hexadecimal dump of memory starting at the specified
 * address for the given size. Useful for inspecting memory contents during
 * debugging.
 *
 * @param address The starting memory address to dump.
 * @param size The number of bytes to dump.
 */
void dump_memory(uint64_t address, uint64_t size) {
    volatile char *ptr = (volatile char *)address;
    log_message(LOG_INFO, "Memory Dump at 0x%llu (Size: %llu bytes):\n", address, size);
    for (uint64_t i = 0; i < size; i++) {
        char byte_buffer[4]; // Two hex digits + space + null terminator
        int pos = 0;
        pos = format_byte_hex((unsigned char)ptr[i], byte_buffer, pos);
        byte_buffer[pos] = '\0'; // Null-terminate
        log_message(LOG_INFO, "%s", byte_buffer); // Print the formatted byte
        if ((i + 1) % 16 == 0) {
            log_message(LOG_INFO, "\n");
        }
    }
    log_message(LOG_INFO, "\n");
}
