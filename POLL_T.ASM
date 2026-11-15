; POLL_T.ASM - Polling con timeout para el puerto de teclado
; Compila (reintentos por defecto): nasm -f bin POLL_T.ASM -o POLL_T.COM
; Compila (forzar timeout):         nasm -f bin POLL_T.ASM -o POLL_T.COM -DMAX_RETRY=5

[BITS 16]
[ORG 0x100]

%ifndef MAX_RETRY
%define MAX_RETRY 0FFFFh        ; numero maximo de reintentos por defecto
%endif

PORT_DATA   EQU 60h
PORT_STATUS EQU 64h
OBF_MASK    EQU 01h

start:
    CLI                         ; el BIOS (INT 09h) no debe consumir el scancode durante el polling
    MOV CX, MAX_RETRY           ; el contador de reintentos acota la espera
.poll:
    IN AL, PORT_STATUS
    TEST AL, OBF_MASK
    JNZ .dato_listo
    LOOP .poll                  ; decrementa CX y salta si CX es distinto de 0

; Timeout: CX llego a 0 sin que el dispositivo respondiera
    STI
    MOV AH, 09h
    MOV DX, msg_timeout
    INT 21h
    JMP .fin

.dato_listo:
    IN AL, PORT_DATA
    STI
    MOV AH, 02h
    MOV DL, AL
    INT 21h                     ; muestra el byte leido (impresion directa)

.fin:
    MOV AH, 4Ch
    INT 21h

msg_timeout DB 'Timeout: sin respuesta del dispositivo$'
