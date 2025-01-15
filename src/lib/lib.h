#ifndef _LIB_H_
#define _LIB_H_

#include <stdint.h>
#include <stddef.h>

/**
 * memset: Fills a block of memory with a specified value.
 *
 * @param buffer Pointer to the memory block to fill.
 * @param value The value to set in each byte of the memory block.
 * @param size The number of bytes to fill.
 */
void memset(void* buffer, char value, int size);

/**
 * memmove: Copies a block of memory from source to destination, handling overlap.
 *
 * @param dst Pointer to the destination memory block.
 * @param src Pointer to the source memory block.
 * @param size The number of bytes to copy.
 */
void memmove(void* dst, void* src, int size);

/**
 * memcpy: Copies a block of memory from source to destination.
 *
 * @param dst Pointer to the destination memory block.
 * @param src Pointer to the source memory block.
 * @param size The number of bytes to copy.
 */
void memcpy(void* dst, void* src, int size);

/**
 * memcmp: Compares two blocks of memory byte by byte.
 *
 * @param src1 Pointer to the first memory block.
 * @param src2 Pointer to the second memory block.
 * @param size The number of bytes to compare.
 * @return An integer less than, equal to, or greater than zero if the first block
 *         is found to be less than, equal to, or greater than the second block.
 */
int memcmp(void* src1, void* src2, int size);

/**
 * @brief Calculates the length of a null-terminated string.
 *
 * @param str Pointer to the null-terminated string.
 * @return The number of characters in the string, excluding the null terminator.
 */
size_t strlen(const char *str);

/**
 * @brief Copies a null-terminated string from source to destination.
 *
 * @param dest Pointer to the destination buffer.
 * @param src Pointer to the source string.
 * @return Pointer to the destination string.
 */
char* strcpy(char *dest, const char *src);

#endif  // _LIB_H_
