[BITS 16]
[ORG 0x7C00]

; ----------------------------------------------------------------------------
;  MBR Bootloader
;  Loads a secondary loader from disk using INT 0x13 extensions (AH=0x42).
; ----------------------------------------------------------------------------

Start:
    ; ------------------------------------------------------------------------
    ; 1) Zero registers, set segment registers, and initialize stack
    ; ------------------------------------------------------------------------
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00              ; put stack at 0x7C00 (top of boot sector)

    ; Save the boot drive number (BIOS sets DL to the boot drive)
    mov [BootDrive], dl

    ; ------------------------------------------------------------------------
    ; 2) Clear screen by setting 80x25 text mode (INT 0x10 AH=0)
    ; ------------------------------------------------------------------------
    mov ax, 0x0003              ; AL=3 => 80x25 text mode, clears display
    int 0x10

    ; ------------------------------------------------------------------------
    ; 3) Check for BIOS disk extensions (INT 0x13 AH=0x41)
    ;    This ensures we can use the Extended Read (AH=0x42).
    ; ------------------------------------------------------------------------
    mov ah, 0x41
    mov bx, 0x55AA                  ; "magic number" for disk extension check
    int 0x13
    jc   NoDiskExtensionsSupport    ; carry set => no support
    cmp  bx, 0xAA55
    jne  NoDiskExtensionsSupport    ; if bx != 0xAA55 => no support

    ; ------------------------------------------------------------------------
    ; 4) Load secondary loader at 0x7E00:0000 using Extended Read (AH=0x42)
    ; ------------------------------------------------------------------------
    mov si, ReadPacket
    mov word [si], 0x10         ; # of sectors to read (example: 16)
    mov word [si + 2], 5        ; size of the packet (varies by BIOS)
    mov word [si + 4], 0x7E00   ; offset where loader should be loaded
    mov word [si + 6], 0x0000   ; segment = 0 => use ES
    mov dword [si + 8], 1       ; LBA (low 32 bits) => sector 1
    mov dword [si + 0xC], 0     ; LBA (high 32 bits) => typically 0
    mov dl, [BootDrive]         ; restore boot drive
    mov ah, 0x42
    int 0x13
    jc  DiskReadError           ; carry set => read failed

    ; ------------------------------------------------------------------------
    ; 5) Jump to the secondary loader (now in 0x7E00:0000)
    ; ------------------------------------------------------------------------
    jmp 0x7E00

; ----------------------------------------------------------------------------
;  ERROR / NOT-SUPPORTED HANDLING
; ----------------------------------------------------------------------------
NoDiskExtensionsSupport:
DiskReadError:
    ; We just halt here if extended reads aren't supported or if read fails
    hlt

; ----------------------------------------------------------------------------
;  DATA SECTION
; ----------------------------------------------------------------------------
BootDrive:   db 0                ; Store BIOS drive number
ReadPacket:  times 16 db 0       ; Buffer for INT 0x13 Extended Read parameters

; ----------------------------------------------------------------------------
;  PARTITION TABLE & BOOT SIGNATURE
; ----------------------------------------------------------------------------
; Space up to 0x1BE (446 bytes total) => MBR code area
times (0x1BE - ($ - $$)) db 0

; Single partition entry example
db 0x80, 0, 2, 0, 0xF0, 0xFF, 0xFF, 0xFF    ; bootable, CHS start/end, type
dd 1                                        ; start LBA
dd (20 * 16 * 63 - 1)                       ; # of sectors
times (16 * 3) db 0                         ; fill remaining partition entries

; Boot Signature (0x55AA)
db 0x55
db 0xAA
