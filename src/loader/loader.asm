[BITS 16]
[ORG 0x7E00]

; ----------------------------------------------------------------------------
;  16-BIT REAL MODE BOOTSTRAP
; ----------------------------------------------------------------------------

start:
    ; ------------------------------------------------------------------------
    ; 1) Save boot drive and set cursor position to top-left
    ; ------------------------------------------------------------------------
    mov [BootDrive], dl          ; Store the BIOS drive number (DL) for later
    xor bh, bh                   ; Page number = 0
    xor dh, dh                   ; Row = 0
    xor dl, dl                   ; Column = 0
    mov ah, 0x02                 ; BIOS: Set cursor position
    int 0x10

    ; Print "Start of bootloader"
    mov si, DebugStart
    call PrintMessage
    call NextLine

    ; ------------------------------------------------------------------------
    ; 2) CPUID checks for extended functions, long mode, SSE2
    ; ------------------------------------------------------------------------

    ; Check if the CPU supports extended functions (CPUID with EAX=0x80000000)
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001         ; Must support at least 0x80000001
    jb  NoExtendedFunctionsSupport

    ; Print confirmation
    mov si, DebugExtSupported
    call PrintMessage
    call NextLine

    ; Check for Long Mode & SSE2 via CPUID with EAX=0x80000001
    mov eax, 0x80000001
    cpuid

    ; Bit 29 in EDX -> Long Mode
    test edx, 0x20000000
    jz  NoLongModeSupport

    ; Bit 26 in EDX -> SSE2
    test edx, 0x04000000
    jz  NoSSE2Support

LoadKernelExtended:
    ; ------------------------------------------------------------------------
    ; 3) Read kernel from disk (INT 0x13 AH=0x42 - Extended Read)
    ; ------------------------------------------------------------------------
    mov si, ReadPacket
    mov word [si], 0x10         ; Number of sectors to read (0x10 = 16)
    mov word [si + 2], 100      ; Size of packet (some BIOSes ignore)
    mov word [si + 4], 0        ; Reserved
    mov word [si + 6], 0x1000   ; Destination offset in memory (within DS)
    mov dword [si + 8], 6       ; LBA (low 32 bits)
    mov dword [si + 0xC], 0     ; LBA (high 32 bits)
    mov dl, [BootDrive]         ; Restore the saved drive ID
    mov ah, 0x42                ; Extended read
    int 0x13
    jc  DiskReadError           ; Jump if read failed (carry set)

GetE820MemoryMap:
    ; ------------------------------------------------------------------------
    ; 4) E820 memory detection
    ; ------------------------------------------------------------------------
    mov eax, 0xE820
    mov edx, 0x534D4150         ; 'SMAP' signature
    mov ecx, 20                 ; Size of the E820 buffer
    mov edi, 0x9000             ; Store the map at 0x9000
    xor ebx, ebx                ; Continuation value
    int 0x15
    jc  NoMemoryInfoSupport     ; If CF=1, E820 not supported

ContinueE820:
    add edi, 20                 ; Move pointer to next memory map entry
    mov eax, 0xE820
    mov edx, 0x534D4150
    mov ecx, 20
    int 0x15
    jc  E820Done

    test ebx, ebx
    jnz ContinueE820

E820Done:
    ; Print message that kernel loaded & memory fetch done
    mov si, SuccessMessage
    call PrintMessage
    call NextLine

CheckA20Line:
    ; ------------------------------------------------------------------------
    ; 5) Quick A20 line test (simple check)
    ; ------------------------------------------------------------------------
    mov ax, 0xFFFF
    mov es, ax
    mov word [ds:0x7C00], 0xA200
    cmp word [es:0x7C10], 0xA200
    jne EnableA20Message
    mov word [0x7C00], 0xB200
    cmp word [es:0x7C10], 0xB200
    je  JumpToEnd

EnableA20Message:
    xor ax, ax
    mov es, ax
    mov si, A20LineSetMsg
    call PrintMessage
    call NextLine

EnterProtectedMode:
    ; ------------------------------------------------------------------------
    ; 6) Set simple text mode, then jump into protected mode
    ; ------------------------------------------------------------------------
    mov ax, 3
    int 0x10                    ; Set 80x25 text mode (clears screen)

    cli                         ; Disable interrupts
    lgdt [Gdt32Ptr]             ; Load 32-bit GDT
    lidt [Idt32Ptr]             ; Load 32-bit IDT (stub or empty)

    mov eax, cr0
    or eax, 1                   ; Set PE bit (bit 0) to enable protected mode
    mov cr0, eax

    ; Far jump to flush CPU pipeline and load CS
    jmp 0x08:ProtectedModeEntry

; ----------------------------------------------------------------------------
;  ERROR HANDLING / NOT-SUPPORTED
; ----------------------------------------------------------------------------

NoExtendedFunctionsSupport:
    mov si, ExtFuncsNotSupported
    call PrintMessage
    jmp JumpToEnd

NoLongModeSupport:
    mov si, LongModeNotSupported
    call PrintMessage
    jmp JumpToEnd

NoSSE2Support:
    mov si, SSE2NotSupported
    call PrintMessage
    jmp JumpToEnd

NoMemoryInfoSupport:
    mov si, MemInfoNotSupported
    call PrintMessage
    jmp JumpToEnd

DiskReadError:
    mov si, DiskReadErrorMsg
    call PrintMessage
    jmp JumpToEnd

; ----------------------------------------------------------------------------
;  SUBROUTINES (16-bit)
; ----------------------------------------------------------------------------

NextLine:
    ; Move the cursor down one line
    mov ah, 0x03     ; BIOS: read cursor position
    xor bh, bh
    int 0x10
    inc dh           ; increment row
    xor dl, dl       ; reset column to 0
    mov ah, 0x02     ; BIOS: set cursor position
    int 0x10
    ret

PrintMessage:
    ; Prints a null-terminated string from DS:SI
    pusha
.PrintChar:
    lodsb
    or al, al
    jz  .Done
    mov ah, 0x0E     ; BIOS Teletype
    int 0x10
    jmp .PrintChar
.Done:
    popa
    ret

PrintRegister:
    ; Example routine to print EDX in hex
    pusha
    mov cx, 8
.PrintHexLoop:
    rol edx, 4
    mov al, dl
    and al, 0x0F
    add al, '0'
    cmp al, '9'
    jbe .PrintHexChar
    add al, 7
.PrintHexChar:
    mov ah, 0x0E
    int 0x10
    loop .PrintHexLoop
    popa
    ret

JumpToEnd:
    hlt
    jmp JumpToEnd

; ----------------------------------------------------------------------------
;  32-BIT PROTECTED MODE
; ----------------------------------------------------------------------------
[BITS 32]

ProtectedModeEntry:
    ; ------------------------------------------------------------------------
    ; Set up data segments
    ; ------------------------------------------------------------------------
    mov ax, 0x10   ; Selector for data segment in GDT32
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x7C00

    ; Example: Clear an area in memory for page tables or kernel usage
    cld
    mov edi, 0x80000
    xor eax, eax
    mov ecx, 0x10000 / 4
    rep stosd

    ; Simple page table setup, or set up for 64-bit transition
    mov dword [0x80000], 0x81007        ; PDE/PTE example
    mov dword [0x81000], 10000111b      ; PDE bits, etc.

    lgdt [Gdt64Ptr]                     ; Prepare 64-bit GDT

    ; Enable PAE bit in CR4 (bit 5)
    mov eax, cr4
    or eax, (1 << 5)
    mov cr4, eax

    ; Set CR3 to the page directory (for identity mapping, etc.)
    mov eax, 0x80000
    mov cr3, eax

    ; Enable Long Mode in the EFER MSR (0xC0000080), set LME bit (bit 8)
    mov ecx, 0xC0000080    ; EFER Model-Specific Register
    rdmsr
    or eax, (1 << 8)       ; LME = Long Mode Enable
    wrmsr

    ; Enable paging & stay in protected mode momentarily
    mov eax, cr0
    or eax, (1 << 31)      ; Set PG bit
    mov cr0, eax

    ; Far jump into 64-bit code
    jmp 0x08:LongModeEntry

ProtectedModeEnd:
    hlt
    jmp ProtectedModeEnd

; ----------------------------------------------------------------------------
;  64-BIT LONG MODE
; ----------------------------------------------------------------------------
[BITS 64]

LongModeEntry:
    ; ------------------------------------------------------------------------
    ; 64-bit entry point
    ; ------------------------------------------------------------------------
    mov rsp, 0x7C00

    cld
    mov rdi, 0x200000
    mov rsi, 0x10000
    mov rcx, 51200 / 8
    rep movsq

    jmp 0x200000

LongModeEnd:
    hlt
    jmp LongModeEnd

; ----------------------------------------------------------------------------
;  DATA SECTION
; ----------------------------------------------------------------------------

; --- Boot messages ---
DebugStart:             db "Start of bootloader.", 0
DebugExtSupported:      db "Extended functions supported.", 0
SuccessMessage:         db "Kernel loaded & memory fetch complete.", 0
A20LineSetMsg:          db "A20 line is set.", 0

; --- Error messages ---
DiskReadErrorMsg:       db "Error reading disk.", 0
ExtFuncsNotSupported:   db "Extended functions not supported.", 0
LongModeNotSupported:   db "Long mode not supported.", 0
SSE2NotSupported:       db "SSE2 not supported.", 0
MemInfoNotSupported:    db "Memory info not supported.", 0

; --- Extended Read Packet (INT 0x13 AH=0x42) ---
ReadPacket: times 16 db 0

; --- BIOS Drive Number ---
BootDrive: db 0

; ----------------------------------------------------------------------------
;  GDT (32-bit) / IDT (32-bit)
; ----------------------------------------------------------------------------
align 4

Gdt32:
    dq 0                     ; NULL descriptor
Code32:
    dw 0xFFFF                ; Limit low
    dw 0x0000                ; Base low
    db 0x00                  ; Base middle
    db 0x9A                  ; Access (code seg)
    db 0xCF                  ; Granularity
    db 0x00                  ; Base high

Data32:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92                  ; Access (data seg)
    db 0xCF
    db 0x00

Gdt32Len:  equ $ - Gdt32
Gdt32Ptr:  dw Gdt32Len - 1
           dd Gdt32

; Empty 32-bit IDT
Idt32Ptr:  dw 0
           dd 0

; ----------------------------------------------------------------------------
;  GDT (64-bit)
; ----------------------------------------------------------------------------
align 8

Gdt64:
    dq 0                            ; NULL descriptor
    dq 0x0020980000000000           ; Code segment descriptor (64-bit)
Gdt64Len: equ $ - Gdt64
Gdt64Ptr: dw Gdt64Len - 1
          dd Gdt64
