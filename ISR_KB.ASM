; ISR_KB.ASM - ISR personalizado para IRQ1 (teclado)
; Compila: nasm -f bin ISR_KB.ASM -o ISR_KB.COM

[BITS 16]
[ORG 0x100]

section .data
contador DW 0                   ; numero de teclas atendidas
MAX_KEYS EQU 5
old_isr  DD 0                   ; almacena SEG:OFF del handler original
msg_tecla DB 0Dh, 0Ah, "Tecla detectada por ISR propio$"
msg_fin   DB 0Dh, 0Ah, "ISR restaurado. Fin del programa.$"

section .text
start:
; El programa guarda el vector original de INT 09h
    MOV AX, 3509h               ; AH=35h: obtener vector INT 09h
    INT 21h                     ; ES:BX = direccion del handler actual
    MOV [old_isr], BX
    MOV [old_isr+2], ES

; El programa instala el ISR propio
    PUSH DS
    MOV AX, CS
    MOV DS, AX
    MOV DX, mi_isr              ; DS:DX = direccion del nuevo handler
    MOV AX, 2509h               ; AH=25h: fijar vector INT 09h
    INT 21h
    POP DS
    STI                         ; asegura interrupciones habilitadas

.esperar:
    MOV AX, [contador]
    CMP AX, MAX_KEYS
    JL .esperar                 ; bucle activo hasta 5 pulsaciones

; El programa restaura el handler original (DS se conserva con PUSH/POP)
    CLI
    PUSH DS
    LDS DX, [old_isr]           ; DS:DX = handler original
    MOV AX, 2509h
    INT 21h
    POP DS                      ; DS vuelve a apuntar a los datos del programa
    STI

    MOV AH, 09h
    MOV DX, msg_fin
    INT 21h
    MOV AH, 4Ch
    INT 21h

; ---- ISR propio ----------------------------------------------------
mi_isr:
    PUSH AX
    PUSH DX
    PUSH DS
    MOV AX, CS
    MOV DS, AX                  ; DS apunta al segmento del programa

    IN AL, 60h                  ; lee el scancode y libera el buffer del 8042
    TEST AL, 80h                ; si es un break code (tecla soltada)
    JNZ .fin_isr                ; no se cuenta como pulsacion

    MOV AH, 09h
    MOV DX, msg_tecla
    INT 21h
    INC WORD [contador]

.fin_isr:
    MOV AL, 20h                 ; EOI al PIC maestro, antes del IRET
    OUT 20h, AL

    POP DS
    POP DX
    POP AX
    IRET
