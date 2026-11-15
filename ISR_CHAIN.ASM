; ISR_CHAIN.ASM - ISR para IRQ1 con encadenamiento al handler original
; Compila: nasm -f bin ISR_CHAIN.ASM -o ISR_CHAIN.COM

[BITS 16]
[ORG 0x100]

section .data
contador DW 0                   ; teclas contadas por el ISR propio
MAX_KEYS EQU 5
old_isr  DD 0                   ; SEG:OFF del handler original de INT 09h
msg_ini  DB "Escriba 5 teclas (el eco de DOS debe seguir funcionando): $"
msg_cont DB 0Dh, 0Ah, "Teclas contadas por ISR_CHAIN: $"
msg_fin  DB 0Dh, 0Ah, "ISR_CHAIN restaurado. Fin del programa.$"

section .text
start:
; El programa guarda el vector original de INT 09h
    MOV AX, 3509h
    INT 21h
    MOV [old_isr], BX
    MOV [old_isr+2], ES

; El programa instala el ISR con encadenamiento
    PUSH DS
    MOV AX, CS
    MOV DS, AX
    MOV DX, mi_isr_chain
    MOV AX, 2509h
    INT 21h
    POP DS
    STI

    MOV AH, 09h
    MOV DX, msg_ini
    INT 21h

; Lectura con eco por DOS: solo funciona si el handler original recibe la tecla
.leer:
    MOV AH, 01h
    INT 21h
    CMP WORD [contador], MAX_KEYS
    JL .leer

; El programa restaura el handler original (DS se conserva con PUSH/POP)
    CLI
    PUSH DS
    LDS DX, [old_isr]
    MOV AX, 2509h
    INT 21h
    POP DS
    STI

    MOV AH, 09h
    MOV DX, msg_cont
    INT 21h
    MOV AX, [contador]
    CALL imprimir_decimal

    MOV AH, 09h
    MOV DX, msg_fin
    INT 21h
    MOV AH, 4Ch
    INT 21h

; ---- ISR con encadenamiento ---------------------------------------
; El handler original (BIOS) envia el EOI, por eso este ISR no lo envia.
mi_isr_chain:
    PUSH AX
    IN AL, 60h                  ; lee el scancode sin alterarlo (el BIOS lo relee)
    TEST AL, 80h                ; break code: no se cuenta
    JNZ .encadenar
    INC WORD [CS:contador]      ; codigo propio: cuenta la pulsacion
.encadenar:
    POP AX
    PUSHF                       ; simula INT: flags + far call al handler original
    CALL FAR [CS:old_isr]
    IRET

; ---- Subrutina: imprime AX en decimal (sin signo) -----------------
imprimir_decimal:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV BX, 10
    XOR CX, CX
.divide:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    TEST AX, AX
    JNZ .divide
.imprimir:
    POP DX
    ADD DL, 30h
    MOV AH, 02h
    INT 21h
    LOOP .imprimir
    POP DX
    POP CX
    POP BX
    POP AX
    RET
