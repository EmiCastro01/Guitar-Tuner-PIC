LIST P=16F887  
#include "p16f887.inc"

    __CONFIG _CONFIG1, _FOSC_EXTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF
    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
    
    
    ;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< DEFINICIOINES >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ;-------------------------------------------------------------------------------------------
    CONTA_Z EQU 0X24	    ;CONTADOR DE CRUCES POR CERO (SIEMPRE VALE 2: LEER CHECK_ZERO_CROSS)
    FREQ_L EQU 0x22	    ;CONTADOR DE LECTURA DE LA FRECUENCIA (NIBBLE INFERIOR)
    CONTA  EQU 0x21	    ;CONTADOR AUXILIAR PARA EL CONTEO DE 1 SEGUNDO DEL TMR1
    AUX    EQU 0x20	    ;AUXILIAR PARA CADA CASO    
    FREQ_H EQU 0x23	    ;CONTADOR DE LECTURA DE LA FRECUENCIA (NIBBLE SUPERIOR)
    FREQ_L_TO_COMPARE EQU	0X25	;CONTADOR DE ESCRITURA DE LA FRECUENCIA (NIBBLE INFERIOR)	
    FREQ_H_TO_COMPARE EQU	0X26	;CONTADOR DE ESCRITURA DE LA FRECUENCIA (NIBBLE SUPERIOR)
    TUNING_STR_L EQU 0X50
    TUNING_STR_H EQU 0X51	    ;FREQ SELECCIONADA PARA SER AFINADA
    DIF_FREQ_L	EQU 0x52    
    DIF_FREQ_H EQU 0x53		    ;DIFERENCIA DE AFINACIONES ENTRE COMPARE Y TUNING	
	

    ;-------------->>>>>> FRECUENCIAS GUITARRA <H:L> <<<<<------------------------------
    CBLOCK 0X27		
    
    E1_STR_L	   
    E1_STR_H	    ;CUERDA 1: MI - 330Hz 
    B_STR_L	    
    B_STR_H	    ;CUERDA 2: SI - 246Hz
    G_STR_L	    
    G_STR_H	    ;CUERDA 3: SOL - 196H
    D_STR_L	   
    D_STR_H	    ;CUERDA 4: RE - 146Hz
    A_STR_L	   
    A_STR_H	    ;CUERDA 5: LA - 110Hz
    E2_STR_L	    
    E2_STR_H	    ;CUERDA 6: MI - 82Hz
    ENDC
    ;------------------------------------------------------------------------------
    ;------------------------------------------------------------------------------------
    
    ORG 0x00
    GOTO INICIO

    ORG 0x04
    GOTO INT
    
INICIO
    ;CARGA DE VALORES EN CUERDAS DE GUITARRA	valores estaticos y finales!!<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    BANKSEL PORTB
    MOVLW   0x4A
    MOVWF   E1_STR_L
    MOVLW   0x01
    MOVWF   E1_STR_H
    MOVLW   0xF6
    MOVWF   B_STR_L
    MOVLW   0x00
    MOVWF   B_STR_H
    MOVLW   0xC4
    MOVWF   G_STR_L
    MOVLW   0x00
    MOVWF   G_STR_H
    MOVLW   0x92
    MOVWF   D_STR_L
    MOVLW   0x00
    MOVWF   D_STR_H
    MOVLW   0x6E
    MOVWF   A_STR_L
    MOVLW   0x00
    MOVWF   A_STR_H
    MOVLW   0x52
    MOVWF   E2_STR_L
    MOVLW   0x00
    MOVWF   E2_STR_L
    
    ;pRUEBAS
    
    MOVF    E1_STR_L, 0
    MOVWF   TUNING_STR_L
    MOVF    E1_STR_H, 0
    MOVWF   TUNING_STR_H
    
    ;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    
     ;COMPARADOR ANALOGICO (CRUCES POR 0)<<<<<<<<<<<<<<<<<<<<<<<<<<<
    BANKSEL TRISA
    BSF	TRISA, 0
    BSF	TRISA, 3
    BANKSEL ANSEL
    BSF	ANSEL, 3
    BANKSEL CM1CON0
    BSF	CM1CON0, 7
     BANKSEL PIE2
    MOVLW   B'00100000'
    MOVWF   PIE2
    ; --------------------------------------------
    ; -----------------------------------------------
    BANKSEL PORTA
    MOVLW   0X02
    MOVWF   CONTA_Z		
    CLRF FREQ_L
    CLRF FREQ_H
    CLRF FREQ_L_TO_COMPARE
    CLRF FREQ_H_TO_COMPARE
    MOVLW .16
    MOVWF CONTA
    CLRF AUX
    BANKSEL TRISB
    CLRF TRISB
    CLRF TRISD
    BANKSEL PORTB
    CLRF PORTB
    CLRF PORTD
  
  ; TMR1 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    BANKSEL TMR1H
    MOVLW 0x0B
    MOVWF TMR1H
    MOVLW 0xDC
    MOVWF TMR1L
    
    BANKSEL T1CON
    MOVLW b'00010001' 
    MOVWF T1CON
    
    BANKSEL PIE1
    BSF PIE1, TMR1IE 
    ;-------------------------------------------------------
    
    MOVLW b'11100000'
    MOVWF INTCON 
    
    GOTO MAIN
;<<<<<<<<<<<<<<<<<<<<<<<<<<MAIN>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

        ;;;;CORREGIRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR

MAIN
   
    CALL COMPARE_STRINGS
   
    
	
    
   

    GOTO MAIN

    ;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

     ;<<<<<<<<<<<<<<<<<<<<EXPLICACION: COMPARE_STRINGS >>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ;------- Cuando el TMR1 cumple un segundo (teniendo tambien en cuenta
   
    ;---------------------------------------------------------------------------
PRENDER
    BSF	PORTB,0
    GOTO END_C_S

    
COMPARE_STRINGS
    BANKSEL PORTB
    MOVF    FREQ_L_TO_COMPARE, W
    SUBWF   TUNING_STR_L, W
    BTFSC   STATUS, Z
    GOTO PRENDER
    BCF	PORTB,0
    GOTO END_C_S
END_C_S
    RETURN
    ;;;;CORREGIRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
    
    
    ;<<<<<<<<<<<<<<<<<<<<EXPLICACION: FREQ_CATCHED >>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ;------- Cuando el TMR1 cumple un segundo (teniendo tambien en cuenta
    ; el contador (CONTA), se toma la frecuencia medida en los registros
    ; <FREQ_H : FREQ_L> y se escriben en sus respectivos <x_TO_COMPARE>
    ;para ser escritos en los puertos o ser manejados en el main. Luego se
    ;borra el contenido de <FREQ_H : FREQ_L> para tomar muestras nuevamente en
    ;un nuevo recuento del TMR1
    ;---------------------------------------------------------------------------
FREQ_CATCHED	
   
	    
    BANKSEL TMR1H
    MOVLW 0x0B
    MOVWF TMR1H
    MOVLW 0xDC
    MOVWF TMR1L
    
    BANKSEL PORTA
    DECFSZ CONTA
    RETURN
    
    BANKSEL PORTB
    MOVF    FREQ_L, 0
    MOVWF FREQ_L_TO_COMPARE
    CLRF    FREQ_L
    MOVF    FREQ_H, 0
    MOVWF   FREQ_H_TO_COMPARE
    CLRF    FREQ_H
    MOVLW .16
    MOVWF CONTA
    
    RETURN

     ;<<<<<<<<<<<<<<<<<<<<EXPLICACION: INC_FREQ >>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ;------- incrementa el par <FREQ_H : FREQ_L>.
    ;---------------------------------------------------------------------------
INC_FREQ
    BANKSEL PORTB
    INCF    FREQ_L, F
    BTFSS   STATUS, Z	;DESBORDAMIENTO DEL FREQ_L
    RETURN
    INCF    FREQ_H, F
    CLRF    FREQ_L
    RETURN
    
    
     ;<<<<<<<<<<<<<<<<<<<<EXPLICACION: CHECK_ZERO_CROSS >>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ;------- La rutina de interrupciones manda a este lugar cuando el comparador
    ;detectó un cruce por cero. Como en un periodo de 
    ; la onda senoidal existen dos cruces por cero,
    ;es necesario contar un unico cruce "cada dos cruces reales" para obtener
    ;una señal cuadrada de la misma frecuencia que la senoidal.
    ;---------------------------------------------------------------------------
CHECK_ZERO_CROSS
    
    BANKSEL PIR2
    BTFSS PIR2, 5
    RETFIE
    BANKSEL PORTA
    DECFSZ CONTA_Z
    GOTO END_INT_ZERO_CROSS
    BANKSEL PORTB
    MOVLW   0x02
    MOVWF   CONTA_Z
    CALL INC_FREQ
    GOTO END_INT_ZERO_CROSS
    
        ;<<<<<<<<<<<<<<<<<<<<EXPLICACION: END_INT_ZERO_CROSS >>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ;------- Fin comun para los casos del cruce por cero. Retorna de interrupcion
    ;---------------------------------------------------------------------------
END_INT_ZERO_CROSS
    BANKSEL PIR2
    BCF PIR2, 5
    RETFIE
    
INT
    
    BANKSEL PIR1
    BTFSS PIR1, TMR1IF
    GOTO CHECK_ZERO_CROSS
    CALL FREQ_CATCHED
    BANKSEL PIR1
    BCF PIR1, TMR1IF
    RETFIE 
    

END