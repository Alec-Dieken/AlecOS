#include "stdint.h"
#include "stdarg.h"
#include "print.h"
#include "lib.h"

// Screen buffer initialized to VGA text mode address
static struct ScreenBuffer screen_buffer = {(char*)0xb8000, 0, 0};

/**
 * Converts an unsigned integer to a string representation.
 *
 * @param buffer Pointer to the output buffer.
 * @param position Starting position in the buffer.
 * @param digits The unsigned integer to convert.
 * @return The number of characters written to the buffer.
 */
static int udecimal_to_string(char *buffer, int position, uint64_t digits) {
    char digits_map[10] = "0123456789";
    char digits_buffer[25];
    int size = 0;

    // Extract digits in reverse order
    do {
        digits_buffer[size++] = digits_map[digits % 10];
        digits /= 10;
    } while (digits != 0);

    // Write digits in correct order to the buffer
    for (int i = size - 1; i >= 0; i--) {
        buffer[position++] = digits_buffer[i];
    }

    return size;
}

/**
 * Converts a signed integer to a string representation.
 *
 * @param buffer Pointer to the output buffer.
 * @param position Starting position in the buffer.
 * @param digits The signed integer to convert.
 * @return The number of characters written to the buffer.
 */
static int decimal_to_string(char *buffer, int position, int64_t digits) {
    int size = 0;

    // Handle negative numbers
    if (digits < 0) {
        digits = -digits;
        buffer[position++] = '-';
        size = 1;
    }

    size += udecimal_to_string(buffer, position, (uint64_t)digits);
    return size;
}

/**
 * Converts an unsigned integer to a hexadecimal string representation.
 *
 * @param buffer Pointer to the output buffer.
 * @param position Starting position in the buffer.
 * @param digits The unsigned integer to convert.
 * @return The number of characters written to the buffer.
 */
static int hex_to_string(char *buffer, int position, uint64_t digits) {
    char digits_buffer[25];
    char digits_map[16] = "0123456789ABCDEF";
    int size = 0;

    // Extract digits in reverse order
    do {
        digits_buffer[size++] = digits_map[digits % 16];
        digits /= 16;
    } while (digits != 0);

    // Write digits in correct order to the buffer
    for (int i = size - 1; i >= 0; i--) {
        buffer[position++] = digits_buffer[i];
    }

    buffer[position++] = 'H'; // Append 'H' for hexadecimal notation
    return size + 1;
}

/**
 * Copies a string into a buffer.
 *
 * @param buffer Pointer to the output buffer.
 * @param position Starting position in the buffer.
 * @param string Pointer to the input string.
 * @return The number of characters written to the buffer.
 */
static int read_string(char *buffer, int position, const char *string) {
    int index = 0;

    while (string[index] != '\0') {
        buffer[position++] = string[index++];
    }

    return index;
}

/**
 * Writes a buffer to the screen with text wrapping and scrolling.
 *
 * @param buffer Pointer to the text buffer.
 * @param size Number of characters to write.
 * @param sb Pointer to the screen buffer structure.
 * @param color Text color to apply.
 */
static void write_screen(const char *buffer, int size, struct ScreenBuffer *sb, char color) {
    int column = sb->column;
    int row = sb->row;

    for (int i = 0; i < size; i++) {
        // Scroll screen if row exceeds 24
        if (row >= 25) {
            memcpy(sb->buffer, sb->buffer + LINE_SIZE, LINE_SIZE * 24);
            memset(sb->buffer + LINE_SIZE * 24, 0, LINE_SIZE);
            row--;
        }

        if (buffer[i] == '\n') {
            column = 0;
            row++;
        } else {
            sb->buffer[column * 2 + row * LINE_SIZE] = buffer[i];
            sb->buffer[column * 2 + row * LINE_SIZE + 1] = color;
            column++;

            if (column >= 80) {
                column = 0;
                row++;
            }
        }
    }

    sb->column = column;
    sb->row = row;
}

/**
 * printk: Formats and prints a string to the screen.
 *
 * @param format Format string with optional specifiers (e.g., %d, %x, %s).
 * @param ... Additional arguments matching the format specifiers.
 * @return The number of characters written to the screen.
 */
int printk(const char *format, ...) {
    char buffer[1024];
    int buffer_size = 0;
    int64_t integer = 0;
    char *string = 0;
    va_list args;

    va_start(args, format);

    for (int i = 0; format[i] != '\0'; i++) {
        if (format[i] != '%') {
            buffer[buffer_size++] = format[i];
        } else {
            switch (format[++i]) {
                case 'x':
                    integer = va_arg(args, int64_t);
                    buffer_size += hex_to_string(buffer, buffer_size, (uint64_t)integer);
                    break;

                case 'u':
                    integer = va_arg(args, int64_t);
                    buffer_size += udecimal_to_string(buffer, buffer_size, (uint64_t)integer);
                    break;

                case 'd':
                    integer = va_arg(args, int64_t);
                    buffer_size += decimal_to_string(buffer, buffer_size, integer);
                    break;

                case 's':
                    string = va_arg(args, char*);
                    buffer_size += read_string(buffer, buffer_size, string);
                    break;

                default:
                    buffer[buffer_size++] = '%';
                    i--;
            }
        }
    }

    write_screen(buffer, buffer_size, &screen_buffer, 0xf); // Write to screen in white color
    va_end(args);

    return buffer_size;
}
