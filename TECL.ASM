; TECL.ASM - Lectura del scancode del teclado 8042 por polling
; Compila: nasm -f bin TECL.ASM -o TECL.COM

[BITS 16]
[ORG 0x100]                     ; programa .COM, CS=DS=ES=SS

PORT_DATA   EQU 60h             ; Data Port del 8042 (scancode)
PORT_STATUS EQU 64h             ; Status Register del 8042
OBF_MASK    EQU 01h             ; bit 0: Output Buffer Full
BREAK_MASK  EQU 80h             ; bit 7 del scancode: tecla soltada (break)

start:
; CLI: sin interrupciones, el BIOS (INT 09h) no consume el scancode antes del polling
    CLI
; El programa espera, sin limite, a que OBF=1 (dato disponible)
.poll:
    IN AL, PORT_STATUS          ; lee el registro de estado del 8042
    TEST AL, OBF_MASK           ; comprueba el bit OBF
    JZ .poll                    ; si OBF=0 no hay dato listo, repite
    IN AL, PORT_DATA            ; lee el scancode del Data Port
    TEST AL, BREAK_MASK         ; si es un break code (tecla soltada)
    JNZ .poll                   ; se descarta y se sigue esperando el make code
    STI                         ; ya leido el make code, se rehabilitan las interrupciones
    MOV BL, AL                  ; guarda el scancode en BL

; El programa muestra el scancode en hexadecimal (conversion manual)
    MOV AH, 02h                 ; funcion DOS: imprimir caracter
    MOV DL, BL
    SHR DL, 4                   ; nibble alto
    ADD DL, 30h
    CMP DL, 3Ah
    JL .printH
    ADD DL, 07h                 ; ajuste para A-F
.printH:
    INT 21h
    MOV DL, BL
    AND DL, 0Fh                 ; nibble bajo
    ADD DL, 30h
    CMP DL, 3Ah
    JL .printL
    ADD DL, 07h
.printL:
    INT 21h
    MOV AH, 02h
    MOV DL, 0Dh                 ; CR
    INT 21h
    MOV DL, 0Ah                 ; LF
    INT 21h

    MOV AH, 4Ch
    INT 21h                     ; termina el programa
