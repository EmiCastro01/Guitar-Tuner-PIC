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
					    ;[7] IS_HIGHER/LOWER: 0 si frec medida < frec real. 1 al reVES
    BUFFER_MASK		EQU 0X57
    TUNING_OUTPUT	EQU 0X56		    ;VALOR QUE SEND_PORT MUESTRA EN EL PUERTO. OPERADO SOBRE EL BUFFER
    TUNER_STEP		EQU 0X58
    TUNER_STEP_2	EQU 0X59
    TUNER_STEP_3	EQU 0X5A		    ;VALORES DE PASO ENTRE ENCENDIDO DE LEDS	
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
;DEFINICIONES PARA TUNING_STATUS_REGISTER
#define	IS_TUNED 0
#define	IS_HIGHER_LOWER 1
#define	L_SUB_IS_NEGATIVE 2
#define	H_SUB_IS_NEGATIVE 3
#define	L_IS_TUNED 4
#define	H_IS_TUNED 5
    
;DEFINICIONES PARA TUNING_OUTPUT
#define NEG_TUNE_2_LED  0
#define	NEG_TUNE_1_LED  1
#define	NEG_TUNE_0_LED  2
#define	IN_TUNE_LED  3
#define POS_TUNE_0_LED  4
#define	POS_TUNE_1_LED  5
#define	POS_TUNE_2_LED	6

;DEFINICIONES DE VALORES PARA EL MUESTREO POR EL PORTB
#define SPREAD	.3		    ;si disminuyen aumentan presicion pero disminuyen rango
#define STEP	.25		    ;el spred es el rango de frecuencias para arriba y para abajo que toma como afinado, sin estar
				    ; ciertamente afinado
    
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
    
    ;ASIGNACION DE VALORES DE STEP
    MOVLW   STEP
    MOVWF   TUNER_STEP
    MOVLW   STEP
    ADDWF   TUNER_STEP, W
    MOVWF   TUNER_STEP_2
    MOVLW   STEP
    ADDWF   TUNER_STEP_2, W
    MOVWF   TUNER_STEP_3
    ;En esta asignacion genero un paso de lo que diga en la definicion de step para los tres leds.
    
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
    BANKSEL TRISD
    CLRF TRISD
    BANKSEL PORTB
  
  ; RETARDO <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    BANKSEL PORTB
    MOVLW   .255
    MOVWF   TIMER_Z_CROSS
    
   ;SELECTOR DE CUERDAS EN PUERTO B
    BANKSEL TRISB
    MOVLW   0XFF
    MOVWF   TRISB
    BANKSEL ANSELH
    CLRF ANSELH
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
    
    MOVLW b'11000000'
    MOVWF INTCON 
    
   
    
    GOTO MAIN
;MAIN MAIN MAIN MAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAIN
;MAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAINMAIN MAIN MAIN

MAIN
   CALL	STRING_SELECTION
   CALL	GET_DEVIATION
   CALL COMPRESS_TO_1_BYTE		   
   CALL SEND_TX
   CALL	SEND_PORT
   GOTO MAIN


;FIN MAIN FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    
   ;FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    FIN MAIN    
   
  
;-----------------------------	STRING_ELECTION--------------------------------->>>>>>>>>>>>>>>>>>>>>>>
   ;ACA HACER LA LOGICA PARA SELECCIONAR LA CUERDA A AFINAR
STRING_SELECTION
   BANKSEL PORTB
   BTFSC    PORTB, 0
   GOTO	    SELECT_E1
   BTFSC    PORTB,1
   GOTO SELECT_B
   BTFSC    PORTB,2
   GOTO SELECT_G
   BTFSC    PORTB, 3
   GOTO SELECT_D
   BTFSC    PORTB, 4
   GOTO SELECT_A
   BTFSC    PORTB, 6
   GOTO SELECT_E2
   GOTO END_SELECTION

SELECT_E1
    MOVF    E1_STR_L, W
    MOVWF   TUNING_STR_L
    MOVF    E1_STR_H, W
    MOVWF   TUNING_STR_H
    GOTO END_SELECTION
   
SELECT_B
    MOVF    B_STR_L, W
    MOVWF   TUNING_STR_L
    MOVF    B_STR_H, W
    MOVWF   TUNING_STR_H
    GOTO END_SELECTION
   
SELECT_G
    MOVF    G_STR_L, W
    MOVWF   TUNING_STR_L
    MOVF    G_STR_H, W
    MOVWF   TUNING_STR_H   
    GOTO END_SELECTION
   
SELECT_D
    MOVF    D_STR_L, W
    MOVWF   TUNING_STR_L
    MOVF    D_STR_H, W
    MOVWF   TUNING_STR_H
    GOTO END_SELECTION
    
SELECT_A
    MOVF    A_STR_L, W
    MOVWF   TUNING_STR_L
    MOVF    A_STR_H, W
    MOVWF   TUNING_STR_H
    GOTO END_SELECTION
    
SELECT_E2
    MOVF    E2_STR_L, W
    MOVWF   TUNING_STR_L
    MOVF    E2_STR_H, W
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
    MOVF FREQ_L_TO_COMPARE, W
    SUBWF TUNING_STR_L, W
    BTFSC STATUS, Z
    BSF TUNING_STATUS_REGISTER, L_IS_TUNED
    BTFSS STATUS, C
    BSF TUNING_STATUS_REGISTER, L_SUB_IS_NEGATIVE
    MOVWF DIF_FREQ_L
    
    BTFSC TUNING_STATUS_REGISTER, L_SUB_IS_NEGATIVE
    GOTO NEGATIVE_L
    GOTO COMPARE_HIGH

    

NEGATIVE_L
    BTFSC   TUNING_STR_H, 0
    GOTO COMPARE_HIGH
    MOVF   TUNING_STR_L, W
    SUBWF   FREQ_L_TO_COMPARE, W
    MOVWF   DIF_FREQ_L

COMPARE_HIGH
 
    MOVF FREQ_H_TO_COMPARE, W
    SUBWF TUNING_STR_H, W
    BTFSC STATUS, Z
    BSF TUNING_STATUS_REGISTER, H_IS_TUNED
    BTFSS STATUS, C
    BSF TUNING_STATUS_REGISTER, H_SUB_IS_NEGATIVE
    MOVWF DIF_FREQ_H 

    BTFSC TUNING_STATUS_REGISTER, H_SUB_IS_NEGATIVE
    GOTO NEGATIVE_H
    GOTO CHECK_RESULT

NEGATIVE_H
    COMF DIF_FREQ_H, F
    INCF DIF_FREQ_H, F
    COMF DIF_FREQ_L, F
    INCF DIF_FREQ_L, F

CHECK_RESULT
    BTFSC TUNING_STATUS_REGISTER, L_IS_TUNED
    CALL CHECK_H
    BTFSC TUNING_STATUS_REGISTER, H_SUB_IS_NEGATIVE 
    BSF TUNING_STATUS_REGISTER, IS_HIGHER_LOWER   
    BTFSC TUNING_STATUS_REGISTER, L_SUB_IS_NEGATIVE 
    CALL CHECK_L
    RETURN

CHECK_L
    BTFSC   TUNING_STATUS_REGISTER, H_IS_TUNED
    BSF	TUNING_STATUS_REGISTER, IS_HIGHER_LOWER
    RETURN

CHECK_H
    BTFSC   TUNING_STATUS_REGISTER, H_IS_TUNED
    BSF	TUNING_STATUS_REGISTER, IS_TUNED
    RETURN
;-------------------------------------------FIN ETAPA COMPARACION--------------------------------------------------------
     
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<EXPLICACION COMPRESS_TO_ONE_BYTE><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ;------------- Utiliza solo el nibble inferior del calculo de la desviacion de frecuencias. Con esto se pierde rango
    ; de precision, pero se estima que la cuerda a afinar no necesita una precision exageradamente grande.
    ;	En 1 byte (buffer) se comprimen los valores del DIF_FREQ_x en 7 bits (menos significativos), y el octavo bit
    ; indica si la desviacion es hacia la derecha o izquierda.
COMPRESS_TO_1_BYTE
   CLRF	BUFFER_TO_TX		    ;LIMPIAR EL BUFFER
   MOVF	DIF_FREQ_L, W		    ; SOLO MANDAMOS LA PARTE BAJA DE LA DESVIACION
   MOVWF BUFFER_TO_TX	
   MOVF	BUFFER_TO_TX, W
   SUBLW    b'01111111'		;En el caso de que el valor sea mayor a 127, el byte se pone todo en alto indicando exceso de desviacion
   BTFSS    STATUS, C
   GOTO OUT_OF_RANGE
   BCF	BUFFER_TO_TX, 7
   BTFSC    TUNING_STATUS_REGISTER, IS_HIGHER_LOWER	    ;1 SI HIGHER
   BSF	BUFFER_TO_TX, 7
   GOTO END_COMPRESSION

   
OUT_OF_RANGE				    ;esto le saca al afinador la posibilidad de detectar una desafinacion de 127 Hz, pero le da la posibilidad de detectar si esta fuera de rango
   MOVLW    0XFF
   MOVWF    BUFFER_TO_TX
   BCF	    BUFFER_TO_TX, 7
   BTFSC    TUNING_STATUS_REGISTER, IS_HIGHER_LOWER	    
   BSF	BUFFER_TO_TX, 7
   GOTO END_COMPRESSION
   
END_COMPRESSION
   RETURN
 ;---------------------------------SEND_TX<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 ;Subrutina de transmision serie. Carga el buffer en TXREG (BUFFER_TO_TX)
 
SEND_TX
    NOP
   RETURN
   
;---------------------------------------------------------------------------------------------------
;-----------------------------SEND PORT->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
 ; muestra resultados en puertos con la logica del afinador
 
SEND_PORT   
   BANKSEL PORTB
   CALL	MAP 
   MOVF TUNING_OUTPUT, W
   BANKSEL PORTD
   MOVWF    PORTD
   
   RETURN 
;----------------------------MAP: Subrutinba de Send_port<<<<<<<<<<<<
   ; Mapea los valores del buffer a valores que pueden ser mostrados en 7 leds. 3 para un sentido de afinacion
   ; 3 para el otro y uno que indica si la cuerda esta afinada. El valor de step es de .21
   ;utiliza una mascara para desligarse del bit de orientacion (0x7F)
MAP
   BANKSEL PORTB
    CLRF BUFFER_MASK
    CLRF TUNING_OUTPUT
    MOVF    BUFFER_TO_TX, W
    MOVWF   BUFFER_MASK			;TRABAJA CON LA MASCARA
    MOVLW   0X7F
    ANDWF   BUFFER_MASK, F
    BTFSC STATUS, Z    
    GOTO TUNED      
    BTFSC BUFFER_TO_TX, 7
    GOTO NEGATIVE      
    GOTO POSITIVE    
    GOTO END_MAP


NEGATIVE
    MOVLW   0X7F
    SUBWF   BUFFER_MASK, W
    BTFSC   STATUS, Z
    BSF	TUNING_OUTPUT, NEG_TUNE_2_LED	    ;CASO OUT OF RANGE
    MOVLW SPREAD
    SUBWF   BUFFER_MASK, W
    BTFSS STATUS, C
    GOTO TUNED				;SPREAD DE AFINACION NEGATIVA
    MOVF TUNER_STEP, W
    SUBWF   BUFFER_MASK, W
    BTFSS   STATUS, C
    BSF	TUNING_OUTPUT, NEG_TUNE_0_LED
    MOVF TUNER_STEP_2, W
    SUBWF   BUFFER_MASK, W
    BTFSS   STATUS, C
    BSF	TUNING_OUTPUT, NEG_TUNE_1_LED
    MOVF TUNER_STEP_3, W
    SUBWF   BUFFER_MASK, W
    BTFSS   STATUS, C
    BSF	TUNING_OUTPUT, NEG_TUNE_2_LED
    GOTO END_MAP

POSITIVE
    MOVLW   0X7F
    SUBWF   BUFFER_MASK, W
    BTFSC   STATUS, Z
    BSF	TUNING_OUTPUT, POS_TUNE_2_LED	    ;CASO OUT OF RANGE
    MOVLW SPREAD
    SUBWF   BUFFER_MASK, W
    BTFSS STATUS, C
    GOTO TUNED				;SPREAD DE AFINACION POSITIVA
    MOVF TUNER_STEP, W
    SUBWF   BUFFER_MASK, W
    BTFSS   STATUS, C
    BSF	TUNING_OUTPUT, POS_TUNE_0_LED
    MOVF TUNER_STEP_2, W
    SUBWF   BUFFER_MASK, W
    BTFSS   STATUS, C
    BSF	TUNING_OUTPUT, POS_TUNE_1_LED
    MOVF TUNER_STEP_3, W
    SUBWF   BUFFER_MASK, W
    BTFSS   STATUS, C
    BSF	TUNING_OUTPUT, POS_TUNE_2_LED
    GOTO END_MAP
TUNED
    BSF	TUNING_OUTPUT, IN_TUNE_LED
    GOTO END_MAP
END_MAP
    RETURN
 
;---------------------------------------------------------------------------------------------
;-------------------------FIN SEND_PORT----------------------------------------------------->
  
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
    

    
;------------------------------------------------------------------------------------------->
END