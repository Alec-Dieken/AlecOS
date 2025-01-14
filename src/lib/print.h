#ifndef _PRINT_H_
#define _PRINT_H_

/**
 * LINE_SIZE: Defines the number of characters in a single line of the screen buffer.
 * Typically used for managing text rendering in a fixed-width screen layout.
 */
#define LINE_SIZE 160

/**
 * ScreenBuffer: Represents a simple text-based screen buffer for managing output.
 *
 * @field buffer Pointer to the memory holding the screen content.
 * @field column Current column position in the buffer.
 * @field row Current row position in the buffer.
 */
struct ScreenBuffer {
    char* buffer;  ///< Pointer to the screen buffer memory.
    int column;    ///< Current column position for text rendering.
    int row;       ///< Current row position for text rendering.
};

/**
 * printk: Formats and prints a string to the screen or log.
 * Similar to printf but optimized for kernel or low-level output.
 *
 * @param format A format string specifying how to format the output.
 * @param ... Additional arguments corresponding to the format specifiers.
 * @return The number of characters printed, or a negative value if an error occurs.
 */
int printk(const char *format, ...);

#endif  // _PRINT_H_