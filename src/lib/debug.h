#ifndef ALECOS_DEBUG_H
#define ALECOS_DEBUG_H

#include <stdint.h>
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Log levels for debug messages.
 */
typedef enum {
    LOG_INFO,   /**< Informational messages */
    LOG_WARN,   /**< Warning messages */
    LOG_ERROR,  /**< Error messages */
    LOG_PANIC   /**< Critical panic messages */
} log_level_t;

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
void log_message(log_level_t level, const char *format, ...);

/**
 * @brief Handles failed assertions by displaying an error message and halting.
 *
 * This function prints an error message indicating the file and line number
 * where the assertion failed, dumps the CPU registers and memory, disables
 * interrupts, and halts the system by entering an infinite loop.
 *
 * @param file The name of the file where the assertion failed.
 * @param line The line number where the assertion failed.
 */
void error_check(const char *file, uint64_t line);

/**
 * @brief Asserts that a condition is true. If not, triggers a panic.
 *
 * This macro evaluates the expression `expr`. If `expr` is false, it calls
 * `error_check` with the current file name and line number.
 *
 * @param expr The expression to evaluate.
 */
#define ASSERT(expr) do {                      \
    if (!(expr)) {                             \
        error_check(__FILE__, __LINE__);       \
    }                                          \
} while (0)

/**
 * @brief Dumps the current CPU registers for debugging purposes.
 *
 * This function captures and prints the values of critical CPU registers.
 * It's useful for diagnosing the state of the system at the time of an error.
 */
void dump_registers(void);

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
void dump_memory(uint64_t address, uint64_t size);

#ifdef __cplusplus
}
#endif

#endif // ALECOS_DEBUG_H
