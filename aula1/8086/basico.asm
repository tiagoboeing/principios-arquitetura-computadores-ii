
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

LOO:
	MOV DX,IO0
	INC AL
	OUT DX,AL



	JMP LOO
code ends

;MILHA PILHA
STACK SEGMENT STACK      
DW 128 DUP(0) 
STACK ENDS 

;MEUS DADOS
DATA      SEGMENT  
DATA      ENDS

end inicio
