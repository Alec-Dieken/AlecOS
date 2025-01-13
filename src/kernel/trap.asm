section .text

; External and global symbols
extern handler                ; External handler function

; Global vectors and functions
global vector0
global vector1
global vector2
global vector3
global vector4
global vector5
global vector6
global vector7
global vector8
global vector10
global vector11
global vector12
global vector13
global vector14
global vector16
global vector17
global vector18
global vector19
global vector32
global vector39
global eoi
global read_isr
global load_idt

; Macro to define interrupt vectors to reduce repetitive code
%macro DEFINE_VECTOR 2
%1:
    push 0             ; Error code placeholder (0 if no error code)
    push %2            ; Interrupt vector number
    jmp Trap           ; Jump to common Trap handler
%endmacro

; Trap handler
Trap:
    ; Save all general-purpose registers
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    ; Increment memory value
    inc byte [0xb8010]
    mov byte [0xb8011], 0xe

    ; Pass stack pointer (rsp) to the handler
    mov rdi, rsp
    call handler

TrapReturn:
    ; Restore all general-purpose registers
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax

    ; Adjust stack pointer and return from interrupt
    add rsp, 16          ; Adjust stack in case of alignment issues
    iretq                ; Return from interrupt

; Define interrupt vectors using the macro
DEFINE_VECTOR vector0, 0
DEFINE_VECTOR vector1, 1
DEFINE_VECTOR vector2, 2
DEFINE_VECTOR vector3, 3
DEFINE_VECTOR vector4, 4
DEFINE_VECTOR vector5, 5
DEFINE_VECTOR vector6, 6
DEFINE_VECTOR vector7, 7
DEFINE_VECTOR vector8, 8
DEFINE_VECTOR vector10, 10
DEFINE_VECTOR vector11, 11
DEFINE_VECTOR vector12, 12
DEFINE_VECTOR vector13, 13
DEFINE_VECTOR vector14, 14
DEFINE_VECTOR vector16, 16
DEFINE_VECTOR vector17, 17
DEFINE_VECTOR vector18, 18
DEFINE_VECTOR vector19, 19
DEFINE_VECTOR vector32, 32
DEFINE_VECTOR vector39, 39

; End of Interrupt (EOI)
eoi:
    mov al, 0x20           ; Send End-of-Interrupt signal
    out 0x20, al
    ret

; Read ISR (In-Service Register)
read_isr:
    mov al, 0x0B           ; Command to read ISR
    out 0x20, al
    in al, 0x20            ; Read ISR value
    ret

; Load IDT (Interrupt Descriptor Table)
load_idt:
    lidt [rdi]             ; Load IDT from the address in rdi
    ret
