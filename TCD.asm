#include <p16f873A.inc>

;==========================================================================================================

; ____   ____  _       _______     _____       _  ____   ____  ________  _____   ______   
;|_  _| |_  _|/ \     |_   __ \   |_   _|     / \|_  _| |_  _||_   __  ||_   _|.' ____ \  
;  \ \   / / / _ \      | |__) |    | |      / _ \ \ \   / /    | |_ \_|  | |  | (___ \_| 
;   \ \ / / / ___ \     |  __ /     | |     / ___ \ \ \ / /     |  _| _   | |   _.____`.  
;    \ ' /_/ /   \ \_  _| |  \ \_  _| |_  _/ /   \ \_\ ' /     _| |__/ | _| |_ | \____) | 
;     \_/|____| |____||____| |___||_____||____| |____|\_/     |________||_____| \______.' 

;==========================================================================================================

    CBLOCK 0x20 
        NUMLEDS
        CONTADOR
        TRISBVAL
        ENTRADA_SERIAL
    ENDC

    ;Endereco do inicio do Programa apos Reset
    ORG 0x0000
    GOTO INICIO   

    ; Endereco de Rotinas de interrupcoes
    ORG 0x0004
    RETFIE
		
;==========================================================================================================

; _____  ____  _____  _____   ______  _____   ___    
;|_   _||_   \|_   _||_   _|.' ___  ||_   _|.'   `.  
;  | |    |   \ | |    | | / .'   \_|  | | /  .-.  \ 
;  | |    | |\ \| |    | | | |         | | | |   | | 
; _| |_  _| |_\   |_  _| |_\ `.___.'\ _| |_\  `-'  / 
;|_____||_____|\____||_____|`.____ .'|_____|`.___.' 

;==========================================================================================================

INICIO 		
    ; SETA AS CONFIGURA��ES DE ENVIO E RECEBIMENTO DE DADOS
    MOVLW b'00100110'
    banksel TXSTA
    MOVWF TXSTA

    MOVLW b'10010000'
    BANKSEL RCSTA
    MOVWF RCSTA

    ; Configurando bps pra 9600
    ; 4MHz/(16*9600) - 1 
    MOVLW d'25'
    BANKSEL SPBRG
    MOVWF SPBRG

    ; CONFIGURA��O INICIAL PARA O TRIS B, 4 ENTRADA (PARA APAGAR OS LEDS) E 4 DE SA�DA (PARA ACENDER/APAGAR OS LEDS)
    MOVLW b'00000000'
    BANKSEL TRISB
    MOVWF TRISB

LOOP ; Loop principal do programa
    CALL RECEBE ; Recebe o dado da serial
    GOTO TESTALED ; Mudando estado de algum LED
    GOTO TESTA8 ; Setando Output (numero de leds) no TRISB
    GOTO TESTA9 ; Apagando todos os LEDS
    GOTO TESTA10 ; Ligando todos os LEDS
    GOTO TESTA11 ; Pegando o status dos LEDS
    GOTO LOOP

;===========================================================================================================================
; ________  _____  _____  ____  _____   ______    ___   ________   ______   
;|_   __  ||_   _||_   _||_   \|_   _|.' ___  | .'   `.|_   __  |.' ____ \  
;  | |_ \_|  | |    | |    |   \ | | / .'   \_|/  .-.  \ | |_ \_|| (___ \_| 
;  |  _|     | '    ' |    | |\ \| | | |       | |   | | |  _| _  _.____`.  
; _| |_       \ \__/ /    _| |_\   |_\ `.___.'\\  `-'  /_| |__/ || \____) | 
;|_____|       `.__.'    |_____|\____|`.____ .' `.___.'|________| \______.' 
                                                                          
;===========================================================================================================================

ZERACONTADOR
    MOVLW d'0'
    MOVWF CONTADOR
    RETURN

RECEBE ; Recebe dados da serial
	NOP
	NOP
	NOP
	NOP
	NOP
    CALL OVERRUN
    BANKSEL PIR1
    BTFSS PIR1, RCIF ; Chegou algo?
    GOTO WAIT ; Nao
    MOVF RCREG, 0 ; Sim, recebe o valor em W
    MOVWF ENTRADA_SERIAL
	;DEBUG
	MOVF ENTRADA_SERIAL, 0
	CALL ENVIA ; Manda de volta para provar que recebeu
    RETURN

WAIT
	NOP
    NOP
    NOP
    NOP
    NOP
    GOTO RECEBE

ENVIA ; Envia o W para a serial
	CALL TESTAENVIO
	BANKSEL TXREG
	MOVWF TXREG ; Envia
	NOP
	NOP
	NOP
	NOP
	NOP
    RETURN

TESTAENVIO ; Espera um dado ser enviado antes de mandar outro
	NOP
	NOP
	NOP
	NOP
    NOP
    NOP
    NOP
    BANKSEL TXSTA ; trmt � o buffer que tem o status to registrador de transmissao
    BTFSS TXSTA, TRMT  ; trmt = 1?
    GOTO TESTAENVIO ; Nao, buffer est� mandando dado ainda, espera
    NOP ; Sim, mata tempo do proc e continua
    NOP
    NOP
	NOP
	NOP
	NOP
    RETURN

OVERRUN ; Testa o bit overrun e reseta se for necessario, para permitir o recebimento de bits
    BANKSEL RCSTA
    BTFSS RCSTA, OERR
    RETURN ; Ta ok, continue
    MOVLW b'10000000' ; Seta o CREN para 0
    MOVWF RCSTA
    NOP
    NOP
    NOP
    NOP
    NOP
    MOVLW b'10010000' ; Reseta o CREN para 1 para reabilitar o recebimento
    MOVWF RCSTA
    NOP
    NOP
    RETURN


;=======================================================================================================================================================

;   ______    ___   ____  _____  _________  _______      ___   _____     ________        ______   ________        _____     ________  ______    
; .' ___  | .'   `.|_   \|_   _||  _   _  ||_   __ \   .'   `.|_   _|   |_   __  |      |_   _ `.|_   __  |      |_   _|   |_   __  ||_   _ `.  
;/ .'   \_|/  .-.  \ |   \ | |  |_/ | | \_|  | |__) | /  .-.  \ | |       | |_ \_|        | | `. \ | |_ \_|        | |       | |_ \_|  | | `. \ 
;| |       | |   | | | |\ \| |      | |      |  __ /  | |   | | | |   _   |  _| _         | |  | | |  _| _         | |   _   |  _| _   | |  | | 
;\ `.___.'\\  `-'  /_| |_\   |_    _| |_    _| |  \ \_\  `-'  /_| |__/ | _| |__/ |       _| |_.' /_| |__/ |       _| |__/ | _| |__/ | _| |_.' / 
; `.____ .' `.___.'|_____|\____|  |_____|  |____| |___|`.___.'|________||________|      |______.'|________|      |________||________||______.'  
;

;=======================================================================================================================================================

TESTALED ;{ Testa se o comando de entrada est� setando algum LED
    MOVF ENTRADA_SERIAL, 0; Pega o dado da entrada no W
    SUBLW d'7'
    BTFSS STATUS, C ; Testa se o comando de entrada est� entre o numero de leds (0-7)
    GOTO TESTA8 ; � maior que 7, o comando � outro
	MOVF ENTRADA_SERIAL, 0; Pega o dado de entrada de novo

;================================================================================================================================
;  _____     ________  ______      ____    
; |_   _|   |_   __  ||_   _ `.  .'    '.  
;   | |       | |_ \_|  | | `. \|  .--.  | 
;   | |   _   |  _| _   | |  | || |    | | 
;  _| |__/ | _| |__/ | _| |_.' /|  `--'  | 
; |________||________||______.'  '.____.' 
;================================================================================================================================

	SUBLW d'0' ; Testa se � para trocar o estado do LED0
    BTFSS STATUS, Z
	GOTO TESTA_LED1 ; N�o � 0, Testa se � para o LED1
    BANKSEL PORTB
	BTFSS PORTB, RB0 ; O comando � para o LED0
	GOTO RB0_APAGADO
	BCF PORTB, RB0 ; LED0 Ligado, APAGA ele
	CALL LED_APAGADO
	GOTO LOOP

RB0_APAGADO ; RB0 Apagado, LIGA ele
	BSF PORTB, RB0
	CALL LED_LIGADO
	GOTO LOOP

;=================================================================================================================================
;  _____     ________  ______    __    
; |_   _|   |_   __  ||_   _ `. /  |   
;   | |       | |_ \_|  | | `. \`| |   
;   | |   _   |  _| _   | |  | | | |   
;  _| |__/ | _| |__/ | _| |_.' /_| |_  
; |________||________||______.'|_____| 
                                      
;=================================================================================================================================

TESTA_LED1
	MOVF ENTRADA_SERIAL, 0; Pega o dado de entrada de novo
	SUBLW d'1'
    BTFSS STATUS, Z ; Testa se == 1
	GOTO TESTA_LED2 ; N�o � 0, � outro led
    BANKSEL PORTB
	BTFSS PORTB, RB1 ; � para o LED1, testa o estado dele
	GOTO RB1_APAGADO
	BCF PORTB, RB1 ; Est� ligado, APAGA ele
	CALL LED_APAGADO
	GOTO LOOP

RB1_APAGADO
	BSF PORTB, RB1
	CALL LED_LIGADO
	GOTO LOOP

;================================================================================================================================
;  _____     ________  ______     _____
; |_   _|   |_   __  ||_   _ `.  / ___ `. 
;   | |       | |_ \_|  | | `. \|_/___) | 
;   | |   _   |  _| _   | |  | | .'____.' 
;  _| |__/ | _| |__/ | _| |_.' // /_____  
; |________||________||______.' |_______|
;================================================================================================================================

TESTA_LED2
	MOVF ENTRADA_SERIAL, 0; Pega o dado de entrada de novo
	SUBLW d'2'
    BTFSS STATUS, Z ; Testa se == 1
	GOTO TESTA_LED3 ; N�o � 0, � outro led
    BANKSEL PORTB
	BTFSS PORTB, RB2 ; � para o LED1, testa o estado dele
	GOTO RB2_APAGADO
	BCF PORTB, RB2 ; Est� ligado, APAGA ele
	CALL LED_APAGADO
	GOTO LOOP

RB2_APAGADO
	BSF PORTB, RB2
	CALL LED_LIGADO
	GOTO LOOP


;================================================================================================================================
;  _____     ________  ______     ______   
; |_   _|   |_   __  ||_   _ `.  / ____ `. 
;   | |       | |_ \_|  | | `. \ `'  __) | 
;   | |   _   |  _| _   | |  | | _  |__ '. 
;  _| |__/ | _| |__/ | _| |_.' /| \____) | 
; |________||________||______.'  \______.' 
;================================================================================================================================

TESTA_LED3
	MOVF ENTRADA_SERIAL, 0; Pega o dado de entrada de novo
	SUBLW d'3'
    BTFSS STATUS, Z ; Testa se == 1
	GOTO TESTA_LED4 ; N�o � 0, � outro led
    BANKSEL PORTB
	BTFSS PORTB, RB3 ; � para o LED1, testa o estado dele
	GOTO RB3_APAGADO
	BCF PORTB, RB3 ; Est� ligado, APAGA ele
	CALL LED_APAGADO
	GOTO LOOP

RB3_APAGADO
	BSF PORTB, RB3
	CALL LED_LIGADO
	GOTO LOOP

;======================================================================================================================================
;  _____     ________  ______    _    _    
; |_   _|   |_   __  ||_   _ `. | |  | |   
;   | |       | |_ \_|  | | `. \| |__| |_  
;   | |   _   |  _| _   | |  | ||____   _| 
;  _| |__/ | _| |__/ | _| |_.' /    _| |_  
; |________||________||______.'    |_____| 
;======================================================================================================================================

TESTA_LED4
	MOVF ENTRADA_SERIAL, 0; Pega o dado de entrada de novo
	SUBLW d'4'
    BTFSS STATUS, Z ; Testa se == 1
	GOTO TESTA_LED5 ; N�o � 0, � outro led
    BANKSEL PORTB
	BTFSS PORTB, RB4 ; � para o LED1, testa o estado dele
	GOTO RB4_APAGADO
	BCF PORTB, RB4 ; Est� ligado, APAGA ele
	CALL LED_APAGADO
	GOTO LOOP

RB4_APAGADO
	BSF PORTB, RB4
	CALL LED_LIGADO
	GOTO LOOP


;============================================================================================================================
;  _____     ________  ______    _______   
; |_   _|   |_   __  ||_   _ `. |  _____|  
;   | |       | |_ \_|  | | `. \| |____    
;   | |   _   |  _| _   | |  | |'_.____''. 
;  _| |__/ | _| |__/ | _| |_.' /| \____) | 
; |________||________||______.'  \______.' 
;============================================================================================================================


TESTA_LED5
	MOVF ENTRADA_SERIAL, 0; Pega o dado de entrada de novo
	SUBLW d'5'
    BTFSS STATUS, Z ; Testa se == 1
	GOTO TESTA_LED6 ; N�o � 0, � outro led
    BANKSEL PORTB
	BTFSS PORTB, RB5 ; � para o LED1, testa o estado dele
	GOTO RB5_APAGADO
	BCF PORTB, RB5 ; Est� ligado, APAGA ele
	CALL LED_APAGADO
	GOTO LOOP

RB5_APAGADO
	BSF PORTB, RB5
	CALL LED_LIGADO
	GOTO LOOP;


;================================================================================================================================
;  _____     ________  ______     ______   
; |_   _|   |_   __  ||_   _ `. .' ____ \  
;   | |       | |_ \_|  | | `. \| |____\_| 
;   | |   _   |  _| _   | |  | || '____`'. 
;  _| |__/ | _| |__/ | _| |_.' /| (____) | 
; |________||________||______.' '.______.' 
;================================================================================================================================

TESTA_LED6
	MOVF ENTRADA_SERIAL, 0; Pega o dado de entrada de novo
	SUBLW d'6'
    BTFSS STATUS, Z ; Testa se == 1
	GOTO TESTA_LED7 ; N�o � 0, � outro led
    BANKSEL PORTB
	BTFSS PORTB, RB6 ; � para o LED1, testa o estado dele
	GOTO RB6_APAGADO
	BCF PORTB, RB6 ; Est� ligado, APAGA ele
	CALL LED_APAGADO
	GOTO LOOP

RB6_APAGADO
	BSF PORTB, RB6
	CALL LED_LIGADO
	GOTO LOOP


;============================================================================================================================
;  _____     ________  ______    _______  
; |_   _|   |_   __  ||_   _ `. |  ___  | 
;   | |       | |_ \_|  | | `. \|_/  / /  
;   | |   _   |  _| _   | |  | |    / /   
;  _| |__/ | _| |__/ | _| |_.' /   / /    
; |________||________||______.'   /_/    
;=============================================================================================================================


TESTA_LED7
	MOVF ENTRADA_SERIAL, 0; Pega o dado de entrada de novo
	SUBLW d'7'
    BTFSS STATUS, Z ; Testa se == 1
	GOTO LOOP ; N�o � 0, � outro led
    BANKSEL PORTB
	BTFSS PORTB, RB7 ; � para o LED1, testa o estado dele
	GOTO RB7_APAGADO
	BCF PORTB, RB7 ; Est� ligado, APAGA ele
	CALL LED_APAGADO
	GOTO LOOP

RB7_APAGADO
	BSF PORTB, RB7
	CALL LED_LIGADO
	GOTO LOOP

LED_APAGADO ; Manda para o computador o numero 0 indicando que o estado do LED est� APAGADO
    MOVLW d'0'
	CALL ENVIA
    RETURN

LED_LIGADO ; Manda para o computador o numero 1 indicando que o estado do LED est� LIGADO
    MOVLW d'1'
	CALL ENVIA
    RETURN
;}

;=======================================================================================================================
;  ______   ________  _________     _              _____     ________  ______     ______   
;.' ____ \ |_   __  ||  _   _  |   / \            |_   _|   |_   __  ||_   _ `. .' ____ \  
;| (___ \_|  | |_ \_||_/ | | \_|  / _ \             | |       | |_ \_|  | | `. \| (___ \_| 
; _.____`.   |  _| _     | |     / ___ \            | |   _   |  _| _   | |  | | _.____`.  
;| \____) | _| |__/ |   _| |_  _/ /   \ \_         _| |__/ | _| |__/ | _| |_.' /| \____) | 
; \______.'|________|  |_____||____| |____|       |________||________||______.'  \______.' 
;=======================================================================================================================

TESTA8 ;{ Testa se o comando recebido � 8 (setando numero de leds no trisb)
    MOVF ENTRADA_SERIAL, 0 ; Pega o dado de entrada e coloca no W
    SUBLW d'8'
    BTFSS STATUS, Z 
    GOTO TESTA9 ; NAO, o comando � outro
    CALL RECEBE ; SIM, � 8, recebe o numero de leds
	MOVF ENTRADA_SERIAL, 0 ; Pega o dado de entrada e coloca no W
	;BANKSEL TRISB Removendo a troca do trisb
	;MOVWF TRISB
	BANKSEL PIR1
	MOVF ENTRADA_SERIAL, 0
	BANKSEL PORTB
	MOVWF TRISBVAL
	MOVF TRISBVAL, 0
	CALL ENVIA
	GOTO LOOP

;==============================================================================================================================
;      _       _______     _        ______       _               _____     ________  ______     ______   
;     / \     |_   __ \   / \     .' ___  |     / \             |_   _|   |_   __  ||_   _ `. .' ____ \  
;    / _ \      | |__) | / _ \   / .'   \_|    / _ \              | |       | |_ \_|  | | `. \| (___ \_| 
;   / ___ \     |  ___/ / ___ \  | |   ____   / ___ \             | |   _   |  _| _   | |  | | _.____`.  
; _/ /   \ \_  _| |_  _/ /   \ \_\ `.___]  |_/ /   \ \_          _| |__/ | _| |__/ | _| |_.' /| \____) | 
;|____| |____||_____||____| |____|`._____.'|____| |____|        |________||________||______.'  \______.' 
;==============================================================================================================================


TESTA9 ;{ Se a entrada for 9, apaga todos os LEDS
    MOVF ENTRADA_SERIAL, 0 ; Pega o dado da entrada
    SUBLW d'9' ; 9 = Apagando todos os leds
    BTFSS STATUS, Z 
    GOTO TESTA10 ; NAO, o comando � outro
    MOVLW b'00000000'
    BANKSEL PORTB
    MOVWF PORTB
    GOTO LOOP
;}


;==============================================================================================================================
;  _____     _____   ______       _              _____     ________  ______     ______   
; |_   _|   |_   _|.' ___  |     / \            |_   _|   |_   __  ||_   _ `. .' ____ \  
;   | |       | | / .'   \_|    / _ \             | |       | |_ \_|  | | `. \| (___ \_| 
;   | |   _   | | | |   ____   / ___ \            | |   _   |  _| _   | |  | | _.____`.  
;  _| |__/ | _| |_\ `.___]  |_/ /   \ \_         _| |__/ | _| |__/ | _| |_.' /| \____) | 
; |________||_____|`._____.'|____| |____|       |________||________||______.'  \______.'
;==============================================================================================================================

TESTA10 ;{ Liga todos os leds
    MOVF ENTRADA_SERIAL, 0 ; Pega o dado da entrada
    SUBLW d'10' ; 10 = Apagando todos os leds
    BTFSS STATUS, Z 
    GOTO TESTA11 ; NAO, o comando � outro
    MOVLW b'11111111'
    BANKSEL PORTB
    MOVWF PORTB
    GOTO LOOP
;}

;========================================================================================================================
; _______  ________    ______       _                 ______   _________     _     _________  _____  _____   ______   
;|_   __ \|_   __  | .' ___  |     / \              .' ____ \ |  _   _  |   / \   |  _   _  ||_   _||_   _|.' ____ \  
;  | |__) | | |_ \_|/ .'   \_|    / _ \             | (___ \_||_/ | | \_|  / _ \  |_/ | | \_|  | |    | |  | (___ \_| 
;  |  ___/  |  _| _ | |   ____   / ___ \             _.____`.     | |     / ___ \     | |      | '    ' |   _.____`.  
; _| |_    _| |__/ |\ `.___]  |_/ /   \ \_          | \____) |   _| |_  _/ /   \ \_  _| |_      \ \__/ /   | \____) | 
;|_____|  |________| `._____.'|____| |____|          \______.'  |_____||____| |____||_____|      `.__.'     \______.' 
;========================================================================================================================

TESTA11 ;{ 11 = Pega o status de todos os leds
    MOVF ENTRADA_SERIAL, 0 ; Pega o dado da entrada
    SUBLW d'11' ; 11 = Retorna para o serial o status de todos os leds
    BTFSS STATUS, Z 
    GOTO LOOP ; NAO, o comando � outro
    MOVF TRISBVAL, 0 ; Manda o TRSIB para W
    CALL ENVIA
    GOTO LOOP
;}

END
