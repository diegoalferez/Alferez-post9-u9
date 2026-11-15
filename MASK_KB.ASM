; MASK_KB.ASM - Enmascarar y desenmascarar IRQ1 con el PIC 8259A
; Compila: nasm -f bin MASK_KB.ASM -o MASK_KB.COM

[BITS 16]
[ORG 0x100]

PIC_IMR   EQU 21h               ; IMR del PIC maestro
IRQ1_MASK EQU 02h               ; bit 1 del IMR = IRQ1 (teclado)
WAIT_TICKS EQU 55               ; 55 ticks a 18.2 ticks/s = unos 3 segundos

start:
; El programa lee el IMR actual y lo guarda en la pila
    IN AL, PIC_IMR
    PUSH AX

; Se enmascara IRQ1 (bit 1 del IMR en 1 = deshabilitada)
    OR AL, IRQ1_MASK
    OUT PIC_IMR, AL

    MOV AH, 09h
    MOV DX, msg_mask
    INT 21h

; El programa espera ~3 segundos con el timer del BIOS (INT 1Ah)
    MOV AH, 00h
    INT 1Ah                     ; ticks actuales en CX:DX
    MOV BX, DX                  ; BX = ticks de inicio
.wait:
    MOV AH, 00h
    INT 1Ah
    SUB DX, BX                  ; DX = ticks transcurridos (resta modular)
    CMP DX, WAIT_TICKS
    JB .wait                    ; repite mientras no pasen 55 ticks

; Se restaura el IMR original
    POP AX
    OUT PIC_IMR, AL

    MOV AH, 09h
    MOV DX, msg_unmask
    INT 21h

    MOV AH, 4Ch
    INT 21h

msg_mask   DB "IRQ1 enmascarado (teclado deshabilitado). $"
msg_unmask DB 0Dh, 0Ah, "IRQ1 restaurado.$"
