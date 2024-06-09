LIST P=16F887  
#include "p16f887.inc"

    __CONFIG _CONFIG1, _FOSC_EXTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF
    __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
    
    
    ;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< DEFINICIOINES >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ;-------------------------------------------------------------------------------------------
    TIMER_Z_CROSS   EQU 0x40	    ;CONTADOR PARA HACER RETARDO
    STATUS_CONTEXT  EQU 0X41	    ;PARA CONTEXTO (STATUS)
    W_CONTEXT	    EQU	0X42	    ; PARA CONTEXTO (W)
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
    TUNING_STATUS_REGISTER  EQU 0X54	    ;REGISTRO DEL ESTADO DE LA ACTUAL AFINACION	
					    ;[-,-,H_IS_TUNED,L_IS_TUNED,H_SUB_IS_NEGATIVE,L_SUB_IS_NEGATIVE,IS_HIGHER/LOWER,IS_TUNED]
					    ;[0] IS_TUNED: 0 para desafinada, 1 para afinada (ambas freq iguales)
					    ;[1] IS_HIGHER/LOWER: 1 para higher, 0 para lower. Se refiere a la frecuencia captada por mic
					    ;[2] L_SUB_IS_NEGATIVE: 1 si la resta  TUNING_STR_L - FREQ_L_TO_COMPARE es < 0. 0 si no
					    ;[3] H_SUB_IS_NEGATIVE: idem pero con nibble superior
					    ;[4] L_IS_TUNED: 1 Si la resta de TUNING_STR_L - FREQ_L_TO_COMPARE = 0
					    ;[5] H_IS_TUNED: 1 Si la resta de TUNING_STR_H - FREQ_H_TO_COMPARE = 0
    BUFFER_TO_TX	EQU 0X55		    ;[IS_HIGHER/LOWER, data<6:0>]
					    ;Buffer del byte comprimido para transmitir o mostrar. 
					    ;[7] IS_HIGHER/LOWER: 0 si frec medida < frec real. 1 al reves
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
    MOVWF   E2_STR_H
    
   
    
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
  
  ; RETARDO <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    BANKSEL PORTB
    MOVLW   .255
    MOVWF   TIMER_Z_CROSS
    
   ;SELECTOR DE CUERDAS EN PUERTO C
    BANKSEL TRISC
    MOVLW   0XFF
    MOVWF   TRISC
    
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
;MAIN MAIN MAIN MAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAIN
;MAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAIN

MAIN
    
   CALL	STRING_SELECTION
   CALL	GET_DEVIATION
   CALL COMPRESS_TO_1_BYTE		    ;PIERDE DEFINICIO PERO GANA VELOCIDAD Y SIMPLIFICA EL CODIGO
   CALL SEND_TX
   CALL	SHOW_RES
   GOTO MAIN


;FIN MAIN FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    
   ;FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    
   
  
;-----------------------------	STRING_ELECTION--------------------------------->>>>>>>>>>>>>>>>>>>>>>>
   ;ACA HACER LA LOGICA PARA SELECCIONAR LA CUERDA A AFINAR
STRING_SELECTION
   BANKSEL PORTC
   BTFSC    PORTC, 0
   GOTO	    SELECT_E1
   BTFSC    PORTC,1
   GOTO SELECT_B
   BTFSC    PORTC,2
   GOTO SELECT_G
   BTFSC    PORTC, 3
   GOTO SELECT_D
   BTFSC    PORTC, 4
   GOTO SELECT_A
   BTFSC    PORTC, 6
   GOTO SELECT_E2
   GOTO END_SELECTION

SELECT_E1
    MOVF    E1_STR_L, 0
    MOVWF   TUNING_STR_L
    MOVF    E1_STR_H, 0
    MOVWF   TUNING_STR_H
    GOTO END_SELECTION
   
SELECT_B
    MOVF    B_STR_L, 0
    MOVWF   TUNING_STR_L
    MOVF    B_STR_H, 0
    MOVWF   TUNING_STR_H
    GOTO END_SELECTION
   
SELECT_G
    MOVF    G_STR_L, 0
    MOVWF   TUNING_STR_L
    MOVF    G_STR_H, 0
    MOVWF   TUNING_STR_H   
    GOTO END_SELECTION
   
SELECT_D
    MOVF    D_STR_L, 0
    MOVWF   TUNING_STR_L
    MOVF    D_STR_H, 0
    MOVWF   TUNING_STR_H
    GOTO END_SELECTION
    
SELECT_A
    MOVF    A_STR_L, 0
    MOVWF   TUNING_STR_L
    MOVF    A_STR_H, 0
    MOVWF   TUNING_STR_H
    GOTO END_SELECTION
    
SELECT_E2
    MOVF    E2_STR_L, 0
    MOVWF   TUNING_STR_L
    MOVF    E2_STR_H, 0
    MOVWF   TUNING_STR_H
    GOTO END_SELECTION
    
END_SELECTION   
   RETURN
   
; _---------------------------------------------------------------------------------------------------------------
   
   
; ----------------------<<<< EXPLICACION: GET DEVIATION >>>>>>>-------------------------------------->
   ;------- Globalmente hace la resta de 16 bits de [TUNING_STR_x - FREQ_x_TO_COMPARE] y guarda el resultado
    ;------------------------------en DIF_FREQ_x. Ademas, devuelve en los regitros el valor absoluto
    ; de la desviacion de afinacion entre la frecuencia real y la medida.
    ;Existen tres posibles situaciones que se manejan con el TUNING_STATUS_REGISTER para las restas
;-------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

GET_DEVIATION
    CLRF AUX
    CLRF TUNING_STATUS_REGISTER
    MOVF FREQ_L_TO_COMPARE, 0
    SUBWF TUNING_STR_L, 0
    BTFSC STATUS, Z
    BSF TUNING_STATUS_REGISTER, 4
    BTFSS STATUS, C
    BSF TUNING_STATUS_REGISTER, 2
    MOVWF DIF_FREQ_L

    
    BTFSC TUNING_STATUS_REGISTER, 2
    GOTO NEGATIVE_L

POSITIVE_L
    MOVF DIF_FREQ_L, 0
    GOTO COMPARE_HIGH

NEGATIVE_L
   
    COMF DIF_FREQ_L, F
    INCF DIF_FREQ_L, F

COMPARE_HIGH
    MOVF FREQ_H_TO_COMPARE, 0
    SUBWF TUNING_STR_H, 0
    BTFSC STATUS, Z
    BSF TUNING_STATUS_REGISTER, 5
    BTFSS STATUS, C
    BSF TUNING_STATUS_REGISTER, 3
    MOVWF DIF_FREQ_H

    BTFSC TUNING_STATUS_REGISTER, 3
    GOTO NEGATIVE_H

POSITIVE_H
    MOVF DIF_FREQ_H, 0
    GOTO CHECK_RESULT

NEGATIVE_H
  
    COMF DIF_FREQ_H, F
    INCF DIF_FREQ_H, F

CHECK_RESULT
    
    BTFSC TUNING_STATUS_REGISTER, 4
    BTFSC TUNING_STATUS_REGISTER, 5
    BSF TUNING_STATUS_REGISTER, 0

    BTFSC TUNING_STATUS_REGISTER, 3 
    BSF TUNING_STATUS_REGISTER, 1   
    BTFSC TUNING_STATUS_REGISTER, 2 
    CALL CHECK_L
    RETURN
CHECK_L
    BTFSC   TUNING_STATUS_REGISTER, 5
    BSF	TUNING_STATUS_REGISTER, 1
    RETURN
;-------------------------------------------FIN ETAPA COMPARACION--------------------------------------------------------
     
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<EXPLICACION COMPRESS_TO_ONE_BYTE><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ;------------- Utiliza solo el nibble inferior del calculo de la desviacion de frecuencias. Con esto se pierde rango
    ; de precision, pero se estima que la cuerda a afinar no necesita una precision exageradamente grande.
    ;	En 1 byte (buffer) se comprimen los valores del DIF_FREQ_x en 7 bits (menos significativos), y el octavo bit
    ; indica si la desviacion es hacia la derecha o izquierda.
COMPRESS_TO_1_BYTE
   CLRF	BUFFER_TO_TX		    ;LIMPIAR EL BUFFER
   MOVF	DIF_FREQ_L, 0		    ; SOLO MANDAMOS LA PARTE BAJA DE LA DESVIACION
   MOVWF BUFFER_TO_TX		    
   BTFSC    TUNING_STATUS_REGISTER, 1	    ;1 SI HIGHER
   BSF	BUFFER_TO_TX, 7
   RETURN   

 ;---------------------------------SEND_TX<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 ;Subrutina de transmision serie. Carga el buffer en TXREG (BUFFER_TO_TX)
 
SEND_TX
    NOP
   RETURN
   
;---------------------------------------------------------------------------------------------------
;-----------------------------SHOW RES->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
 ; muestra resultados en puertos y logs
SHOW_RES
BANKSEL PORTB
   MOVF BUFFER_TO_TX, 0
   MOVWF    PORTB
   RETURN 
  
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
    

    ;----------->>>>>>>> RUTINA DE INTERRUPCIONES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
INT
    ; Guardo contexto
    MOVWF W_CONTEXT     
    SWAPF STATUS, W  
    CLRF STATUS_CONTEXT  
    MOVWF STATUS_CONTEXT

    BANKSEL PIR1
    BTFSS PIR1, TMR1IF
    GOTO CHECK_ZERO_CROSS
    CALL FREQ_CATCHED
    BANKSEL PIR1
    BCF PIR1, 0

    ; pusheo contexto
    SWAPF STATUS_CONTEXT, W 
    MOVWF STATUS         
    SWAPF W_CONTEXT, F      
    SWAPF W_CONTEXT, W      
    RETFIE
    
;------------------------------------------------------------------------------------------->
END