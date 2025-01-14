#include "trap.h"
#include "../lib/print.h"
#include "../lib/lib.h"

/**
 * Displays a welcome message for AlecOS with ASCII art.
 */
static void welcome_message() {
    printk("\n\n");
    printk("         *                 *                  *              *\n");
    printk("                                                      *             *\n");
    printk("                        *            *                             ___\n");
    printk("  *               *                                          |     | |\n");
    printk("        *              _________##                 *        / \\    | |\n");
    printk("                      @\\\\\\\\\\\\\\\\\\##    *     |              |--o|===|-|\n");
    printk("  *                  @@@\\\\\\\\\\\\\\\\##\\       \\|/|/            |---|   |d|\n");
    printk("                    @@ @@\\\\\\\\\\\\\\\\\\\\\\    \\|\\\\|//|/     *   /     \\  |w|\n");
    printk("             *     @@@@@@@\\\\\\\\\\\\\\\\\\\\\\    \\|\\|/|/         |  U    | |b|\n");
    printk("                  @@@@@@@@@----------|    \\\\|//          |  S    |=| |\n");
    printk("       __         @@ @@@ @@__________|     \\|/           |  A    | | |\n");
    printk("  ____|_@|_       @@@@@@@@@__________|     \\|/           |_______| |_|\n");
    printk("=|__ _____ |=     @@@@ .@@@__________|      |             |@| |@|  | |\n");
    printk("____0_____0__\\|/__@@@@__@@@__________|_\\|/__|___\\|/__\\|/___________|_|_\n");
    printk("\n\n");
    printk("    Welcome to AlecOS - Where Innovation Meets the Stars!\n\n");
}

/**
 * Kernel entry point.
 * This function initializes the system and displays a welcome message.
 */
void KMain(void) {
    char *string = "Hello and Welcome to AlecOS!";
    int64_t value = 0x123456789ABCD;

    // Initialize the Interrupt Descriptor Table (IDT)
    init_idt();

    // Display the welcome message
    welcome_message();

    // Print a sample string and hexadecimal value
    printk("%s\n", string);
    printk("This value is equal to %x\n", value);

    printk("System initialization complete.\n");
    printk("Awaiting user input...\n");
}
