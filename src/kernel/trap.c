#include "trap.h"

/**
 * IDT (Interrupt Descriptor Table) Pointer
 * Points to the array of IDT entries and specifies its size.
 */
static struct IdtPtr idt_pointer;

/**
 * Array of IDT entries
 * Contains up to 256 interrupt vector entries.
 */
static struct IdtEntry vectors[256];

/**
 * Initialize a single IDT entry.
 *
 * @param entry Pointer to the IDT entry to initialize.
 * @param addr Address of the interrupt handler function.
 * @param attribute Attribute byte specifying type and privilege level.
 */
static void init_idt_entry(struct IdtEntry *entry, uint64_t addr, uint8_t attribute) {
    entry->low = (uint16_t)addr;            // Lower 16 bits of the handler address
    entry->selector = 8;                    // Code segment selector (offset in GDT)
    entry->attr = attribute;                // Entry attributes
    entry->mid = (uint16_t)(addr >> 16);    // Middle 16 bits of the handler address
    entry->high = (uint32_t)(addr >> 32);   // Upper 32 bits of the handler address
}

/**
 * Initialize the IDT with interrupt vectors.
 * Sets up the interrupt vector table with the appropriate handler addresses and attributes.
 */
void init_idt(void) {
    // Initialize interrupt vector entries
    init_idt_entry(&vectors[0], (uint64_t)vector0, 0x8E);
    init_idt_entry(&vectors[1], (uint64_t)vector1, 0x8E);
    init_idt_entry(&vectors[2], (uint64_t)vector2, 0x8E);
    init_idt_entry(&vectors[3], (uint64_t)vector3, 0x8E);
    init_idt_entry(&vectors[4], (uint64_t)vector4, 0x8E);
    init_idt_entry(&vectors[5], (uint64_t)vector5, 0x8E);
    init_idt_entry(&vectors[6], (uint64_t)vector6, 0x8E);
    init_idt_entry(&vectors[7], (uint64_t)vector7, 0x8E);
    init_idt_entry(&vectors[8], (uint64_t)vector8, 0x8E);
    init_idt_entry(&vectors[10], (uint64_t)vector10, 0x8E);
    init_idt_entry(&vectors[11], (uint64_t)vector11, 0x8E);
    init_idt_entry(&vectors[12], (uint64_t)vector12, 0x8E);
    init_idt_entry(&vectors[13], (uint64_t)vector13, 0x8E);
    init_idt_entry(&vectors[14], (uint64_t)vector14, 0x8E);
    init_idt_entry(&vectors[16], (uint64_t)vector16, 0x8E);
    init_idt_entry(&vectors[17], (uint64_t)vector17, 0x8E);
    init_idt_entry(&vectors[18], (uint64_t)vector18, 0x8E);
    init_idt_entry(&vectors[19], (uint64_t)vector19, 0x8E);
    init_idt_entry(&vectors[32], (uint64_t)vector32, 0x8E);
    init_idt_entry(&vectors[39], (uint64_t)vector39, 0x8E);

    // Set up the IDT pointer
    idt_pointer.limit = sizeof(vectors) - 1; // Size of the IDT (in bytes - 1)
    idt_pointer.addr = (uint64_t)vectors;   // Address of the IDT array

    // Load the IDT using the lidt instruction
    load_idt(&idt_pointer);
}

/**
 * Trap handler function.
 * Handles interrupts and exceptions by processing the trap frame.
 *
 * @param tf Pointer to the TrapFrame containing CPU state at the time of the interrupt.
 */
void handler(struct TrapFrame *tf) {
    unsigned char isr_value;

    switch (tf->trapno) {
        case 32:
            // Timer interrupt (IRQ0)
            eoi();
            break;

        case 39:
            // Spurious interrupt (IRQ7)
            isr_value = read_isr();
            if ((isr_value & (1 << 7)) != 0) {
                eoi();
            }
            break;

        default:
            // Unhandled interrupt: enter infinite loop
            while (1) { }
    }
}
