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

ADR_USART_DATA EQU  (IO4 + 00h) ; 800H
;ONDE VOCE VAI MANDAR E RECEBER DADOS DO 8251

ADR_USART_CMD  EQU  (IO4 + 02h) ; 802H
;É O LOCAL ONDE VOCE VAI ESCREVER PARA PROGRAMAR O 8251

ADR_USART_STAT EQU  (IO4 + 02h) ; 802H
;RETORNA O STATUS SE UM CARACTER FOI DIGITADO
;RETORNA O STATUS SE POSSO TRANSMITIR CARACTER PARA O TERMINAL

; esta macro cria os ponteiros para interrupcoes
; os parametros sao o numero da interrupcao e o segment e offset da rotina tratadora
setup_int macro int_irq,int_cs,int_ip
   push di
   push ds
   mov di,0
   mov ds,di
   mov di,(int_irq)*4
   mov word ptr ds:[di],int_ip
   mov word ptr ds:[di+2],int_cs
   pop ds
   pop di
endm

; programa o ID da interrupcao para cada IRQ
io8259_std_init macro base,icw1_val,icw2_val,icw3_val,icw4_val
   mov dx,base
   mov al,icw1_val  
   out dx,al                
   mov dx,base+2
   mov al,icw2_val
   out dx,al
   mov al,icw3_val
   out dx,al
   mov al,icw4_val
   out dx,al
endm

;MEU CODIGO
code      SEGMENT 'code'
	  assume    CS:code,DS:data
	  org 0000h
;RESERVADO PARA VETOR DE INTERRUPCOES
	  org 0008h ; VETOR DE INTERRUPCAO NUMERO 2 (NMI)
PONTEIRO_SYSTICK DB 4 DUP('*')
	  org 0400h
;MEU CODIGO

INICIALIZA_8251:  ; 19200,8,N,1                                   
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

RECEBE_CARACTER: ; RETORNA EM AL O CARACTER DIGITADO
   PUSHF
   PUSH DX
AGUARDA_CARACTER:
   MOV DX, ADR_USART_STAT
   IN  AL,DX
   TEST AL,2
   JZ AGUARDA_CARACTER
   MOV DX, ADR_USART_DATA
   IN AL,DX
   SHR AL,1
NAO_RECEBIDO:
   POP DX
   POPF
   RET 

inicio:

    MOV AX,CODE
	MOV DS,AX

	MOV WORD PTR PONTEIRO_SYSTICK, OFFSET SYSTICK
	MOV WORD PTR PONTEIRO_SYSTICK+2, SEG  SYSTICK
	; configurando 8 interrupts do 8259
    cli                                                                                        
    setup_int 60h,seg int0,offset int0
    setup_int 61h,seg int1,offset int1
    setup_int 62h,seg int2,offset int2
    setup_int 63h,seg int3,offset int3
    setup_int 64h,seg int4,offset int4
    setup_int 65h,seg int5,offset int5
    setup_int 66h,seg int6,offset int6
    setup_int 67h,seg int7,offset int7
    io8259_std_init IO5,13h,60h,1bh,00h          
    sti

    MOV AX,DATA
    MOV DS,AX

	CALL INICIALIZA_8251 ; PROGRAMA 19200,N,8,1

	JMP $

AGUARDA_CARACTER_DIGITADO:
	
	CMP HA_CARACTER_DIGITADO, 'Y'
	JNE AGUARDA_CARACTER_DIGITADO
	MOV AL, CARACTER
	CALL MANDA_CARACTER
	MOV HA_CARACTER_DIGITADO,'N'
	JMP AGUARDA_CARACTER_DIGITADO

PAUSA:
	MOV BX,65535
DEC_PAUSE:
	DEC BX
	CMP BX,0
	JNE DEC_PAUSE
	RET

SYSTICK:
   PUSHF
   PUSH AX
   PUSH DX
   MOV DX, ADR_USART_DATA
   IN AL,DX
   SHR AL,1
   MOV CARACTER,AL   
   MOV HA_CARACTER_DIGITADO,'Y'
   POP DX
   POP AX
   POPF
   RET 

int0 proc far
     PUSHF
     PUSH AX
     mov AL,"0"
     CALL MANDA_CARACTER
     POP AX
     POPF
     iret
int0 endp

int1 proc far
     PUSHF
     PUSH AX
     mov AL,"1"
     CALL MANDA_CARACTER
     POP AX
     POPF
     iret
int1 endp

int2 proc far
     PUSHF
     PUSH AX
     mov AL,"2"
     CALL MANDA_CARACTER
     POP AX
     POPF
     iret
int2 endp

int3 proc far
     PUSHF
     PUSH AX
     mov AL,"3"
     CALL MANDA_CARACTER
     POP AX
     POPF
     iret
int3 endp

int4 proc far
     PUSHF
     PUSH AX
     mov AL,"4"
     CALL MANDA_CARACTER
     POP AX
     POPF
     iret
int4 endp

int5 proc far
     PUSHF
     PUSH AX
     mov AL,"5"
     CALL MANDA_CARACTER
     POP AX
     POPF
     iret
int5 endp

int6 proc far
     PUSHF
     PUSH AX
     mov AL,"6"
     CALL MANDA_CARACTER
     POP AX
     POPF
     iret
int6 endp

int7 proc far
     PUSHF
     PUSH AX
     mov AL,"7"
     CALL MANDA_CARACTER
     POP AX
     POPF
     iret
int7 endp

code ends

;MILHA PILHA
STACK SEGMENT STACK      
DW 128 DUP(0) 
STACK ENDS 

;MEUS DADOS
DATA      SEGMENT  
STRING DB 65 DUP(0)
MENS1 DB "ENTRE COM UMA STRING",13,10,0
MENS2 DB 13,10,"ENTRE COM UM CARACTER",13,10,0
MENS3 DB "QUANTIDADE DO CARACTER ",0
MENS4 DB " : AUSENTE",13,10,0
MENS5 DB " : PRESENTE",13,10,0
MENS6 DB " VEZES",13,10

MENS7  DB "ENTRE COM O NUMERO DA TABUADA",13,10,0
NUMERO DB ?

PALAVRA DB 65 DUP(0)
TRACOS  DB 64 DUP('-'),0

CARACTER DB ?
HA_CARACTER_DIGITADO DB 'N'

DATA      ENDS

end inicio
