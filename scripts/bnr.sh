#!/bin/bash

# ----------------------------------------------------------------------------
#  Build and Run script (bnr.sh)
# ----------------------------------------------------------------------------
#  1) Assemble the boot, loader, and kernel code into bin files.
#  2) Create a blank 1.44MB disk image (boot.img).
#  3) Write the boot/loader/kernel binaries into the disk image.
#  4) Launch QEMU with the disk image.
# ----------------------------------------------------------------------------

# Directories
BUILD_DIR="build"
SRC_DIR="src"
LINKER_SCRIPT="linker.lds"

# Source paths
BOOT_SRC="$SRC_DIR/boot/boot.asm"
LOADER_SRC="$SRC_DIR/loader/loader.asm"
KERNEL_ASM_SRC="$SRC_DIR/kernel/kernel.asm"
TRAP_ASM_SRC="$SRC_DIR/kernel/trap.asm"
LIB_ASM_SRC="$SRC_DIR/lib/lib.asm"

MAIN_C_SRC="$SRC_DIR/kernel/main.c"
TRAP_C_SRC="$SRC_DIR/kernel/trap.c"
LIB_C_SRC="$SRC_DIR/lib/lib.c"
PRINT_C_SRC="$SRC_DIR/lib/print.c"
DEBUG_C_SRC="$SRC_DIR/lib/debug.c"

# Output files
BOOT_BIN="$BUILD_DIR/boot.bin"
LOADER_BIN="$BUILD_DIR/loader.bin"

KERNEL_ASM_OBJ="$BUILD_DIR/kernel_asm.o"
TRAP_ASM_OBJ="$BUILD_DIR/trap_asm.o"
LIB_ASM_OBJ="$BUILD_DIR/lib_asm.o"

MAIN_C_OBJ="$BUILD_DIR/main.o"
TRAP_C_OBJ="$BUILD_DIR/trap.o"
LIB_C_OBJ="$BUILD_DIR/lib.o"
PRINT_C_OBJ="$BUILD_DIR/print.o"
DEBUG_C_OBJ="$BUILD_DIR/debug.o"

KERNEL_ELF="$BUILD_DIR/kernel.elf"
KERNEL_BIN="$BUILD_DIR/kernel.bin"

DISK_IMG="$BUILD_DIR/boot.img"

# 1) Assemble/compile all components
mkdir -p "$BUILD_DIR"

echo -e "\e[1;3;34mHandling ASM Files:\e[0m"

echo -e "\e[36mAssembling bootloader...\e[0m"
nasm -f bin -o "$BOOT_BIN" "$BOOT_SRC"

echo -e "\e[36mAssembling loader...\e[0m"
nasm -f bin -o "$LOADER_BIN" "$LOADER_SRC"

echo -e "\e[36mCompiling kernel assembly (kernel.asm) to 64-bit object...\e[0m"
nasm -f elf64 -o "$KERNEL_ASM_OBJ" "$KERNEL_ASM_SRC"

echo -e "\e[36mCompiling trap assembly (trap.asm) to 64-bit object...\e[0m"
nasm -f elf64 -o "$TRAP_ASM_OBJ" "$TRAP_ASM_SRC"

echo -e "\e[36mCompiling lib assembly (lib.asm) to 64-bit object...\e[0m"
nasm -f elf64 -o "$LIB_ASM_OBJ" "$LIB_ASM_SRC"

echo
echo -e "\e[1;3;38;2;150;80;30mCompiling C Files:\e[0m"

echo -e "\e[33mCompiling main.c to 64-bit object...\e[0m"
# -ffreestanding : no standard lib assumptions
# -fno-stack-protector, -mno-red-zone : typical for kernel
# -m64 : ensures 64-bit code generation
gcc -std=c99 -m64 -ffreestanding -fno-stack-protector -mno-red-zone -c "$MAIN_C_SRC" -o "$MAIN_C_OBJ"

echo -e "\e[33mCompiling trap.c to 64-bit object...\e[0m"
# -ffreestanding : no standard lib assumptions
# -fno-stack-protector, -mno-red-zone : typical for kernel
# -m64 : ensures 64-bit code generation
gcc -std=c99 -m64 -ffreestanding -fno-stack-protector -mno-red-zone -c "$TRAP_C_SRC" -o "$TRAP_C_OBJ"

echo -e "\e[33mCompiling lib.c to 64-bit object...\e[0m"
# -ffreestanding : no standard lib assumptions
# -fno-stack-protector, -mno-red-zone : typical for kernel
# -m64 : ensures 64-bit code generation
gcc -std=c99 -m64 -ffreestanding -fno-stack-protector -mno-red-zone -c "$LIB_C_SRC" -o "$LIB_C_OBJ"

echo -e "\e[33mCompiling print.c to 64-bit object...\e[0m"
# -ffreestanding : no standard lib assumptions
# -fno-stack-protector, -mno-red-zone : typical for kernel
# -m64 : ensures 64-bit code generation
gcc -std=c99 -m64 -ffreestanding -fno-stack-protector -mno-red-zone -c "$PRINT_C_SRC" -o "$PRINT_C_OBJ"

echo -e "\e[33mCompiling debug.c to 64-bit object...\e[0m"
# -ffreestanding : no standard lib assumptions
# -fno-stack-protector, -mno-red-zone : typical for kernel
# -m64 : ensures 64-bit code generation
gcc -std=c99 -m64 -ffreestanding -fno-stack-protector -mno-red-zone -c "$DEBUG_C_SRC" -o "$DEBUG_C_OBJ"

echo
echo -e "\e[1;3;38;2;150;50;150mHandling kernel.elf:\e[0m"

echo -e "\e[1;3;38;2;180;60;180mLinking obj files => kernel.elf...\e[0m"
# -nostdlib: do not link against standard libs
# -T linker.lds: use your custom linker script
# -o "$KERNEL_ELF": output ELF
ld -nostdlib -z max-page-size=0x1000 -T "$LINKER_SCRIPT" -o "$KERNEL_ELF" \
   "$KERNEL_ASM_OBJ" \
   "$MAIN_C_OBJ" \
   "$TRAP_ASM_OBJ" \
   "$TRAP_C_OBJ"  \
   "$LIB_ASM_OBJ" \
   "$LIB_C_OBJ" \
   "$PRINT_C_OBJ" \
   "$DEBUG_C_OBJ"

echo -e "\e[1;3;38;2;180;60;180mConverting kernel.elf => kernel.bin (raw binary)...\e[0m"
objcopy -O binary "$KERNEL_ELF" "$KERNEL_BIN"

echo
echo -e "\e[1;3;38;2;150;140;30mCreating Disk Image:\e[0m"

# 2) Create a blank 1.44 MB disk image
echo -e "\e[38;2;180;170;60mCreating blank disk image (1.44MB)...\e[0m"
dd if=/dev/zero of="$DISK_IMG" bs=512 count=2880 2>/dev/null

# 3) Write bootloader to the first sector
echo -e "\e[38;2;180;170;60mWriting bootloader (boot.bin) to first sector...\e[0m"
dd if="$BOOT_BIN" of="$DISK_IMG" bs=512 count=1 conv=notrunc 2>/dev/null

# Write loader to next few sectors
echo -e "\e[38;2;180;170;60mWriting loader (loader.bin) starting at sector 1...\e[0m"
dd if="$LOADER_BIN" of="$DISK_IMG" bs=512 count=5 seek=1 conv=notrunc 2>/dev/null

# Write kernel after loader
echo -e "\e[38;2;180;170;60mWriting kernel (kernel.bin) starting at sector 6...\e[0m"
dd if="$KERNEL_BIN" of="$DISK_IMG" bs=512 count=100 seek=6 conv=notrunc 2>/dev/null

# 4) Run the disk image in QEMU
echo
echo -e "\e[1;3;38;2;40;200;100mLaunching QEMU with $DISK_IMG...\e[0m"
qemu-system-x86_64 \
  -m 1024 \
  -drive format=raw,file="$DISK_IMG",if=ide,index=0 \
  -boot c \
  -enable-kvm \
  -cpu host \
  -smp 1 \
  -vga std \
  -rtc base=localtime \
  -no-reboot \
  -serial null \
  -parallel none \
  -monitor stdio
