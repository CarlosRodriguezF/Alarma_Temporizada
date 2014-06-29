;Alarma para despertar, a intervalos de un minuto

;===============================================================================
;Configuramos el procesador
    list p=16F873A          ;Definimos el tipo de procesador
    include "P16F873A.inc"  ;Incluimos la libreria
; CONFIG
; __config 0xFF31
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_ON & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF
;===============================================================================
;MACROS
;Macro para situarnos en el banco de memoria 0
BNK_0 macro
    bcf STATUS,5
    endm
;Macro para situarnos en el banco de memoria 1
BNK_1 macro
    bsf STATUS,5
    endm
;Macro para guardar status y registro de trabajo
PUSH macro
    movwf salv_w
    swapf salv_w,F  ;Hacemos un swap para no modificar F
    swapf STATUS,W  ;Hacemos swap y guardamos en W
    movwf salv_s    ;Guardamos
    endm
;Macro para cargar status y registro de trabajo
POP macro
    swapf salv_s,W
    movwf STATUS
    swapf salv_w,W
    endm

;===============================================================================
;Variables
salv_w equ 0x20
salv_s equ 0x21
display equ 0x22
unidades equ 0x23
decenas equ 0x24
pulsador1 equ 0x26
antirebote1 equ 0x25

;===============================================================================
    org 0x00    ;Vector de reset
    goto    Start

    org 0x04    ;Interrupcion
    goto    Display

;===============================================================================
;Tabla para mostrar los valores en los displays

TABLA       addwf   PCL,1       ;Busca posicion del digito en la tabla
            retlw   b'11000000' ;Digito 0
            retlw   b'11110110' ;Digito 1
            retlw   b'10100001' ;Digito 2
            retlw   b'10100100' ;Digito 3
            retlw   b'10010110' ;Digito 4
            retlw   b'10001100' ;Digito 5
            retlw   b'10011000' ;Digito 6
            retlw   b'11100110' ;Digito 7
            retlw   b'10000000' ;Digito 8
            retlw   b'10000110' ;Digito 9

;===============================================================================
;Rutina de multiplexacion de display
Display PUSH
        bcf INTCON,2    ;Limpiamos flag de interrupcion
        movlw   0xD8    ;Recargamos el timer0
        movwf   TMR0
        movf    display,0
        xorlw   0x00
        btfsc   STATUS,Z    ;Si display es 0, actualizamos el primero
        call    print0
        movf    display,0
        xorlw   0x01
        btfsc   STATUS,Z    ;Si display es 1, actualizamos el segundo
        call    print1
        movlw   0x01        ;Alternamos el display
        xorwf   display,F
        movf    pulsador1,0
        xorlw   0x01
        btfsc   STATUS,Z
        incf    antirebote1
        bcf     STATUS,Z
        movf    antirebote1,0
        xorlw   0x20
        btfsc   STATUS,Z
        call    configu
        POP
        retfie
;===============================================================================
;Impresion en el primer display (Decenas)
print0  movf    decenas,0
        call    TABLA
        bsf     PORTA,0
        bcf     PORTA,1
        movwf   PORTB
        bcf     STATUS,Z
        return
;Impresion en el segundo display (Unidades)
print1  movf    unidades,0
        call    TABLA
        bsf     PORTA,1
        bcf     PORTA,0
        movwf   PORTB
        bcf     STATUS,Z
        return
;===============================================================================
;Configuracion del tiempo a contar
incdec  bcf     STATUS,Z
        incf    decenas
        clrf    unidades
        movf    decenas,W
        xorlw   0x06
        btfsc   STATUS,Z
        clrf    decenas
        return

configu clrf    antirebote1
        bcf     pulsador1,0
        movf    PORTA,0
        andlw   b'00001000'
        btfsc   STATUS,Z
        return
        bcf     STATUS,Z
        incf    unidades
        movf    unidades,0
        xorlw   0x0A
        btfsc   STATUS,Z
        call    incdec
        return
;===============================================================================
Start
    BNK_0
    clrf    PORTB           ;Puertos A y B inicialmente a 0
    clrf    PORTA
    BNK_1
    movlw   b'10000111'     ;Prescaler de 256 asignado a timer0
    movwf   OPTION_REG
    movlw   b'00000110'     ;Configuramos puerto A como digitales
    movwf   ADCON1
    clrf    TRISB
    movlw   b'00011000'     ;Puerto A tres salidas dos entradas (Interruptores)
    movwf   TRISA
    BNK_0
    movlw   b'10100000'
    movwf   INTCON
    movlw   0xD8            ;Cargamos el timmer para tener 10ms
    movwf   TMR0
    clrf    display
    clrf    unidades
    clrf    decenas
    movlw   0x01
    movwf   unidades

Loop
    movf    PORTA,0
    andlw   b'00001000'
    btfss   STATUS,Z
    bsf     pulsador1,0
    bcf     STATUS,Z
    goto Loop
    end