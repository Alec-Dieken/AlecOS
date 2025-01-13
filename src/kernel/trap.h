#ifndef _TRAP_H_
#define _TRAP_H_

#include <stdint.h>

/**
 * IDT (Interrupt Descriptor Table) Entry Structure
 * Describes a single interrupt vector.
 */
struct IdtEntry {
    uint16_t low;        // Lower 16 bits of the handler address
    uint16_t selector;   // Code segment selector in GDT or LDT
    uint8_t res0;        // Reserved, set to 0
    uint8_t attr;        // Attributes (e.g., type, DPL, present)
    uint16_t mid;        // Middle 16 bits of the handler address
    uint32_t high;       // Upper 32 bits of the handler address (if 64-bit)
    uint32_t res1;       // Reserved, set to 0
} __attribute__((packed));

/**
 * Pointer to the IDT
 * Specifies the size and address of the IDT.
 */
struct IdtPtr {
    uint16_t limit;      // Size of the IDT (number of bytes - 1)
    uint64_t addr;       // Address of the first entry in the IDT
} __attribute__((packed));

/**
 * Trap Frame
 * Captures the CPU state during an interrupt or exception.
 */
struct TrapFrame {
    int64_t r15;         // General-purpose registers
    int64_t r14;
    int64_t r13;
    int64_t r12;
    int64_t r11;
    int64_t r10;
    int64_t r9;
    int64_t r8;
    int64_t rbp;
    int64_t rdi;
    int64_t rsi;
    int64_t rdx;
    int64_t rcx;
    int64_t rbx;
    int64_t rax;
    int64_t trapno;      // Trap number (interrupt vector number)
    int64_t errorcode;   // Error code (if applicable)
    int64_t rip;         // Instruction pointer
    int64_t cs;          // Code segment
    int64_t rflags;      // CPU flags
    int64_t rsp;         // Stack pointer
    int64_t ss;          // Stack segment
};

/**
 * Interrupt Vector Declarations
 * These functions correspond to individual interrupt vectors.
 */
void vector0(void);
void vector1(void);
void vector2(void);
void vector3(void);
void vector4(void);
void vector5(void);
void vector6(void);
void vector7(void);
void vector8(void);
void vector10(void);
void vector11(void);
void vector12(void);
void vector13(void);
void vector14(void);
void vector16(void);
void vector17(void);
void vector18(void);
void vector19(void);
void vector32(void);
void vector39(void);

/**
 * IDT Initialization
 * Initializes the Interrupt Descriptor Table.
 */
void init_idt(void);

/**
 * End of Interrupt (EOI)
 * Signals the end of processing for an interrupt.
 */
void eoi(void);

/**
 * Load IDT
 * Loads the IDT using the lidt instruction.
 * @param ptr Pointer to an IdtPtr structure specifying the IDT.
 */
void load_idt(struct IdtPtr *ptr);

/**
 * Read In-Service Register (ISR)
 * Reads the ISR to determine which interrupts are currently being processed.
 * @return The value of the ISR.
 */
unsigned char read_isr(void);

#endif  // _TRAP_H_
