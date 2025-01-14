; ----------------------------------------------------------------------------
;  KERNEL.ASM (64-bit)
; ----------------------------------------------------------------------------
;  Responsibilities:
;   1) Define a 64-bit GDT, TSS, and their descriptors.
;   2) Load the GDT, set up the TSS selector.
;   3) Initialize PIT & PIC for basic interrupt handling.
;   4) Perform a far jump into the kernel entry point (KernelEntry).
;   5) From KernelEntry, call the main C function (KMain).
;
;  Extern:
;    - KMain: Defined in main.c (compiled to an object file).
; ----------------------------------------------------------------------------

section .data

; ----------------------------------------------------------------------------
;  GDT and TSS Area
; ----------------------------------------------------------------------------

align 8
Gdt64:
    dq 0                               ; NULL descriptor
    dq 0x0020980000000000              ; 64-bit code segment descriptor
    dq 0x0020f80000000000              ; 64-bit data segment descriptor
    dq 0x0000f20000000000              ; (Extra descriptor or TSS placeholder)

; TSS descriptor inside GDT
TssDesc:
    dw  TssLen - 1                     ; TSS limit
    dw  0                              ; TSS base low
    db  0
    db  0x89                           ; type=0x9 (TSS), present=1, DPL=0
    db  0
    db  0
    dq  0

; Calculate the size of Gdt64
Gdt64Len:  equ  $ - Gdt64

; Pointer (size + base) to load into GDTR
Gdt64Ptr:
    dw  Gdt64Len - 1
    dq  Gdt64

; ----------------------------------------------------------------------------
;  TSS Definition
; ----------------------------------------------------------------------------
Tss:
    dd 0                ; Reserved
    dq 0x150000         ; RSP0 = top of kernel stack (example address)
    times 88 db 0       ; Rest of TSS fields
    dd  TssLen

TssLen: equ  $ - Tss

section .text

; We call an external function "KMain" (defined in C).
extern KMain
global start

; ----------------------------------------------------------------------------
;  start: Primary entry point after the bootloader jumps here
; ----------------------------------------------------------------------------
start:
    ; ------------------------------------------------------------------------
    ; 1) Load the 64-bit GDT
    ; ------------------------------------------------------------------------
    lgdt  [Gdt64Ptr]

SetTss:
    ; ------------------------------------------------------------------------
    ; 2) Set up TSS descriptor fields so the CPU knows where TSS is.
    ; ------------------------------------------------------------------------
    mov   rax, Tss
    mov   [TssDesc + 2], ax       ; lower 16 bits of base
    shr   rax, 16
    mov   [TssDesc + 4], al       ; next 8 bits
    shr   rax, 8
    mov   [TssDesc + 7], al       ; next 8 bits
    shr   rax, 8
    mov   [TssDesc + 8], eax      ; remaining 32 bits of base

    ; Load the TSS via its selector => 0x20 (the 3rd descriptor in GDT)
    mov   ax, 0x20
    ltr   ax

InitPIT:
    ; ------------------------------------------------------------------------
    ; 3) Initialize PIT (Programmable Interval Timer)
    ;    - Channel 0, Mode 3, ~100 Hz
    ; ------------------------------------------------------------------------
    mov   al, (1 << 2) | (3 << 4)   ; channel=0, access=lo/hi, mode=3
    out   0x43, al

    mov   ax, 11931                 ; reload value for ~100Hz
    out   0x40, al
    mov   al, ah
    out   0x40, al

InitPIC:
    ; ------------------------------------------------------------------------
    ; 4) Remap the 8259 PIC to avoid CPU exceptions overlap.
    ; ------------------------------------------------------------------------
    mov   al, 0x11           ; ICW1: init, edge-triggered, expect ICW4
    out   0x20, al
    out   0xA0, al

    mov   al, 32             ; ICW2: master offset = 0x20
    out   0x21, al
    mov   al, 40             ; ICW2: slave offset = 0x28 (commonly 0x28 or 0x2F)
    out   0xA1, al

    mov   al, 4              ; ICW3: master has slave on IRQ2
    out   0x21, al
    mov   al, 2              ; ICW3: slave ID
    out   0xA1, al

    mov   al, 1              ; ICW4: 8086 mode, normal EOI
    out   0x21, al
    out   0xA1, al

    ; Mask interrupts on PIC
    ;  - master: all enabled except IRQ0 => 0b11111110 (0xFE)
    ;  - slave:  all disabled => 0b11111111 (0xFF)
    mov   al, 0b11111110
    out   0x21, al
    mov   al, 0b11111111
    out   0xA1, al

    ; ------------------------------------------------------------------------
    ; 5) Far jump to KernelEntry (64-bit code). We push segment & offset,
    ;    then use a 64-bit retf to switch the CPU instruction pointer.
    ; ------------------------------------------------------------------------
    push  8                ; 0x08 => code segment (the 2nd descriptor in GDT)
    push  KernelEntry
    db    0x48             ; REX.W prefix for 64-bit far return
    retf

; ----------------------------------------------------------------------------
;  KERNEL ENTRY (64-bit)
; ----------------------------------------------------------------------------
KernelEntry:
    ; Set a stack pointer for the kernel
    mov   rsp, 0x200000

    ; Call KMain (defined in main.c)
    call  KMain

End:
    hlt
    jmp End
