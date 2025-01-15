#include "lib.h"

/**
 * @brief Calculates the length of a null-terminated string.
 *
 * @param str Pointer to the null-terminated string.
 * @return The number of characters in the string, excluding the null terminator.
 */
size_t strlen(const char *str) {
    size_t len = 0;
    while (str[len] != '\0') {
        len++;
    }
    return len;
}

/**
 * @brief Copies a null-terminated string from source to destination.
 *
 * @param dest Pointer to the destination buffer.
 * @param src Pointer to the source string.
 * @return Pointer to the destination string.
 */
char* strcpy(char *dest, const char *src) {
    size_t i = 0;
    while (src[i] != '\0') {
        dest[i] = src[i];
        i++;
    }
    dest[i] = '\0';
    return dest;
}
