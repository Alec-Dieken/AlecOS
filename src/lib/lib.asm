section .text

; Exporting the symbols for external use
global memset
global memcpy
global memmove
global memcmp

;------------------------------------------------------------------------------
; memset: Fills a block of memory with a specified value
;------------------------------------------------------------------------------
memset:
    cld                          ; Clear the direction flag to increment addresses
    mov ecx, edx                 ; Copy the size (edx) to ecx (counter for rep stosb)
    mov al, sil                  ; Load the fill value (sil) into al
    rep stosb                    ; Fill ecx bytes of memory at rdi with the value in al
    ret                          ; Return

;------------------------------------------------------------------------------
; memcmp: Compares two blocks of memory byte by byte
;------------------------------------------------------------------------------
memcmp:
    cld                          ; Clear the direction flag to increment addresses
    xor eax, eax                 ; Zero out eax (return value)
    mov ecx, edx                 ; Set the comparison size (edx) in ecx
    repe cmpsb                   ; Compare ecx bytes of memory at rsi and rdi
    setnz al                     ; Set al to 1 if a mismatch is found, 0 otherwise
    ret                          ; Return

;------------------------------------------------------------------------------
; memcpy: Copies a block of memory from source to destination
; memmove: Same as memcpy but handles overlapping memory regions
;------------------------------------------------------------------------------
memcpy:
memmove:
    cld                          ; Clear the direction flag to increment addresses

    ; Check for memory overlap (source < destination < source + size)
    cmp rsi, rdi                 ; Compare source (rsi) with destination (rdi)
    jae .copy                    ; If source >= destination, no overlap, go to .copy

    mov r8, rsi                  ; Temporary register r8 = source (rsi)
    add r8, rdx                  ; r8 = source + size
    cmp r8, rdi                  ; Check if destination (rdi) is within the source range
    jbe .copy                    ; If destination >= source + size, no overlap, go to .copy

.overlap:
    std                          ; Set the direction flag to decrement addresses
    add rdi, rdx                 ; Adjust destination pointer to the end
    add rsi, rdx                 ; Adjust source pointer to the end
    sub rdi, 1                   ; Move destination pointer one step back
    sub rsi, 1                   ; Move source pointer one step back

.copy:
    mov ecx, edx                 ; Set the size (edx) in ecx (counter for rep movsb)
    rep movsb                    ; Copy ecx bytes from source (rsi) to destination (rdi)
    cld                          ; Clear the direction flag to ensure default behavior
    ret                          ; Return
