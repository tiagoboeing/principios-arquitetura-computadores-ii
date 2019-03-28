; I/O Address Bus decode - every device gets 0x200 addresses */

IO0  EQU  0000h
IO1  EQU  0200h
IO2  EQU  0400h
IO3  EQU  0600h
IO4  EQU  0800h
IO5  EQU  0A00h
IO6  EQU  0C00h
IO7  EQU  0E00h
IO8  EQU  1000h
IO9  EQU  1200h
IO10 EQU  1400h
IO11 EQU  1600h
IO12 EQU  1800h
IO13 EQU  1A00h
IO14 EQU  1C00h
IO15 EQU  1E00h



ADR_USART_DATA EQU  (IO4 + 00h)
;ONDE VOCE VAI MANDAR E RECEBER DADOS DO 8251

ADR_USART_CMD  EQU  (IO4 + 02h)
;� O LOCAL ONDE VOCE VAI ESCREVER PARA PROGRAMAR O 8251

ADR_USART_STAT EQU  (IO4 + 02h)
;RETORNA O STATUS SE UM CARACTER FOI DIGITADO
;RETORNA O STATUS SE POSSO TRANSMITIR CARACTER PARA O TERMINAL

;MEU CODIGO
code      SEGMENT 'code'
	  assume    CS:code,DS:data

	  org 0000h
;RESERVADO PARA VETOR DE INTERRUPCOES
	  org 0400h
;MEU CODIGO
inicio:
    MOV AX,DATA
    MOV DS,AX

	CALL INICIALIZA_8251
	MOV AL,"O"
	CALL MANDA_CARACTER
	MOV AL,"L"
	CALL MANDA_CARACTER
	MOV AL,"A"
	CALL MANDA_CARACTER
	MOV AL," "
	CALL MANDA_CARACTER
	MOV AL,"M"
	CALL MANDA_CARACTER
	MOV AL,"U"
	CALL MANDA_CARACTER
	MOV AL,"N"
	CALL MANDA_CARACTER
	MOV AL,"D"
	CALL MANDA_CARACTER
	MOV AL,"O"
	CALL MANDA_CARACTER

    
LOO:
   MOV UNID,0
   MOV DEZ, 0
   
ESCREVE:   
   MOV DX,IO3
   MOV BH,0
   MOV BL,UNID
   MOV AL,BIN7SEG[BX]
   OUT DX,AL
   MOV DX,IO2
   MOV BH,0
   MOV BL,DEZ
   MOV AL,BIN7SEG[BX]
   OUT DX,AL
   CALL DELAY

   MOV DX,IO1
   IN  AL,DX
   CMP AL,00000001B
   JE INICIO

UNIDADE:
   INC UNID
   CMP UNID,10D
   JE  DEZENA
   JMP ESCREVE

DEZENA:
   MOV UNID,0
   INC DEZ
   CMP DEZ,6D
   JE  ZERA
   JMP ESCREVE
   
ZERA:
   MOV DEZ,0
   JMP ESCREVE

DELAY:
   MOV DX,65535
DECDX:
   DEC DX
   CMP DX,0
   JNE DECDX
   RET

INICIALIZA_8251:                                     
   MOV AL,0
   MOV DX, ADR_USART_CMD
   OUT DX,AL
   OUT DX,AL
   OUT DX,AL
   MOV AL,40H
   OUT DX,AL
   MOV AL,4DH
   OUT DX,AL
   MOV AL,37H
   OUT DX,AL
   RET

MANDA_CARACTER:
   PUSHF
   PUSH DX
   PUSH AX  ; SALVA AL   
BUSY:
   MOV DX, ADR_USART_STAT
   IN  AL,DX
   TEST AL,1
   JZ BUSY
   MOV DX, ADR_USART_DATA
   POP AX  ; RESTAURA AL
   OUT DX,AL
   POP DX
   POPF
   RET 


code ends

;MILHA PILHA
STACK SEGMENT STACK      
DW 128 DUP(0) 
STACK ENDS 

;MEUS DADOS
DATA      SEGMENT  
	UNID DB 0
	DEZ  DB 0

   ; 0 to 9
   BIN7SEG DB 00111111B, 00000110B, 01011011B, 01001111B, 01100110B, 01101101B, 01111101B, 00000111B, 01111111B, 01101111B

DATA      ENDS

end inicio
