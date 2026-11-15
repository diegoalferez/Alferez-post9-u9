; LPT_1.ASM - Envio de un caracter al puerto paralelo LPT1
; Compila: nasm -f bin LPT_1.ASM -o LPT_1.COM

[BITS 16]
[ORG 0x100]

DATA_PORT   EQU 0378h           ; Data Register
STATUS_PORT EQU 0379h           ; Status Register
CTRL_PORT   EQU 037Ah           ; Control Register
BUSY_MASK   EQU 80h             ; bit 7 del estado: BUSY#
STROBE_MASK EQU 01h             ; bit 0 del control: STROBE

; Los puertos mayores a 0FFh solo se direccionan con DX (IN/OUT con DX)
start:
; Se espera BUSY#=1 (impresora lista)
    MOV DX, STATUS_PORT
.wait_ready:
    IN AL, DX
    TEST AL, BUSY_MASK
    JZ .wait_ready

; Se envia el caracter "A" (41h)
    MOV DX, DATA_PORT
    MOV AL, 41h
    OUT DX, AL                  ; coloca el dato en las lineas D0-D7

; Pulso STROBE (bit 0 del control, activo en bajo segun el laboratorio)
    MOV DX, CTRL_PORT
    IN AL, DX
    AND AL, ~STROBE_MASK        ; STROBE=0 -> activo
    OUT DX, AL

; Retardo minimo (~1 us en DOSBox)
    MOV CX, 0Fh
.delay:
    LOOP .delay

    OR AL, STROBE_MASK          ; STROBE=1 -> inactivo
    OUT DX, AL

    MOV AH, 09h
    MOV DX, msg_ok
    INT 21h

    MOV AH, 4Ch
    INT 21h

msg_ok DB "Caracter 'A' enviado a LPT1 (0378h) sin bloqueo.", 0Dh, 0Ah, "$"
