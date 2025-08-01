LIST P=16F887 
#include "p16f887.inc"

__CONFIG _CONFIG1, _FOSC_EXTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF
__CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
    
DATA_TX	   EQU 0X21
	   
ORG 0x00
GOTO INICIO
ORG 0x04
GOTO INT

INICIO

;Config baud rate 9600bps para Fosc = 4MHz
    BANKSEL SPBRG	
    MOVLW   D'25'		
    MOVWF   SPBRG
    
    BANKSEL BAUDCTL
    BCF     BAUDCTL, BRG16
    
;Config TXSTA SYNC=0, TXEN=1, BRGH=1 
    BANKSEL TXSTA
    MOVLW   b'00100100'
    MOVWF   TXSTA
    
;Config puerto Tx y puertos para mostrar dato enviado
    BANKSEL RCSTA	
    MOVLW   B'10000000'
    MOVWF   RCSTA
    
    BANKSEL TRISB
    CLRF    TRISB
    CLRF    TRISD
    MOVLW   b'1000000'
    MOVWF   TRISC
    
    BANKSEL PORTB
    CLRF    PORTB
    CLRF    PORTD
    
;Config interrupcion por TMR0 
    BANKSEL OPTION_REG
    MOVLW   b'10000111'
    MOVWF   OPTION_REG
    
;Config interrupcion por TMR0 Y global
    BSF     INTCON, GIE
    BSF     INTCON, T0IE
    
;Cargamos TMR0 para que interrumpa cada 65ms
    BANKSEL TMR0
    MOVLW   0x01
    MOVWF   TMR0    
    GOTO    MAIN
    
MAIN          
    BANKSEL PORTB
    MOVLW   0x41 
    MOVWF   DATA_TX
    GOTO    MAIN
   
INT
   BTFSS    INTCON, 2 ; test si la int fue por TMR0
   RETFIE             ; si no int por TMR0 retfie
   GOTO	    SEND      ; si pasaron los 65 ms, cargo dato en el buffer y lo envio
   
END_INT
   BANKSEL  PORTD
   BSF	    PORTD, 1  ; prendo led si se envio el dato
   BCF	    INTCON, 2 ; limpiamos flag de int
   BANKSEL  TMR0      ; cargamos nuevamente el timer
   MOVLW    0x01
   MOVWF    TMR0
   RETFIE 
   
SEND
   BANKSEL  PIR1       
   BTFSS    PIR1,TXIF  ; verifico si el buffer tx esta vacio
   GOTO	    SEND       ; si TXIF=0 entonces TXREG esta ocupado, asi que espero a que se desocupe
   MOVF	    DATA_TX, W ; si esta vacio el buffer, cargo un valor para enviar y retorno
   MOVWF    TXREG
   MOVF	    TXREG,W    ; cargo en portb el valor que se envia 
   MOVWF    PORTB
   GOTO	    END_INT
END