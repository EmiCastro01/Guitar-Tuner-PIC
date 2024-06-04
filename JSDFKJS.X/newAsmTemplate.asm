LIST P = 16F887  
#include "p16f887.inc"

    __CONFIG _CONFIG1, _FOSC_EXTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF


    ORG 0x00
    GOTO INICIO

    ORG 0X04
    GOTO INTER

INICIO
    
    BANKSEL TRISB
    MOVLW   0x01        ; RB0 como entrada
    MOVWF   TRISB

    BANKSEL TRISC
    CLRF    TRISC       ; PORTC como salida

    

    BANKSEL OPTION_REG
    CLRF OPTION_REG
    BSF	OPTION_REG, 6
    
    BANKSEL WPUB
    CLRF    WPUB
    BSF	WPUB,0

    BANKSEL PORTC
    MOVLW   0xAA        ; Inicializar PORTC con 0xAA
    MOVWF   PORTC

    BANKSEL INTCON
    MOVLW   B'10010000' ; Habilitar interrupciones globales e interrupciones por cambio en el puerto B
    MOVWF   INTCON
    GOTO LOOP

LOOP
    NOP
    BSF	PORTC, 7
    GOTO LOOP

INTER
    
    CLRF PORTC
    RETFIE
    
    
    
    
    
    
    END


