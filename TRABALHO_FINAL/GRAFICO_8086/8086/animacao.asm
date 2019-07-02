.MODEL	SMALL

; I/O Address Bus decode - every device gets 0x200 addresses */

; 8255
IO4             EQU 0800h

ADR_PPI_PORTA   EQU (IO4)
ADR_PPI_PORTB   EQU (IO4 + 02h)
ADR_PPI_PORTC   EQU (IO4 + 04h)
ADR_PPI_CONTROL	EQU (IO4 + 06h)

PPI_PORTA_INP   EQU 10h
PPI_PORTA_OUT   EQU 00h
PPI_PORTB_INP   EQU 02h
PPI_PORTB_OUT   EQU 00h
PPI_PORTCL_INP  EQU 01h
PPI_PORTCL_OUT  EQU 00h
PPI_PORTCH_INP  EQU 08h
PPI_PORTCH_OUT  EQU 00h
PPI_MODE_BCL_0  EQU 00h
PPI_MODE_BCL_1  EQU 04h
PPI_MODE_ACH_0  EQU 00h
PPI_MODE_ACH_1  EQU 20h
PPI_MODE_ACH_2  EQU 40h
PPI_ACTIVE      EQU 80h

.8086
.code

ORG 0008H
PONTEIRO_TRATADOR_INTERRUPCAO DB 4 DUP("J")       ; NMI

ORG 0400H

; LIGA DISPLAY
GLCD_ON:
          CALL     GLCD_CS1_LOW
          CALL     GLCD_CS2_LOW
          CALL     GLCD_RS_LOW
          CALL     GLCD_RW_LOW
          MOV      AL,03FH
          CALL     MANDA_PORT_B
          CALL     ENABLE_PULSE
          RET

          ; ------------------------------------
          ; POSICIONA "CURSOR" NA COLUNA
GLCD_GOTO_COL:
          PUSHF
          PUSH     AX

          CALL     GLCD_RS_LOW
          CALL     GLCD_RW_LOW
          CMP      AH,64
          JL       LEFT

          CALL     GLCD_CS2_LOW
          CALL     GLCD_CS1_HIGH
          SUB      AH,64
          MOV      COL_DATA,AH
          JMP      SAI_GOTO_COL

LEFT:
          CALL     GLCD_CS1_LOW
          CALL     GLCD_CS2_HIGH
          MOV      COL_DATA,AH

SAI_GOTO_COL:
          OR       COL_DATA, 40H
          AND      COL_DATA, 7FH
          MOV      AL,COL_DATA
          CALL     MANDA_PORT_B
          CALL     ENABLE_PULSE
          POP      AX
          POPF
          RET
          ; ------------------------------------

          ; ------------------------------------
          ; POSICIONA "CURSOR" NA COLUNA
GLCD_GOTO_COL_TEXT:
          PUSHF
          PUSH     AX
          PUSH     BX

          PUSH     AX
          MOV      BL,8
          MOV      AL,AH
          MUL      BL
          MOV      BL,AL
          POP      AX
          MOV      AH,BL

          CALL     GLCD_RS_LOW
          CALL     GLCD_RW_LOW
          CMP      AH,64
          JL       LEFT_TEXT

          CALL     GLCD_CS2_LOW
          CALL     GLCD_CS1_HIGH
          SUB      AH,64
          MOV      COL_DATA,AH
          JMP      SAI_GOTO_COL_TEXT

LEFT_TEXT:
          CALL     GLCD_CS1_LOW
          CALL     GLCD_CS2_HIGH
          MOV      COL_DATA,AH

SAI_GOTO_COL_TEXT:
          OR       COL_DATA, 40H
          AND      COL_DATA, 7FH
          MOV      AL,COL_DATA
          CALL     MANDA_PORT_B
          CALL     ENABLE_PULSE
          POP      BX
          POP      AX
          POPF
          RET
          ; ------------------------------------

          ; ------------------------------------
          ; POSICIONA "CURSOR" NA LINHA
GLCD_GOTO_ROW:
          PUSH     AX
          CALL     GLCD_RS_LOW
          CALL     GLCD_RW_LOW
          OR       AL,0B8H
          AND      AL,0BFH
          MOV      COL_DATA,AL
          CALL     MANDA_PORT_B
          CALL     ENABLE_PULSE
          POP      AX
          RET
          ; ------------------------------------

          ; ------------------------------------
          ; POSICIONA "CURSOR" NA LINHA
GLCD_GOTO_ROW_TEXT:
          PUSH     AX
          CALL     GLCD_RS_LOW
          CALL     GLCD_RW_LOW
          OR       AL,0B8H
          AND      AL,0BFH
          MOV      COL_DATA,AL
          CALL     MANDA_PORT_B
          CALL     ENABLE_PULSE
          POP      AX
          RET
          ; ------------------------------------


          ; ------------------------------------
          ; AH LINHA E  AL COLUNA
          ; POSICIONAMENTO DO "CURSOR" EM LINHA X COLUNA
          ; MODO GRAFICO (128x64)
GLCD_GOTO_XY:
          CALL     GLCD_GOTO_COL
          CALL     GLCD_GOTO_ROW
          RET
          ; ;------------------------------------

          ; ------------------------------------
          ; AH LINHA E  AL COLUNA
          ; POSICIONAMENTO DO "CURSOR" EM LINHA X COLUNA
          ; COLUNAS 16 (0..15), LINHAS 8 (0..7)
GLCD_GOTO_XY_TEXT:
          CALL     GLCD_GOTO_COL_TEXT
          CALL     GLCD_GOTO_ROW_TEXT
          RET
          ; ------------------------------------

          ; AL = DATA
GLCD_WRITE:
          CALL     GLCD_RS_HIGH
          CALL     GLCD_RW_LOW
          CALL     MANDA_PORT_B
          CALL     ENABLE_PULSE
          RET

          ; AL = DATA
GLCD_CLRLN:
          PUSHF
          PUSH     AX
          PUSH     CX
          MOV      AH,0
          CALL     GLCD_GOTO_XY
          MOV      AH,64
          CALL     GLCD_GOTO_XY
          CALL     GLCD_CS1_LOW
          MOV      AL,0
          MOV      CX,64
ESCREVA:
          CALL     GLCD_WRITE
          LOOP     ESCREVA
          POP      CX
          POP      AX
          POPF
          RET

          ; ---------------------------------------------------------
          ; APAGA DISPLAY GRAFICO
GLCD_CLR:
          PUSHF
          PUSH     AX
          MOV      AL,0
CLRLN:
          CALL     GLCD_CLRLN
          ADD      AL,1
          CMP      AL,8
          JNE      CLRLN
          POP      AX
          POPF
          RET
          ; ---------------------------------------------------------

          ; ---------------------------------------------------------
          ; DESENHA UM PONTO NESTAS COORDENADAS
          ; AH, AL, BH
          ; COLUNAS MODO GRAFICO = 128 (0..127) AH
          ; LINHAS MODO GRAFICO = 64 (0..63) AL
          ; BH = 0 PIXEL APAGADO, BH=1 PIXEL ACESO
GLCD_DRAW_POINT:
          PUSHF
          PUSH     AX
          PUSH     BX
          PUSH     CX

          PUSH     AX                                                                                ; SALVA AH, AL
          PUSH     AX                                                                                ; SALVA AH, AL

          MOV      CH,AH                                                                             ; SALVA AH
          MOV      AH,0

          MOV      BL,8
          DIV      BL

          MOV      AH,CH
          CALL     GLCD_GOTO_XY

          POP      AX                                                                                ; RESTAURA AH, AL

          CMP      BH,0
          JE       LIGHT_SPOT

          MOV      AH,0
          MOV      BH,8
          DIV      BH
          ; AH RESTO
          MOV      CL,AH
          MOV      AL,1
          SHL      AL,CL
          MOV      COL_DATA_AUX,AL

          MOV      AH,CH
          CALL     GLCD_READ_DATA
          OR       COL_DATA_AUX,AL

          JMP      SAI_GLCD_DRAW_POINT

LIGHT_SPOT:
          MOV      AH,0
          MOV      BH,8
          DIV      BH
          ; AH RESTO
          MOV      CL,AH
          MOV      AL,1
          SHL      AL,CL
          NOT      AL
          MOV      COL_DATA_AUX,AL

          MOV      AH,CH
          CALL     GLCD_READ_DATA
          AND      COL_DATA_AUX,AL

SAI_GLCD_DRAW_POINT:
          POP      AX

          MOV      CH,AH                                                                             ; SALVA AH
          MOV      AH,0

          MOV      BL,8
          DIV      BL

          MOV      AH,CH
          CALL     GLCD_GOTO_XY

          MOV      AL, COL_DATA_AUX
          CALL     GLCD_WRITE

          POP      CX
          POP      BX
          POP      AX
          POPF
          RET
          ; ---------------------------------------------------------

          ; ---------------------------------------------------------
          ; LE STATUS DO DISPLAY
GLCD_READ_DATA:
          CALL     INICIALIZA_8255_PORT_INPUT
          CALL     GLCD_RW_HIGH
          CALL     GLCD_RS_HIGH
          CMP      AH,63
          JG       HAB_CS2

HAB_CS1:
          CALL     GLCD_CS2_HIGH
          CALL     GLCD_CS1_LOW
          JMP      HAB

HAB_CS2:
          CALL     GLCD_CS2_LOW
          CALL     GLCD_CS1_HIGH

HAB:
          CALL     GLCD_EN_HIGH
          CALL     GLCD_EN_LOW
          CALL     GLCD_EN_HIGH
          CALL     LE_PORT_B
          MOV      READ_DATA,AL
          CALL     GLCD_EN_LOW
          CALL     INICIALIZA_8255_PORTB_OUTPUT
          RET
          ; ---------------------------------------------------------

          ; ---------------------------------------------------------
          ; AL = INDICE CARACTER FONT (COMECA EM 0)
          ; IMPRIME CARACTER NA LINHA E COLUNA DEFINIDA
PRINT_CAR:
          PUSHF
          PUSH     AX
          PUSH     BX
          PUSH     CX
          MOV      BL,5
          MUL      BL
          MOV      BX,AX
          MOV      CX,5

PRINTING_CAR:
          MOV      AL,FONTS[BX]
          CALL     GLCD_WRITE
          INC      BX
          LOOP     PRINTING_CAR
          POP      CX
          POP      BX
          POP      AX
          POPF
          RET

          ; ---------------------------------------------------------
          ; AH = COLUNA, AL=LINHA
          ; PRIMEIRO BYTE DO VETOR ? NUMERO DE LINHAS E COLUNAS OCUPADAS
          ; EXEMPLO, IMAGEM DE 24X24 PIXELS = 3 LINHAS X 3 COLUNAS
PRINT_ICON:
          PUSHF
          PUSH     AX
          PUSH     CX
MOV CL,   DS       :[SI]
          MOV      QNT_COLUNAS, CL                                                                   ; QNT COLUNAS IMPRESSAS
          MOV      SALVA_QNT_COLUNAS, CL                                                             ; GUARDA QNT PARA NOVO LACO QNT COLUNAS IMPRESSAS
          MOV      POS_COLUNAS, AH                                                                   ; COLUNA PASSADA COMO PARAMETRO
MOV CL,   DS       :[SI+1]
          MOV      LINHA, CL                                                                         ; LINHA
          ADD      SI,2                                                                              ; APONTA PARA ICONE...

PRINT:
          MOV      CX,8
          CALL     GLCD_GOTO_XY_TEXT
PRINTING_ICON:
          PUSH     AX
MOV AL,   DS       :[SI]
          CALL     GLCD_WRITE
          POP      AX
          INC      SI
          LOOP     PRINTING_ICON
          INC      AH
          DEC      QNT_COLUNAS
          JNE      PRINT
          MOV      AH,SALVA_QNT_COLUNAS
          MOV      QNT_COLUNAS,AH
          MOV      AH,POS_COLUNAS
          INC      AL
          DEC      LINHA
          JNE      PRINT
          POP      CX
          POP      AX
          POPF
          RET

          ; ---------------------------------------------------------
          ; ESTA ROTINA IMPRIME O GRAFICO APONTADO POR SI
PLOT_BMP:
          PUSHF
          PUSH     AX
          PUSH     SI
          MOV      AL,0
          MOV      AH,0
PLOT:
          CALL     GLCD_GOTO_XY
          PUSH     AX
          MOV      AL,[SI]
          CALL     GLCD_WRITE
          POP      AX
          INC      SI
          INC      AH
          CMP      AH,127
          JNE      PLOT
          MOV      AH,0
          INC      AL
          CMP      AL,8
          JNE      PLOT
          POP      SI
          POP      AX
          POPF
          RET
          ; ---------------------------------------------------------

          ; ---------------------------------------------------------
          ; ATIVA O GLCD
GLCD_ATIVA:
          CALL     GLCD_CS1_HIGH
          CALL     GLCD_CS2_HIGH
          CALL     GLCD_RST_HIGH
          CALL     GLCD_ON
          RET
          ; ---------------------------------------------------------

          ; ---------------------------------------------------------
          ; ESTAS ROTINAS APENAS GERAM PULSOS PARA O DISPLAY GRAFICO
GLCD_CS1_HIGH:
          PUSHF
          PUSH     AX
          OR       GLCD_CONTROL, 32
          MOV      AL,GLCD_CONTROL
          CALL     MANDA_PORT_A
          POP      AX
          POPF
          RET

GLCD_CS1_LOW:
          PUSHF
          PUSH     AX
          MOV      AL, 32
          NOT      AL
          AND      GLCD_CONTROL, AL
          MOV      AL,GLCD_CONTROL
          CALL     MANDA_PORT_A
          POP      AX
          POPF
          RET

GLCD_CS2_HIGH:
          PUSHF
          PUSH     AX
          OR       GLCD_CONTROL, 16
          MOV      AL,GLCD_CONTROL
          CALL     MANDA_PORT_A
          POP      AX
          POPF
          RET

GLCD_CS2_LOW:
          PUSHF
          PUSH     AX
          MOV      AL, 16
          NOT      AL
          AND      GLCD_CONTROL, AL
          MOV      AL,GLCD_CONTROL
          CALL     MANDA_PORT_A
          POP      AX
          POPF
          RET

GLCD_RST_HIGH:
          PUSHF
          PUSH     AX
          OR       GLCD_CONTROL, 1
          MOV      AL,GLCD_CONTROL
          CALL     MANDA_PORT_A
          POP      AX
          POPF
          RET

GLCD_RST_LOW:
          PUSHF
          PUSH     AX
          MOV      AL, 1
          NOT      AL
          AND      GLCD_CONTROL, AL
          MOV      AL,GLCD_CONTROL
          CALL     MANDA_PORT_A
          POP      AX
          POPF
          RET

GLCD_EN_HIGH:
          PUSHF
          PUSH     AX
          OR       GLCD_CONTROL, 2
          MOV      AL,GLCD_CONTROL
          CALL     MANDA_PORT_A
          POP      AX
          POPF
          RET

GLCD_EN_LOW:
          PUSHF
          PUSH     AX
          MOV      AL, 2
          NOT      AL
          AND      GLCD_CONTROL, AL
          MOV      AL,GLCD_CONTROL
          CALL     MANDA_PORT_A
          POP      AX
          POPF
          RET

GLCD_RW_HIGH:
          PUSHF
          PUSH     AX
          OR       GLCD_CONTROL, 4
          MOV      AL,GLCD_CONTROL
          CALL     MANDA_PORT_A
          POP      AX
          POPF
          RET

GLCD_RW_LOW:
          PUSHF
          PUSH     AX
          MOV      AL, 4
          NOT      AL
          AND      GLCD_CONTROL, AL
          MOV      AL,GLCD_CONTROL
          CALL     MANDA_PORT_A
          POP      AX
          POPF
          RET

GLCD_RS_HIGH:
          PUSHF
          PUSH     AX
          OR       GLCD_CONTROL, 8
          MOV      AL,GLCD_CONTROL
          CALL     MANDA_PORT_A
          POP      AX
          POPF
          RET

GLCD_RS_LOW:
          PUSHF
          PUSH     AX
          MOV      AL, 8
          NOT      AL
          AND      GLCD_CONTROL, AL
          MOV      AL,GLCD_CONTROL
          CALL     MANDA_PORT_A
          POP      AX
          POPF
          RET

ENABLE_PULSE:
          CALL     GLCD_EN_HIGH
          CALL     GLCD_EN_LOW
          RET

          ; ---------------------------------------------------------
          ; ROTINAS PARA 8255
INICIALIZA_8255_PORTB_OUTPUT:
          PUSHF
          PUSH     AX
          PUSH     DX
          MOV      DX, ADR_PPI_CONTROL
          MOV      AL,0
          OR       AL,PPI_PORTA_OUT
          OR       AL,PPI_PORTB_OUT
          OR       AL,PPI_PORTCL_INP
          OR       AL,PPI_PORTCH_INP
          OR       AL,PPI_MODE_BCL_0
          OR       AL,PPI_MODE_ACH_0
          OR       AL,PPI_ACTIVE
          OUT      DX,AL
          POP      DX
          POP      AX
          POPF
          RET

INICIALIZA_8255_PORT_INPUT:
          PUSHF
          PUSH     AX
          PUSH     DX
          MOV      DX, ADR_PPI_CONTROL
          MOV      AL,0
          OR       AL,PPI_PORTA_OUT
          OR       AL,PPI_PORTB_INP
          OR       AL,PPI_PORTCL_INP
          OR       AL,PPI_PORTCH_INP
          OR       AL,PPI_MODE_BCL_0
          OR       AL,PPI_MODE_ACH_0
          OR       AL,PPI_ACTIVE
          OUT      DX,AL
          POP      DX
          POP      AX
          POPF
          RET

MANDA_PORT_A:
          PUSHF
          PUSH     DX
          MOV      DX,ADR_PPI_PORTA
          OUT      DX,AL
          POP      DX
          POPF
          RET

MANDA_PORT_B:
          PUSHF
          PUSH     DX
          MOV      DX,ADR_PPI_PORTB
          OUT      DX,AL
          POP      DX
          POPF
          RET

LE_PORT_B:
          PUSHF
          PUSH     DX
          MOV      DX,ADR_PPI_PORTB
          IN       AL,DX
          POP      DX
          POPF
          RET

LE_PORT_C:
          PUSHF
          PUSH     DX
          MOV      DX,ADR_PPI_PORTC
          IN       AL,DX
          POP      DX
          POPF
          RET
          ; ---------------------------------------------------------

.startup

MOV AX,@DATA
MOV     DS       ,AX
        MOV      AX,@STACK
        MOV      SS,AX

        CALL     INICIALIZA_8255_PORTB_OUTPUT

        CALL     GLCD_ATIVA
        ; ---------------------------------------------------------

        ; INICIO DO JOGO
GAME:
        CALL  GLCD_CLR
        
        ; TELA INICIAL
        CALL TELA_INICIAL
        CALL BORDA_SUPERIOR
        CALL BORDA_INFERIOR

                ; CONGELA TELA 5 SEGS
                MOV   CX, 15
                CALL  DELAY_SEG
                
                CALL  GLCD_CLR


        ;CALL  PERSONAGEM
        
        ; OPERA??ES
        CALL TEXT_OPERACOES

                ; 8 SEGUNDOS
                MOV   CX, 8
                CALL  DELAY_SEG

        ; N?VEL 1
        CALL GLCD_CLR   ; LIMPA DISPLAY
        CALL TEXT_NIVEL1

                ; 7 SEGUNDOS
                MOV   CX, 7     ; CONGELA 7 SEGUNDOS
                CALL  DELAY_SEG

        ; MOSTRA PERGUNTA
        CALL  SINAIS
        CALL  BORDA_SUPERIOR
        CALL  ANIMACAO_CARRO


        ; ------------------------
        ; L?GICA DE GERAR N?MERO RANDOM E EXIBIR NA TELA


        ; ------------------------


        ; RESPOSTA
        ; NECESS?RIO PARA MOSTRAR DE ACORDO COM A L?GICA DO RANDOM
        CALL RESPOSTA_CORRETA
                
                ; 7 SEGUNDOS
                MOV   CX, 7     ; CONGELA 7 SEGUNDOS
                CALL  DELAY_SEG

        JMP      $
        ; ROTINA DELAY DAS ANIMA??ES

DELAY_SEG:
          MOV      DX, 65000D

DECDX:
          SUB      DX, 1

          CMP      DX, 0
          JNE      DECDX

          LOOP     DELAY_SEG
          RET

          ; --------------------------------



RESPOSTA_CORRETA: 
        ; FRAME 0
        LEA     SI, MAOFRAME0
        CALL    PLOT_BMP

                ; 2 SEGUNDOS
                MOV   CX, 2
                CALL  DELAY_SEG

        ; FRAME 1
        LEA     SI, MAOFRAME1
        CALL    PLOT_BMP

                ; 2 SEGUNDOS
                MOV   CX, 2
                CALL  DELAY_SEG
        
        ; FRAME 2
        LEA     SI, MAOFRAME2
        CALL    PLOT_BMP

                ; 2 SEGUNDOS
                MOV   CX, 2
                CALL  DELAY_SEG

        ; NOTA 10
        LEA     SI, NOTA_10
        CALL    PLOT_BMP
        RET

SINAIS:
          CALL     GLCD_CLR
          CALL     DESENHA_MAIS
          CALL     DESENHA_MENOS
          RET

BORDA_SUPERIOR:
        MOV      AH,1                                                                              ; COLUNA
        MOV      AL,0                                                                              ; LINHA
        CALL     GLCD_GOTO_XY_TEXT
        MOV      BH,0
        LEA      SI, OSSO
        CALL     PRINT_ICON

        MOV      AH,4                                                                              ; COLUNA
        MOV      AL,0                                                                              ; LINHA
        CALL     GLCD_GOTO_XY_TEXT
        MOV      BH,0
        LEA      SI, OSSO
        CALL     PRINT_ICON

        MOV      AH,7                                                                              ; COLUNA
        MOV      AL,0                                                                              ; LINHA
        CALL     GLCD_GOTO_XY_TEXT
        MOV      BH,0
        LEA      SI, OSSO
        CALL     PRINT_ICON

        MOV      AH,10                                                                              ; COLUNA
        MOV      AL,0                                                                              ; LINHA
        CALL     GLCD_GOTO_XY_TEXT
        MOV      BH,0
        LEA      SI, OSSO
        CALL     PRINT_ICON

        MOV      AH,13                                                                              ; COLUNA
        MOV      AL,0                                                                              ; LINHA
        CALL     GLCD_GOTO_XY_TEXT
        MOV      BH,0
        LEA      SI, OSSO
        CALL     PRINT_ICON
        RET  

BORDA_INFERIOR:
        MOV      AH,1                                                                              ; COLUNA
        MOV      AL,7                                                                              ; LINHA
        CALL     GLCD_GOTO_XY_TEXT
        MOV      BH,0
        LEA      SI, OSSO
        CALL     PRINT_ICON

        MOV      AH,4                                                                              ; COLUNA
        MOV      AL,7                                                                              ; LINHA
        CALL     GLCD_GOTO_XY_TEXT
        MOV      BH,0
        LEA      SI, OSSO
        CALL     PRINT_ICON

        MOV      AH,7                                                                              ; COLUNA
        MOV      AL,7                                                                              ; LINHA
        CALL     GLCD_GOTO_XY_TEXT
        MOV      BH,0
        LEA      SI, OSSO
        CALL     PRINT_ICON

        MOV      AH,10                                                                              ; COLUNA
        MOV      AL,7                                                                              ; LINHA
        CALL     GLCD_GOTO_XY_TEXT
        MOV      BH,0
        LEA      SI, OSSO
        CALL     PRINT_ICON

        MOV      AH,13                                                                              ; COLUNA
        MOV      AL,7                                                                              ; LINHA
        CALL     GLCD_GOTO_XY_TEXT
        MOV      BH,0
        LEA      SI, OSSO
        CALL     PRINT_ICON
        RET  
PERSONAGEM:
          LEA      SI, VERT
          MOV      AH,0                                                                              ; COLUNA
          MOV      AL,0                                                                              ; LINHA
          CALL     PRINT_ICON
          RET

DESENHA_MAIS:
          MOV      AH,5                                                                              ; COLUNA
          MOV      AL,2                                                                              ; LINHA
          CALL     GLCD_GOTO_XY_TEXT
          MOV      BH,0
          LEA      SI, SINAL_MAIS
          CALL     PRINT_ICON
          RET

DESENHA_MENOS:
          MOV      AH,9                                                                              ; COLUNA
          MOV      AL,2                                                                              ; LINHA
          CALL     GLCD_GOTO_XY_TEXT
          MOV      BH,0
          LEA      SI, SINAL_MENOS
          CALL     PRINT_ICON
          RET

DESENHA_MAIS_PREENCHIDO:
          MOV      AH,5                                                                              ; COLUNA
          MOV      AL,2                                                                              ; LINHA
          CALL     GLCD_GOTO_XY_TEXT
          MOV      BH,0
          LEA      SI, SINAL_MAIS_PREENCHIDO
          CALL     PRINT_ICON
          RET

DESENHA_MENOS_PREENCHIDO:
MOV      AH,9                                                                              ; COLUNA
MOV      AL,2                                                                              ; LINHA
        CALL     GLCD_GOTO_XY_TEXT
        MOV      BH,0
        LEA      SI, SINAL_MENOS_PREENCHIDO
        CALL     PRINT_ICON
        RET

ANIMACAO_CARRO:
MOV     AH,0                                                                            ; COLUNA
MOV     AL,4                                                                            ; LINHA
        CALL    GLCD_GOTO_XY_TEXT
        MOV     BH,0

        CALL    CARRO_F1
        MOV     CX,2
        CALL    DELAY_SEG

        CALL    CARRO_F2
        MOV     CX,2
        CALL    DELAY_SEG

        CALL    CARRO_F3
        MOV     CX,2
        CALL    DELAY_SEG

        CALL    CARRO_F4
        MOV     CX,2
        CALL    DELAY_SEG

        CALL    CARRO_F5
        MOV     CX,2
        CALL    DELAY_SEG

        CALL    CARRO_F6
        MOV     CX,2
        CALL    DELAY_SEG

        CALL    CARRO_F7
        MOV     CX,2
        CALL    DELAY_SEG
        
        ; LIMPA LOCAL DO CARRO
        LEA     SI, CARRO_CLEAR
        CALL    PRINT_ICON

        RET

TELA_INICIAL:
          MOV      AH,5                                                                              ; COLUNA
          MOV      AL,2                                                                              ; LINHA
          CALL     GLCD_GOTO_XY_TEXT
          MOV      BH,0
          LEA      SI, MAIS_E_MENOS
          CALL     PRINT_ICON
          RET

CARRO_F1:
        CMP     CX,0
        LEA     SI, CARRO_FRAME1
        JE      PRINT_ICON
        RET
CARRO_F2:
        CMP     CX,0
        LEA     SI, CARRO_FRAME2
        JE      PRINT_ICON
        RET
CARRO_F3:
        CMP     CX,0
        LEA     SI, CARRO_FRAME3
        JE      PRINT_ICON
        RET
CARRO_F4:
        CMP     CX,0
        LEA     SI, CARRO_FRAME4
        JE      PRINT_ICON
        RET

CARRO_F5:
        CMP     CX,0
        LEA     SI, CARRO_FRAME5
        JE      PRINT_ICON
        RET

CARRO_F6:
        CMP     CX,0
        LEA     SI, CARRO_FRAME6
        JE      PRINT_ICON
        RET

CARRO_F7:
        CMP     CX,0
        LEA     SI, CARRO_FRAME7
        JE      PRINT_ICON
        RET

TEXT_OPERACOES:
        MOV AH,3 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"O"
        CALL PRINT_CAR  
        
        MOV AH,4 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"P"
        CALL PRINT_CAR  

        MOV AH,5 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"E"
        CALL PRINT_CAR  

        MOV AH,6 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"R"
        CALL PRINT_CAR  
        
        MOV AH,7 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"A"
        CALL PRINT_CAR  

        MOV AH,8 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"C"
        CALL PRINT_CAR  

        MOV AH,9 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"O"
        CALL PRINT_CAR  

        MOV AH,10 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"E"
        CALL PRINT_CAR  

        MOV AH,11 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"S"
        CALL PRINT_CAR

        RET  

TEXT_NIVEL1:
        MOV AH,5 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"N"
        CALL PRINT_CAR 
        
        MOV AH,6 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"I"
        CALL PRINT_CAR 
        
        MOV AH,7 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"V"
        CALL PRINT_CAR 

        MOV AH,8 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"E"
        CALL PRINT_CAR 

        MOV AH,9 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"L"
        CALL PRINT_CAR 

        MOV AH,10 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL," "
        CALL PRINT_CAR 

        MOV AH,11 ;COLUNA
        MOV AL,4  ;LINHA
        CALL GLCD_GOTO_XY_TEXT
        MOV AL,"1"
        CALL PRINT_CAR 

        RET

        ; POSICIONA CURSOR COLUNA 0, LINHA 0
        ; IMPRIME LETRA "A"
        ; MOV AH,7 ;COLUNA
        ; MOV AL,0 ;LINHA
        ; CALL GLCD_GOTO_XY_TEXT
        ; MOV AL,"A"
        ; CALL PRINT_CAR

        ; POSICIONA CURSOR COLUNA 15, LINHA 1
        ; IMPRIME LETRA "B"
        ; MOV AH,15 ;COLUNA
        ; MOV AL,1  ;LINHA
        ; CALL GLCD_GOTO_XY_TEXT
        ; MOV AL,"B"
        ; CALL PRINT_CAR

        ; POSICIONA CURSOR COLUNA 7, LINHA 7
        ; IMPRIME LETRA "C"
        ; MOV AH,15 ;COLUNA
        ; MOV AL,7  ;LINHA
        ; CALL GLCD_GOTO_XY_TEXT
        ; MOV AL,"C"
        ; CALL PRINT_CAR

        ; sprite 24x24 bits
        ; AH = LINHA, COLUNA = AL
        ; LEA SI, FLECHA
        ; MOV AH,0 ;COLUNA
        ; MOV AL,0  ;LINHA
        ; CALL PRINT_ICON

        ; sprite 24x24 bits
        ; AH = LINHA, COLUNA = AL
        ; LEA SI, BOOK_OPEN
        ; MOV AH,0 ;COLUNA
        ; MOV AL,0  ;LINHA
        ; CALL PRINT_ICON


        ; sprite 32x32 bits
        ; AH = LINHA, COLUNA = AL
        ; LEA SI, GUY
        ; MOV AH,5 ;COLUNA
        ; MOV AL,4  ;LINHA
        ; CALL PRINT_ICON

        ; APAGA DISPLAY
        ; CALL GLCD_CLR


        ; sprite 128x64 bits
        ; AH = LINHA, COLUNA = AL
        ; LEA SI, FORMULA_1
        ; MOV AH,0 ;COLUNA
        ; MOV AL,0  ;LINHA
        ; CALL PRINT_ICON


        ; COLOCA UM PIXEL NA CANTO DIREITO SUPERIOR
        ; Coluna 127, linha 0
        ; MOV AH,127
        ; MOV AL,0
        ; MOV BH,1
        ; CALL GLCD_DRAW_POINT

        ; Coluna 126, linha 1
        ; MOV AH,126
        ; MOV AL,1
        ; MOV BH,1
        ; CALL GLCD_DRAW_POINT

        ; APAGA UM PIXEL NA CANTO DIREITO SUPERIOR
        ; MOV AH,127
        ; MOV AL,0
        ; MOV BH,0
        ; CALL GLCD_DRAW_POINT

        ; APAGA DISPLAY
        ; CALL GLCD_CLR

        ; APONTA PARA CAMINHAO
        ; LEA SI, FORMULA_1
        ; PLOTA CAMINHAO
        ; CALL PLOT_BMP

        ; JMP DEMO


.DATA
GLCD_CONTROL DB 0
GLCD_DATA    DB 0
COL_DATA DB 0
COL_DATA_AUX DB 0
READ_DATA DB 0
LINHA DB 0

QNT_COLUNAS DB 0
SALVA_QNT_COLUNAS DB 0
POS_COLUNAS DB 0

TRUCK 		DB 0,  0,  0,  0,  0,248,  8,  8,  8,  8,  8,  8, 12, 12, 12, 12
          DB       12, 10, 10, 10, 10, 10, 10,  9,  9,  9,  9,  9,  9,  9,  9,  9
          DB       9,  9,  9,  9,  9,  9,  9,  9,  9,  9,137,137,137,137,137,137
          DB       137,137,137,137,137,137,137,  9,  9,  9,  9,  9,  9,  9,  9,  9
          DB       9,  9, 13,253, 13,195,  6,252,  0,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,  0,  0,255,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          DB       240,240,240,240,240,224,224,240,240,240,240,240,224,192,192,224
          DB       240,240,240,240,240,224,192,  0,  0,  0,255,255,255,255,255,195
          DB       195,195,195,195,195,195,  3,  0,  0,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,255,240, 79,224,255, 96, 96, 96, 32, 32, 32, 32, 32
          DB       32, 32, 32, 32, 32, 32, 32, 32, 64, 64, 64, 64,128,  0,  0,  0
          DB       0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,  0,  0,255,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          DB       255,255,255,255,255,  0,  0,  0,  0,255,255,255,255,255,  0,  0
          DB       0,  0,255,255,255,255,255,  0,  0,  0,255,255,255,255,255,129
          DB       129,129,129,129,129,129,128,  0,  0,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,255,  1,248,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8
          DB       8,  8,  8,  8, 16,224, 24, 36,196, 70,130,130,133,217,102,112
          DB       160,192, 96, 96, 32, 32,160,160,224,224,192, 64, 64,128,128,192
          DB       64,128,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,  0,  0, 63, 96, 96, 96,224, 96, 96, 96, 96, 96, 96
          DB       99, 99, 99, 99, 99, 96, 96, 96, 96, 99, 99, 99, 99, 99, 96, 96
          DB       96, 96, 99, 99, 99, 99, 99, 96, 96, 96, 99, 99, 99, 99, 99, 99
          DB       99, 99, 99, 99, 99, 99, 99, 96, 96, 96, 96, 96, 96, 96, 64, 64
          DB       64,224,224,255,246,  1, 14,  6,  6,  2,  2,  2,  2,  2,  2,  2
          DB       2,  2,  2,  2,130, 67,114, 62, 35, 16, 16,  0,  7,  3,  3,  2
          DB       4,  4,  4,  4,  4,  4,  4, 28, 16, 16, 16, 17, 17,  9,  9, 41
          DB       112, 32, 67,  5,240,126,174,128, 56,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1
          DB       1,  1,127,127,127,127,255,255,247,251,123,191, 95, 93,125,189
          DB       189, 63, 93, 89,177,115,243,229,207, 27, 63,119,255,207,191,255
          DB       255,255,255,255,255,255,255,127,127,127,127,127,127,127,127,255
          DB       255,255,127,127,125,120,120,120,120,120,248,120,120,120,120,120
          DB       120,248,248,232,143,  0,  0,  0,  0,  0,  0,  0,  0,128,240,248
          DB       120,188,220, 92,252, 28, 28, 60, 92, 92, 60,120,248,248, 96,192
          DB       143,168,216,136, 49, 68, 72, 50,160, 96,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,128,192,248,248,248,248,252,254,254,254,254,254,254
          DB       254,254,254,254,254,255,255,255,255,255,246,239,208,246,174,173
          DB       169,128,209,208,224,247,249,255,255,252,220,240,127,255,223,255
          DB       255,255,255,255,255,254,254,255,255,255,255,255,255,255,254,255
          DB       255,255,255,255,255,255,254,254,254,254,254,254,254,254,254,254
          DB       254,254,254,254,255,255,255,255,255,255,254,255,190,255,255,253
          DB       240,239,221,223,254,168,136,170,196,208,228,230,248,127,126,156
          DB       223,226,242,242,242,242,242,177, 32,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,  1,  1,  1,  1,  3,  3,  3,  7,  7,  7,  7,  7, 15
          DB       15, 15,  7, 15, 15, 15,  7,  7, 15, 14, 15, 13, 15, 47, 43, 43
          DB       43, 43, 43, 47,111,239,255,253,253,255,254,255,255,255,255,255
          DB       191,191,239,239,239,191,255,191,255,255,255,255,255,255,255,255
          DB       255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
          DB       255,255,255,255,127,127,127,127,255,255,191,191,191,191,255,254
          DB       255,253,255,255,255,251,255,255,255,127,125, 63, 31, 31, 31, 31
          DB       31, 31, 63, 15, 15,  7,  7,  3,  3,  3,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  0
          DB       1,  1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1
          DB       1,  1,  1,  1,  3,  3,  3, 11, 11, 11, 11,  7,  3, 14,  6,  6
          DB       6,  2, 18, 19, 19,  3, 23, 21, 21, 17,  1, 19, 19,  3,  6,  6
          DB       14, 15, 15,  7, 15, 15, 15, 11,  2,  0,  0,  0,  0,  0,  0,  0
          DB       0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0


FONTS  	        DB      32*5 DUP(0)
          DB       00H, 00H, 00H, 00H, 00H                                                           ; (space)
          DB       00H, 00H, 5FH, 00H, 00H                                                           ; !
          DB       00H, 07H, 00H, 07H, 00H                                                           ; "
          DB       14H, 7FH, 14H, 7FH, 14H                                                           ; #
          DB       24H, 2AH, 7FH, 2AH, 12H                                                           ; $
          DB       23H, 13H, 08H, 64H, 62H                                                           ; %
          DB       36H, 49H, 55H, 22H, 50H                                                           ; &
          DB       00H, 05H, 03H, 00H, 00H                                                           ; '
          DB       00H, 1CH, 22H, 41H, 00H                                                           ; (
          DB       00H, 41H, 22H, 1CH, 00H                                                           ; )
          DB       08H, 2AH, 1CH, 2AH, 08H                                                           ; *
          DB       08H, 08H, 3EH, 08H, 08H                                                           ; +
          DB       00H, 50H, 30H, 00H, 00H                                                           ; H,
          DB       08H, 08H, 08H, 08H, 08H                                                           ; -
          DB       00H, 60H, 60H, 00H, 00H                                                           ; .
          DB       20H, 10H, 08H, 04H, 02H                                                           ; /
          DB       3EH, 51H, 49H, 45H, 3EH                                                           ; 0
          DB       00H, 42H, 7FH, 40H, 00H                                                           ; 1
          DB       42H, 61H, 51H, 49H, 46H                                                           ; 2
          DB       21H, 41H, 45H, 4BH, 31H                                                           ; 3
          DB       18H, 14H, 12H, 7FH, 10H                                                           ; 4
          DB       27H, 45H, 45H, 45H, 39H                                                           ; 5
          DB       3CH, 4AH, 49H, 49H, 30H                                                           ; 6
          DB       01H, 71H, 09H, 05H, 03H                                                           ; 7
          DB       36H, 49H, 49H, 49H, 36H                                                           ; 8
          DB       06H, 49H, 49H, 29H, 1EH                                                           ; 9
          DB       00H, 36H, 36H, 00H, 00H                                                           ; :
          DB       00H, 56H, 36H, 00H, 00H                                                           ; ;
          DB       00H, 08H, 14H, 22H, 41H                                                           ; <
          DB       14H, 14H, 14H, 14H, 14H                                                           ; =
          DB       41H, 22H, 14H, 08H, 00H                                                           ; >
          DB       02H, 01H, 51H, 09H, 06H                                                           ; ?
          DB       32H, 49H, 79H, 41H, 3EH                                                           ; @
          DB       7EH, 11H, 11H, 11H, 7EH                                                           ; A
          DB       7FH, 49H, 49H, 49H, 36H                                                           ; B
          DB       3EH, 41H, 41H, 41H, 22H                                                           ; C
          DB       7FH, 41H, 41H, 22H, 1CH                                                           ; D
          DB       7FH, 49H, 49H, 49H, 41H                                                           ; E
          DB       7FH, 09H, 09H, 01H, 01H                                                           ; F
          DB       3EH, 41H, 41H, 51H, 32H                                                           ; G
          DB       7FH, 08H, 08H, 08H, 7FH                                                           ; H
          DB       00H, 41H, 7FH, 41H, 00H                                                           ; I
          DB       20H, 40H, 41H, 3FH, 01H                                                           ; J
          DB       7FH, 08H, 14H, 22H, 41H                                                           ; K
          DB       7FH, 40H, 40H, 40H, 40H                                                           ; L
          DB       7FH, 02H, 04H, 02H, 7FH                                                           ; M
          DB       7FH, 04H, 08H, 10H, 7FH                                                           ; N
          DB       3EH, 41H, 41H, 41H, 3EH                                                           ; O
          DB       7FH, 09H, 09H, 09H, 06H                                                           ; P
          DB       3EH, 41H, 51H, 21H, 5EH                                                           ; Q
          DB       7FH, 09H, 19H, 29H, 46H                                                           ; R
          DB       46H, 49H, 49H, 49H, 31H                                                           ; S
          DB       01H, 01H, 7FH, 01H, 01H                                                           ; T
          DB       3FH, 40H, 40H, 40H, 3FH                                                           ; U
          DB       1FH, 20H, 40H, 20H, 1FH                                                           ; V
          DB       7FH, 20H, 18H, 20H, 7FH                                                           ; W
          DB       63H, 14H, 08H, 14H, 63H                                                           ; X
          DB       03H, 04H, 78H, 04H, 03H                                                           ; Y
          DB       61H, 51H, 49H, 45H, 43H                                                           ; Z
          DB       00H, 00H, 7FH, 41H, 41H                                                           ; [
          DB       02H, 04H, 08H, 10H, 20H                                                           ; "\"
          DB       41H, 41H, 7FH, 00H, 00H                                                           ; ]
          DB       04H, 02H, 01H, 02H, 04H                                                           ; ^
          DB       40H, 40H, 40H, 40H, 40H                                                           ; _
          DB       00H, 01H, 02H, 04H, 00H                                                           ; `
          DB       20H, 54H, 54H, 54H, 78H                                                           ; a
          DB       7FH, 48H, 44H, 44H, 38H                                                           ; b
          DB       38H, 44H, 44H, 44H, 20H                                                           ; c
          DB       38H, 44H, 44H, 48H, 7FH                                                           ; d
          DB       38H, 54H, 54H, 54H, 18H                                                           ; e
          DB       08H, 7EH, 09H, 01H, 02H                                                           ; f
          DB       08H, 14H, 54H, 54H, 3CH                                                           ; g
          DB       7FH, 08H, 04H, 04H, 78H                                                           ; h
          DB       00H, 44H, 7DH, 40H, 00H                                                           ; i
          DB       20H, 40H, 44H, 3DH, 00H                                                           ; j
          DB       00H, 7FH, 10H, 28H, 44H                                                           ; k
          DB       00H, 41H, 7FH, 40H, 00H                                                           ; l
          DB       7CH, 04H, 18H, 04H, 78H                                                           ; m
          DB       7CH, 08H, 04H, 04H, 78H                                                           ; n
          DB       38H, 44H, 44H, 44H, 38H                                                           ; o
          DB       7CH, 14H, 14H, 14H, 08H                                                           ; p
          DB       08H, 14H, 14H, 18H, 7CH                                                           ; q
          DB       7CH, 08H, 04H, 04H, 08H                                                           ; r
          DB       48H, 54H, 54H, 54H, 20H                                                           ; s
          DB       04H, 3FH, 44H, 40H, 20H                                                           ; t
          DB       3CH, 40H, 40H, 20H, 7CH                                                           ; u
          DB       1CH, 20H, 40H, 20H, 1CH                                                           ; v
          DB       3CH, 40H, 30H, 40H, 3CH                                                           ; w
          DB       44H, 28H, 10H, 28H, 44H                                                           ; x
          DB       0CH, 50H, 50H, 50H, 3CH                                                           ; y
          DB       44H, 64H, 54H, 4CH, 44H                                                           ; z
          DB       00H, 08H, 36H, 41H, 00H                                                           ; {
          DB       00H, 00H, 7FH, 00H, 00H                                                           ; |
          DB       00H, 41H, 36H, 08H, 00H                                                           ; }
          DB       08H, 08H, 2AH, 1CH, 08H                                                           ; ->
          DB       08H, 1CH, 2AH, 08H, 08                                                            ; <-

                                                  ; 24X24 (3 LINHAS 3 COLUNAS)
                                                  ; 2 PRIMEIROS BYTES CONSTA NUMERO DE LINHAS E COLUNAS ICONE
                                                  ; CRIADO COM FASTLCD.EXE
BOOK	DB 3,3,00H,00H,00H,0E0H,20H,38H,28H,2EH
          DB       2AH,2AH,2AH,2AH,2AH,2AH,2AH,0EAH
          DB       0AH,0FAH,02H,0FEH,00H,00H,00H,00H
          DB       00H,00H,00H,0FFH,00H,0ABH,2AH,2AH
          DB       0ABH,0AAH,0AAH,0ABH,0ABH,29H,00H,0FFH
          DB       00H,0FFH,00H,0FFH,00H,00H,00H,00H
          DB       00H,00H,00H,7FH,40H,40H,40H,40H
          DB       40H,40H,48H,48H,48H,40H,40H,7FH
          DB       10H,1FH,04H,07H,00H,00H,00H,00H

          ; 24X24 (3 LINHAS 3 COLUNAS)
          ; 2 PRIMEIROS BYTES CONSTA NUMERO DE LINHAS E COLUNAS ICONE
          ; CRIADO COM FASTLCD.EXE
BOOK_OPEN	DB 	3,3,00H,00H,00H,00H,00H,0F8H,08H,0CEH
          DB       8AH,8AH,0CAH,8AH,8AH,0CAH,0CAH,4AH
          DB       0AH,0FAH,02H,0FEH,00H,00H,00H,00H
          DB       48H,24H,82H,0DAH,0CDH,0E5H,76H,0EAH
          DB       1AH,6AH,0AAH,2AH,2AH,2AH,2AH,0AH
          DB       00H,0FFH,00H,0FFH,00H,00H,00H,00H
          DB       0DEH,1FH,0FH,0BH,07H,03H,03H,01H
          DB       30H,18H,18H,03H,06H,0AH,0B2H,50H
          DB       10H,1FH,04H,07H,00H,00H,00H,00H

GUY DB 4,4
          DB       00H,000H,010H,010H,018H,008H,008H,008H,048H,008H,00CH,004H,004H,004H,004H,004H
          DB       04H,004H,004H,004H,044H,004H,004H,004H,00CH,018H,010H,000H,000H,000H,000H,000H
          DB       00H,01CH,036H,022H,062H,042H,040H,000H,000H,000H,000H,000H,000H,0FCH,084H,080H
          DB       00H,000H,000H,000H,000H,000H,000H,000H,000H,000H,008H,008H,004H,004H,004H,0FCH
          DB       00H,000H,000H,000H,000H,004H,004H,01CH,060H,040H,040H,0C0H,080H,080H,080H,080H
          DB       80H,000H,000H,080H,0C0H,070H,01CH,000H,000H,000H,002H,006H,004H,006H,002H,003H
          DB       00H,000H,000H,000H,000H,000H,000H,000H,000H,008H,008H,008H,07CH,01FH,025H,024H
          DB       24H,001H,001H,001H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

CAMINHAO	DB 16,8
DB 		000H,000H,000H,000H,000H,0F8H,008H,008H,008H,008H,008H,008H,00CH,00CH,00CH,00CH
DB 		00CH,00AH,00AH,00AH,00AH,00AH,00AH,009H,009H,009H,009H,009H,009H,009H,009H,009H
DB		009H,009H,009H,009H,009H,009H,009H,009H,009H,009H,089H,089H,089H,089H,089H,089H
DB		089H,089H,089H,089H,089H,089H,089H,009H,009H,009H,009H,009H,009H,009H,009H,009H
DB		009H,009H,00DH,0FDH,00DH,0C3H,006H,0FCH,000H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 		000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,0FFH,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB		0F0H,0F0H,0F0H,0F0H,0F0H,0E0H,0E0H,0F0H,0F0H,0F0H,0F0H,0F0H,0E0H,0C0H,0C0H,0E0H
DB		0F0H,0F0H,0F0H,0F0H,0F0H,0E0H,0C0H,000H,000H,000H,0FFH,0FFH,0FFH,0FFH,0FFH,0C3H
DB		0C3H,0C3H,0C3H,0C3H,0C3H,0C3H,003H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,0FFH,0F0H,04FH,0E0H,0FFH,060H,060H,060H,020H,020H,020H,020H,020H
DB		020H,020H,020H,020H,020H,020H,020H,020H,040H,040H,040H,040H,080H,000H,000H,000H
DB		000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,0FFH,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB		0FFH,0FFH,0FFH,0FFH,0FFH,000H,000H,000H,000H,0FFH,0FFH,0FFH,0FFH,0FFH,000H,000H
DB		000H,000H,0FFH,0FFH,0FFH,0FFH,0FFH,000H,000H,000H,0FFH,0FFH,0FFH,0FFH,0FFH,081H
DB		081H,081H,081H,081H,081H,081H,080H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,0FFH,001H,0F8H,008H,008H,008H,008H,008H,008H,008H,008H,008H,008H
DB		008H,008H,008H,008H,010H,0E0H,018H,024H,0C4H,046H,082H,082H,085H,0D9H,066H,070H
DB		0A0H,0C0H,060H,060H,020H,020H,0A0H,0A0H,0E0H,0E0H,0C0H,040H,040H,080H,080H,0C0H
DB		040H,080H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,03FH,060H,060H,060H,0E0H,060H,060H,060H,060H,060H,060H
DB		063H,063H,063H,063H,063H,060H,060H,060H,060H,063H,063H,063H,063H,063H,060H,060H
DB		060H,060H,063H,063H,063H,063H,063H,060H,060H,060H,063H,063H,063H,063H,063H,063H
DB		063H,063H,063H,063H,063H,063H,063H,060H,060H,060H,060H,060H,060H,060H,040H,040H
DB		040H,0E0H,0E0H,0FFH,0F6H,001H,00EH,006H,006H,002H,002H,002H,002H,002H,002H,002H
DB		002H,002H,002H,002H,082H,043H,072H,03EH,023H,010H,010H,000H,007H,003H,003H,002H
DB		004H,004H,004H,004H,004H,004H,004H,01CH,010H,010H,010H,011H,011H,009H,009H,029H
DB		070H,020H,043H,005H,0F0H,07EH,0AEH,080H,038H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,000H,000H,000H,000H,001H,001H,001H,001H,001H,001H,001H
DB		001H,001H,07FH,07FH,07FH,07FH,0FFH,0FFH,0F7H,0FBH,07BH,0BFH,05FH,05DH,07DH,0BDH
DB		0BDH,03FH,05DH,059H,0B1H,073H,0F3H,0E5H,0CFH,01BH,03FH,077H,0FFH,0CFH,0BFH,0FFH
DB		0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,07FH,07FH,07FH,07FH,07FH,07FH,07FH,07FH,0FFH
DB		0FFH,0FFH,07FH,07FH,07DH,078H,078H,078H,078H,078H,0F8H,078H,078H,078H,078H,078H
DB		078H,0F8H,0F8H,0E8H,08FH,000H,000H,000H,000H,000H,000H,000H,000H,080H,0F0H,0F8H
DB		078H,0BCH,0DCH,05CH,0FCH,01CH,01CH,03CH,05CH,05CH,03CH,078H,0F8H,0F8H,060H,0C0H
DB		08FH,0A8H,0D8H,088H,031H,044H,048H,032H,0A0H,060H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,080H,0C0H,0F8H,0F8H,0F8H,0F8H,0FCH,0FEH,0FEH,0FEH,0FEH,0FEH,0FEH
DB		0FEH,0FEH,0FEH,0FEH,0FEH,0FFH,0FFH,0FFH,0FFH,0FFH,0F6H,0EFH,0D0H,0F6H,0AEH,0ADH
DB		0A9H,080H,0D1H,0D0H,0E0H,0F7H,0F9H,0FFH,0FFH,0FCH,0DCH,0F0H,07FH,0FFH,0DFH,0FFH
DB		0FFH,0FFH,0FFH,0FFH,0FFH,0FEH,0FEH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FEH,0FFH
DB		0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FEH,0FEH,0FEH,0FEH,0FEH,0FEH,0FEH,0FEH,0FEH,0FEH
DB		0FEH,0FEH,0FEH,0FEH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FEH,0FFH,0BEH,0FFH,0FFH,0FDH
DB		0F0H,0EFH,0DDH,0DFH,0FEH,0A8H,088H,0AAH,0C4H,0D0H,0E4H,0E6H,0F8H,07FH,07EH,09CH
DB		0DFH,0E2H,0F2H,0F2H,0F2H,0F2H,0F2H,0B1H,020H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,001H,001H,001H,001H,003H,003H,003H,007H,007H,007H,007H,007H,00FH
DB		00FH,00FH,007H,00FH,00FH,00FH,007H,007H,00FH,00EH,00FH,00DH,00FH,02FH,02BH,02BH
DB		02BH,02BH,02BH,02FH,06FH,0EFH,0FFH,0FDH,0FDH,0FFH,0FEH,0FFH,0FFH,0FFH,0FFH,0FFH
DB		0BFH,0BFH,0EFH,0EFH,0EFH,0BFH,0FFH,0BFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
DB		0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
DB		0FFH,0FFH,0FFH,0FFH,07FH,07FH,07FH,07FH,0FFH,0FFH,0BFH,0BFH,0BFH,0BFH,0FFH,0FEH
DB		0FFH,0FDH,0FFH,0FFH,0FFH,0FBH,0FFH,0FFH,0FFH,07FH,07DH,03FH,01FH,01FH,01FH,01FH
DB		01FH,01FH,03FH,00FH,00FH,007H,007H,003H,003H,003H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,001H,001H,000H
DB		001H,001H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,001H,001H,001H,001H
DB		001H,001H,001H,001H,003H,003H,003H,00BH,00BH,00BH,00BH,007H,003H,00EH,006H,006H
DB		006H,002H,012H,013H,013H,003H,017H,015H,015H,011H,001H,013H,013H,003H,006H,006H
DB		00EH,00FH,00FH,007H,00FH,00FH,00FH,00BH,002H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

FLECHA		DB 4,4
DB		001H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB	 	000H,000H,000H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H
DB		0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0F8H,0F0H,0E0H,0C0H,080H,000H,000H,000H
DB		000H,000H,000H,003H,003H,003H,003H,003H,003H,003H,003H,003H,003H,003H,003H,003H
DB		003H,003H,003H,003H,003H,003H,003H,003H,00FH,007H,003H,001H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB		000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H



; N?vel 1
NIVEL_1 	DB 16,8
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,040H,040H,080H,000H,000H,000H,000H,040H,040H,040H,040H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,020H,020H,020H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,040H,040H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,002H,002H,002H,000H,000H,000H,000H,000H,000H,000H,000H,002H,002H,002H
DB 			002H,000H,000H,000H,002H,002H,002H,002H,000H,000H,000H,020H,020H,022H,022H,022H
DB 			022H,020H,020H,020H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,002H,002H,002H,000H,000H,000H,000H,001H,000H,000H,000H,000H
DB 			000H,000H,002H,002H,002H,002H,002H,002H,002H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,002H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,002H,002H
DB 			002H,002H,000H,000H,000H,000H,000H,000H,000H,002H,002H,002H,002H,002H,002H,002H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,002H,002H,002H,002H,002H,002H,002H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

; Opera??es
OPERACOES 	DB 16,8
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,080H,080H,080H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,040H,000H,080H,080H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,002H,088H,000H,000H,002H
DB 			002H,000H,000H,000H,000H,000H,000H,024H,022H,022H,022H,022H,020H,020H,000H,000H
DB 			000H,000H,000H,002H,008H,000H,000H,002H,002H,000H,000H,000H,000H,000H,022H,022H
DB 			022H,020H,020H,000H,000H,000H,000H,000H,000H,000H,002H,002H,002H,000H,004H,000H
DB 			000H,000H,000H,000H,000H,002H,002H,002H,000H,000H,000H,000H,000H,000H,024H,022H
DB 			022H,022H,022H,020H,020H,000H,000H,000H,000H,000H,000H,012H,012H,012H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,002H,002H,002H,000H,000H,000H,000H,000H,020H,020H,020H,000H,002H
DB 			002H,000H,000H,000H,000H,000H,000H,000H,000H,002H,002H,002H,002H,000H,000H,000H
DB 			000H,000H,002H,002H,002H,002H,002H,002H,000H,000H,000H,000H,000H,000H,002H,002H
DB 			002H,000H,001H,002H,000H,000H,000H,000H,000H,000H,022H,022H,002H,002H,000H,000H
DB 			000H,000H,000H,000H,000H,002H,002H,002H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			002H,002H,002H,002H,000H,000H,000H,000H,000H,001H,000H,002H,002H,002H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

; OSSO
OSSO DB 2, 1
        DB              	07EH,0D3H,083H,042H,064H,024H,024H,024H,024H,024H,024H,064H,042H,083H,0D3H,07EH

RETANGULO_FUNDO_NUMEROS DB 8,4
DB 			0FFH,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H
DB 			001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H
DB 			001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H
DB 			001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,001H,0FFH,0FFH
DB 			0FFH,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,0FFH
DB 			0FFH,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB 			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,0FFH
DB 			0FFH,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H
DB 			080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H
DB 			080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H
DB 			080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,080H,0FFH

SINAL_MAIS 	DB 2,2
DB 		 	0FFH,0FFH,003H,083H,083H,083H,083H,0F3H,0F3H,083H,083H,083H,083H,003H,0FFH,0FFH
DB 		 	0FFH,0FFH,0C0H,0C1H,0C1H,0C1H,0C1H,0CFH,0CFH,0C1H,0C1H,0C1H,0C1H,0C0H,0FFH,0FFH

SINAL_MAIS_PREENCHIDO 	DB 2,2
DB						00FFH,00FFH,00FFH,007FH,007FH,007FH,007FH,0007H,0007H,007FH,007FH,007FH,007FH,00FFH,00FFH,00FFH
DB						00FFH,00FFH,00FFH,00FEH,00FEH,00FEH,00FEH,00E0H,00E0H,00FEH,00FEH,00FEH,00FEH,00FFH,00FFH,00FFH

SINAL_MENOS	DB 2,2
DB 		 	0FFH,0FFH,003H,003H,083H,083H,083H,083H,083H,083H,083H,083H,003H,003H,0FFH,0FFH
DB 		 	0FFH,0FFH,0C0H,0C0H,0C1H,0C1H,0C1H,0C1H,0C1H,0C1H,0C1H,0C1H,0C0H,0C0H,0FFH,0FFH

SINAL_MENOS_PREENCHIDO DB 2,2
DB 			0FFH,0FFH,0FFH,07FH,07FH,07FH,07FH,07FH,07FH,07FH,07FH,07FH,07FH,0FFH,0FFH,0FFH
DB 			0FFH,0FFH,0FFH,0FEH,0FEH,0FEH,0FEH,0FEH,0FEH,0FEH,0FEH,0FEH,0FEH,0FFH,0FFH,0FFH

VERT 		DB 16,8
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,0FCH,0FFH,0FFH,0FFH,0FFH
DB			0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
DB			0FFH,0FFH,0FFH,07FH,07FH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0E0H,0E7H
DB			07CH,060H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,01CH,03EH,00FH,00FH,00FH,0FFH,0FFH,01FH
DB			003H,007H,007H,07FH,07FH,01FH,007H,007H,007H,003H,083H,083H,083H,081H,081H,081H
DB			080H,080H,000H,000H,000H,03FH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,063H,07FH,0FFH,0E1H
DB			0C0H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,0FFH,0FFH,03FH
DB			07FH,0FFH,09FH,01EH,0FEH,07EH,000H,0CEH,0FFH,0FFH,07FH,07FH,07FH,07FH,04FH,04FH
DB			00FH,01FH,01FH,01FH,006H,000H,0E1H,0FFH,0FFH,0FFH,07FH,013H,000H,0C0H,0F8H,01FH
DB			003H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,01FH,07FH
DB			0F8H,0E0H,000H,000H,000H,080H,0C0H,0DFH,0CFH,040H,060H,000H,000H,000H,000H,000H
DB			000H,000H,0C0H,0F0H,0FEH,0FFH,0EFH,00FH,007H,003H,0FFH,0FEH,0FEH,007H,003H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			001H,007H,01FH,0FCH,0ECH,0ECH,067H,06FH,06EH,06EH,06AH,06CH,02CH,00EH,000H,000H
DB			080H,0F0H,0FFH,0FFH,0FFH,0FFH,0FFH,000H,000H,000H,0FFH,0FFH,0FFH,0F8H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,0C0H,0E0H,0E0H,0E0H,0E0H,040H,040H,040H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,080H,0C0H,0E0H
DB			0F0H,0B8H,0BCH,0FFH,0FFH,0FFH,0FCH,0F0H,0F8H,0C0H,0F0H,0D0H,0B8H,0BCH,01EH,00FH
DB			00FH,08FH,00FH,00FH,08FH,087H,0C0H,0C0H,0E0H,0E0H,0F3H,0FFH,0FFH,01FH,030H,0E0H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
DB			000H,001H,0FFH,0FFH,0DFH,0DFH,027H,006H,007H,01CH,0BCH,0F8H,078H,0F0H,0F0H,0E0H
DB			0E0H,060H,060H,0E0H,060H,0C0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,060H,0E0H,0E0H,0E0H
DB			0F0H,0F0H,070H,038H,0F8H,0FCH,0FEH,0F7H,0E3H,0C3H,007H,007H,00FH,0BFH,0FFH,07FH
DB			0FFH,0FFH,0FFH,0FFH,0FEH,0FDH,0FBH,0C7H,0CFH,01FH,04FH,02FH,00FH,02FH,05FH,08FH
DB			008H,088H,08CH,01FH,07FH,0FFH,0FFH,0FFH,0FFH,01FH,0B7H,03BH,07CH,0FCH,0FCH,0FFH
DB			0FFH,0FEH,0FEH,0E6H,087H,003H,003H,007H,01EH,0FCH,0E0H,000H,000H,000H,000H,000H
DB			080H,080H,080H,0C0H,0C0H,040H,060H,0A0H,0A0H,0B0H,0F8H,0F8H,0DCH,0DCH,01CH,0FCH
DB			0FEH,0FEH,0BEH,03EH,01EH,080H,080H,0C0H,0C0H,0C0H,0C0H,080H,000H,000H,000H,000H
DB			000H,000H,03CH,07FH,07FH,0FFH,0FAH,0F0H,0F6H,0ECH,0E0H,0E0H,004H,040H,000H,032H
DB			06BH,067H,047H,0C7H,087H,08FH,02FH,0FFH,0FFH,0FFH,0FFH,0F3H,0F3H,0F7H,0F7H,0FFH
DB			0FFH,07FH,07FH,02FH,00FH,007H,007H,03FH,01FH,037H,027H,017H,016H,003H,0E1H,0D0H
DB			096H,0D0H,043H,047H,0E7H,0E7H,00FH,092H,048H,040H,000H,040H,020H,000H,088H,04CH
DB			000H,082H,012H,0A0H,006H,0CAH,0CEH,01EH,00AH,000H,011H,060H,0C2H,000H,006H,070H
DB			0C3H,003H,001H,01CH,003H,01EH,07CH,0FEH,0FFH,0FFH,0FFH,0FEH,0FFH,0EDH,0FFH,0EFH
DB			0FFH,07EH,066H,006H,01FH,09FH,03FH,09FH,03FH,08FH,0EFH,043H,063H,04DH,07FH,07FH
DB			007H,019H,08BH,09BH,0BBH,0B3H,0D3H,0C3H,0F3H,0F8H,078H,00FH,006H,006H,000H,00FH

; CARRO FRAME 1
CARRO_FRAME1 DB 16, 4
        DB 	000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,080H,080H,080H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,0F8H,0FEH,0FEH,0FEH
        DB 	0F8H,038H,000H,000H,018H,018H,038H,018H
        DB 	018H,018H,038H,038H,038H,018H,018H,038H
        DB 	038H,078H,078H,080H,000H,080H,0C0H,0C0H
        DB 	080H,080H,080H,000H,000H,000H,000H,000H
        DB 	000H,080H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H
        DB 	0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,060H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,080H,080H
        DB 	040H,040H,040H,040H,0C0H,0E0H,0E0H,0E0H
        DB 	0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H
        DB 	0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0F8H
        DB 	0FCH,0E2H,0E3H,0E1H,0FDH,0FDH,0FDH,0E1H
        DB 	0E1H,0E1H,0E1H,0E1H,0FAH,0FEH,0FFH,0FFH
        DB 	07EH,0FEH,0FEH,0FCH,0E3H,0E5H,0FFH,0FFH
        DB 	0FFH,0FEH,0FCH,0FCH,0FCH,07EH,07EH,07EH
        DB 	07CH,07CH,07CH,0FCH,0FCH,0FCH,0FCH,0F8H
        DB 	0F8H,0E0H,0E0H,0E2H,0C6H,0DCH,09FH,0FFH
        DB 	0FFH,0FFH,0FFH,0FFH,0FFH,0FEH,0FEH,0FEH
        DB 	0FEH,0FFH,0FFH,0FFH,0FFH,0C3H,0C3H,0DBH
        DB 	09FH,09FH,087H,003H,003H,0E1H,0E0H,0E0H
        DB 	0F8H,0F8H,03CH,01EH,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,080H,080H,080H,0C0H,0E0H,0E0H,0E0H
        DB 	0E0H,0C0H,0F8H,0FEH,0FFH,0BFH,007H,0E2H
        DB 	03AH,0FEH,0FAH,0FAH,0E6H,01FH,0FDH,0E3H
        DB 	03FH,0FFH,0FFH,0FFH,0FFH,0FFH,0BFH,01FH
        DB 	03FH,03FH,07FH,0FFH,0FFH,0FFH,0FFH,0FFH
        DB 	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
        DB 	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,07FH
        DB 	000H,000H,000H,005H,007H,0FFH,007H,03FH
        DB 	003H,081H,081H,003H,0BFH,001H,01FH,01EH
        DB 	03EH,03EH,01EH,01EH,006H,002H,000H,004H
        DB 	0FCH,0FCH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
        DB 	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
        DB 	0FFH,0FFH,0FFH,01FH,0E3H,0F9H,0FCH,0FEH
        DB 	07EH,0FAH,0E2H,006H,01EH,0FCH,0F9H,007H
        DB 	003H,001H,000H,000H,000H,000H,000H,000H
        DB 	000H,039H,020H,021H,023H,021H,020H,020H
        DB 	020H,021H,03BH,021H,021H,038H,003H,003H
        DB 	003H,003H,007H,01FH,03FH,07FH,07CH,0FBH
        DB 	0FAH,0FAH,0FAH,0FAH,0FDH,0FEH,07FH,03FH
        DB 	01FH,007H,003H,003H,001H,000H,006H,01FH
        DB 	01FH,01EH,01EH,01FH,01FH,01FH,01FH,01FH
        DB 	01FH,007H,007H,007H,007H,01FH,01FH,01FH
        DB 	01FH,01FH,01FH,01FH,01FH,01FH,01FH,006H
        DB 	004H,004H,004H,006H,004H,004H,006H,007H
        DB 	004H,004H,004H,004H,007H,004H,004H,004H
        DB 	006H,006H,004H,006H,006H,006H,006H,006H
        DB 	007H,007H,007H,007H,003H,003H,003H,007H
        DB 	007H,007H,007H,007H,007H,007H,007H,007H
        DB 	007H,01FH,03FH,07EH,07FH,0FFH,0FFH,0FBH
        DB 	0FBH,0E3H,0FBH,0F8H,07CH,03FH,01FH,003H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H

; CARRO FRAME 2
CARRO_FRAME2 DB 16,4
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	080H,080H,080H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	0F8H,0FEH,0FEH,0FEH,0F8H,038H,000H,000H,018H,018H,038H,018H,018H,018H,038H,038H
        DB 	038H,018H,018H,038H,038H,078H,078H,080H,000H,080H,0C0H,0C0H,080H,080H,080H,000H
        DB 	000H,000H,000H,000H,000H,080H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H
        DB 	0E0H,0E0H,0E0H,060H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,080H,080H,040H,040H,040H,040H,0C0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H
        DB 	0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0F8H,0FCH,0E2H,0E3H,0E1H
        DB 	0FDH,0FDH,0FDH,0E1H,0E1H,0E1H,0E1H,0E1H,0FAH,0FEH,0FFH,0FFH,07EH,0FEH,0FEH,0FCH
        DB 	0E3H,0E5H,0FFH,0FFH,0FFH,0FEH,0FCH,0FCH,0FCH,07EH,07EH,07EH,07CH,07CH,07CH,0FCH
        DB 	0FCH,0FCH,0FCH,0F8H,0F8H,0E0H,0E0H,0E2H,0C6H,0DCH,09FH,0FFH,0FFH,0FFH,0FFH,0FFH
        DB 	0FFH,0FEH,0FEH,0FEH,0FEH,0FFH,0FFH,0FFH,0FFH,0C3H,0C3H,0DBH,09FH,09FH,087H,003H
        DB 	003H,0E1H,0E0H,0E0H,0F8H,0F8H,03CH,01EH,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	0FFH,0BFH,007H,0E2H,03AH,0FEH,0FAH,0FAH,0E6H,01FH,0FDH,0E3H,03FH,0FFH,0FFH,0FFH
        DB 	0FFH,0FFH,0BFH,01FH,03FH,03FH,07FH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
        DB 	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,07FH,000H,000H,000H,005H
        DB 	007H,0FFH,007H,03FH,003H,081H,081H,003H,0BFH,001H,01FH,01EH,03EH,03EH,01EH,01EH
        DB 	006H,002H,000H,004H,0FCH,0FCH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
        DB 	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,01FH,0E3H,0F9H,0FCH,0FEH,07EH,0FAH,0E2H,006H
        DB 	01EH,0FCH,0F9H,007H,003H,001H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	03FH,07FH,07CH,0FBH,0FAH,0FAH,0FAH,0FAH,0FDH,0FEH,07FH,03FH,01FH,007H,003H,003H
        DB 	001H,000H,006H,01FH,01FH,01EH,01EH,01FH,01FH,01FH,01FH,01FH,01FH,007H,007H,007H
        DB 	007H,01FH,01FH,01FH,01FH,01FH,01FH,01FH,01FH,01FH,01FH,006H,004H,004H,004H,006H
        DB 	004H,004H,006H,007H,004H,004H,004H,004H,007H,004H,004H,004H,006H,006H,004H,006H
        DB 	006H,006H,006H,006H,007H,007H,007H,007H,003H,003H,003H,007H,007H,007H,007H,007H
        DB 	007H,007H,007H,007H,007H,01FH,03FH,07EH,07FH,0FFH,0FFH,0FBH,0FBH,0E3H,0FBH,0F8H
        DB 	07CH,03FH,01FH,003H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

; CARRO FRAME 3
CARRO_FRAME3  DB 16, 4
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,080H,080H,080H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,0F8H,0FEH,0FEH,0FEH
	DB 	0F8H,038H,000H,000H,018H,018H,038H,018H,018H,018H,038H,038H,038H,018H,018H,038H
	DB 	038H,078H,078H,080H,000H,080H,0C0H,0C0H,080H,080H,080H,000H,000H,000H,000H,000H
	DB 	000H,080H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,060H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0F8H,0FCH,0E2H,0E3H,0E1H,0FDH,0FDH,0FDH,0E1H
	DB 	0E1H,0E1H,0E1H,0E1H,0FAH,0FEH,0FFH,0FFH,07EH,0FEH,0FEH,0FCH,0E3H,0E5H,0FFH,0FFH
	DB 	0FFH,0FEH,0FCH,0FCH,0FCH,07EH,07EH,07EH,07CH,07CH,07CH,0FCH,0FCH,0FCH,0FCH,0F8H
	DB 	0F8H,0E0H,0E0H,0E2H,0C6H,0DCH,09FH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FEH,0FEH,0FEH
	DB 	0FEH,0FFH,0FFH,0FFH,0FFH,0C3H,0C3H,0DBH,09FH,09FH,087H,003H,003H,0E1H,0E0H,0E0H
	DB 	0F8H,0F8H,03CH,01EH,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	03FH,03FH,07FH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
	DB 	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,07FH,000H,000H,000H,005H,007H,0FFH,007H,03FH
	DB 	003H,081H,081H,003H,0BFH,001H,01FH,01EH,03EH,03EH,01EH,01EH,006H,002H,000H,004H
	DB 	0FCH,0FCH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
	DB 	0FFH,0FFH,0FFH,01FH,0E3H,0F9H,0FCH,0FEH,07EH,0FAH,0E2H,006H,01EH,0FCH,0F9H,007H
	DB 	003H,001H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	01FH,01EH,01EH,01FH,01FH,01FH,01FH,01FH,01FH,007H,007H,007H,007H,01FH,01FH,01FH
	DB 	01FH,01FH,01FH,01FH,01FH,01FH,01FH,006H,004H,004H,004H,006H,004H,004H,006H,007H
	DB 	004H,004H,004H,004H,007H,004H,004H,004H,006H,006H,004H,006H,006H,006H,006H,006H
	DB 	007H,007H,007H,007H,003H,003H,003H,007H,007H,007H,007H,007H,007H,007H,007H,007H
	DB 	007H,01FH,03FH,07EH,07FH,0FFH,0FFH,0FBH,0FBH,0E3H,0FBH,0F8H,07CH,03FH,01FH,003H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

; CARRO FRAME 4

CARRO_FRAME4 DB 16, 4
	DB 	000H,000H,000H,000H,0F8H,0FEH,0FEH,0FEH,0F8H,038H,000H,000H,018H,018H,038H,018H
	DB 	018H,018H,038H,038H,038H,018H,018H,038H,038H,078H,078H,080H,000H,080H,0C0H,0C0H
	DB 	080H,080H,080H,000H,000H,000H,000H,000H,000H,080H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H
	DB 	0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,060H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	07EH,0FEH,0FEH,0FCH,0E3H,0E5H,0FFH,0FFH,0FFH,0FEH,0FCH,0FCH,0FCH,07EH,07EH,07EH
	DB 	07CH,07CH,07CH,0FCH,0FCH,0FCH,0FCH,0F8H,0F8H,0E0H,0E0H,0E2H,0C6H,0DCH,09FH,0FFH
	DB 	0FFH,0FFH,0FFH,0FFH,0FFH,0FEH,0FEH,0FEH,0FEH,0FFH,0FFH,0FFH,0FFH,0C3H,0C3H,0DBH
	DB 	09FH,09FH,087H,003H,003H,0E1H,0E0H,0E0H,0F8H,0F8H,03CH,01EH,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,005H,007H,0FFH,007H,03FH,003H,081H,081H,003H,0BFH,001H,01FH,01EH
	DB 	03EH,03EH,01EH,01EH,006H,002H,000H,004H,0FCH,0FCH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
	DB 	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,01FH,0E3H,0F9H,0FCH,0FEH
	DB 	07EH,0FAH,0E2H,006H,01EH,0FCH,0F9H,007H,003H,001H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	004H,004H,004H,006H,004H,004H,006H,007H,004H,004H,004H,004H,007H,004H,004H,004H
	DB 	006H,006H,004H,006H,006H,006H,006H,006H,007H,007H,007H,007H,003H,003H,003H,007H
	DB 	007H,007H,007H,007H,007H,007H,007H,007H,007H,01FH,03FH,07EH,07FH,0FFH,0FFH,0FBH
	DB 	0FBH,0E3H,0FBH,0F8H,07CH,03FH,01FH,003H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

; CARRO FRAME 5
CARRO_FRAME5 DB 16, 4
	DB 	038H,018H,018H,038H,038H,078H,078H,080H,000H,080H,0C0H,0C0H,080H,080H,080H,000H
	DB 	000H,000H,000H,000H,000H,080H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H
	DB 	0E0H,0E0H,0E0H,060H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	0FCH,0FCH,0FCH,0F8H,0F8H,0E0H,0E0H,0E2H,0C6H,0DCH,09FH,0FFH,0FFH,0FFH,0FFH,0FFH
	DB 	0FFH,0FEH,0FEH,0FEH,0FEH,0FFH,0FFH,0FFH,0FFH,0C3H,0C3H,0DBH,09FH,09FH,087H,003H
	DB 	003H,0E1H,0E0H,0E0H,0F8H,0F8H,03CH,01EH,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	006H,002H,000H,004H,0FCH,0FCH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
	DB 	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,01FH,0E3H,0F9H,0FCH,0FEH,07EH,0FAH,0E2H,006H
	DB 	01EH,0FCH,0F9H,007H,003H,001H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	006H,006H,006H,006H,007H,007H,007H,007H,003H,003H,003H,007H,007H,007H,007H,007H
	DB 	007H,007H,007H,007H,007H,01FH,03FH,07EH,07FH,0FFH,0FFH,0FBH,0FBH,0E3H,0FBH,0F8H
	DB 	07CH,03FH,01FH,003H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

; CARRO FRAME 6
CARRO_FRAME6 DB 16, 4
	DB 	000H,000H,000H,000H,080H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H
	DB 	0E0H,0E0H,060H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	0FEH,0FEH,0FEH,0FEH,0FFH,0FFH,0FFH,0FFH,0C3H,0C3H,0DBH,09FH,09FH,087H,003H,003H
	DB 	0E1H,0E0H,0E0H,0F8H,0F8H,03CH,01EH,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,01FH,0E3H,0F9H,0FCH,0FEH,07EH,0FAH,0E2H,006H,01EH
	DB 	0FCH,0F9H,007H,003H,001H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	007H,007H,007H,007H,01FH,03FH,07EH,07FH,0FFH,0FFH,0FBH,0FBH,0E3H,0FBH,0F8H,07CH
	DB 	03FH,01FH,003H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

; CARRO FRAME 7
CARRO_FRAME7 DB 16,4
	DB 	0E0H,0E0H,060H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	0E1H,0E0H,0E0H,0F8H,0F8H,03CH,01EH,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	0FCH,0F9H,007H,003H,001H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	03FH,01FH,003H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H   

; CARRO CLEAR
CARRO_CLEAR DB 16,4
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

; Mais e menos
MAIS_E_MENOS DB 6, 3
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,0F0H,098H,0F8H,0F8H,0F0H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,03CH,03EH,03AH,03AH,03AH,03AH,03EH,0FFH,0FFH,0FFH,0FFH,0FFH,03EH
        DB 	03EH,03EH,03EH,03EH,03CH,000H,000H,000H,000H,000H,000H,000H,000H,03EH,03EH,03AH
        DB 	03AH,03AH,03AH,03EH,03EH,03EH,03EH,03EH,03EH,03EH,03EH,03EH,03EH,03EH,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,007H,00FH,00FH,00FH,007H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

; Resposta - NOTA 10
NOTA_10 DB 16, 8
	DB 	000H,000H,000H,0C0H,0E0H,060H,070H,070H,070H,070H,070H,070H,070H,070H,070H,070H
	DB 	070H,070H,070H,070H,070H,070H,070H,070H,070H,070H,070H,070H,070H,070H,070H,070H
	DB 	070H,070H,070H,070H,070H,070H,070H,070H,070H,070H,070H,060H,0E0H,0C0H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,080H,080H,000H
	DB 	000H,080H,080H,000H,000H,002H,080H,004H,000H,000H,000H,020H,080H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,0FFH,0FFH,0FFH,000H,000H,000H,000H,000H,000H,000H,000H,030H,010H,018H
	DB 	0F8H,0FCH,0FCH,000H,000H,000H,000H,000H,000H,0E0H,0F0H,038H,008H,00CH,008H,038H
	DB 	0F0H,0E0H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,0FFH,0FFH,0FFH,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,008H,03EH,07FH,00FH,003H,000H
	DB 	000H,001H,021H,000H,000H,000H,021H,081H,080H,000H,004H,038H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,0FFH,0FFH,0FFH,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	0FFH,0FFH,0FFH,000H,000H,000H,000H,000H,007H,03FH,07FH,0E0H,080H,080H,080H,0E0H
	DB 	07FH,03FH,007H,000H,000H,000H,000H,000H,000H,000H,000H,000H,0FFH,0FFH,0FFH,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,018H,000H,000H,000H,000H
	DB 	000H,001H,000H,080H,080H,050H,040H,040H,020H,020H,000H,000H,030H,006H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,00FH,03FH,07FH,060H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H
	DB 	0E1H,0E1H,0E1H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E1H,0E0H,0E0H
	DB 	0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,060H,07FH,03FH,00FH,000H
	DB 	000H,000H,000H,000H,000H,000H,010H,090H,0B0H,0A0H,040H,040H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,080H,0C0H,080H,030H,078H,0F0H
	DB 	0C0H,080H,080H,020H,060H,020H,020H,030H,010H,010H,018H,000H,0CFH,0FEH,0F8H,0E0H
	DB 	080H,000H,080H,0C0H,0C0H,080H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,060H,0C0H,080H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,020H,020H,030H,018H,084H,0C3H,0E0H,0F0H,0FCH,0FEH,0FFH,0FFH,0FFH
	DB 	0FFH,0FFH,0FFH,0FEH,0FEH,0F8H,000H,000H,0FFH,0FCH,000H,000H,001H,003H,003H,006H
	DB 	004H,00DH,019H,011H,033H,02FH,00EH,01EH,01EH,01EH,03EH,03FH,07FH,0BFH,09FH,04FH
	DB 	023H,018H,00FH,003H,001H,003H,007H,00FH,01CH,030H,0E0H,080H,010H,0F0H,0F1H,0E2H
	DB 	080H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,010H,030H,020H,060H,0E0H,0C0H,0C0H,0C1H,0C3H,0FEH,0FEH
	DB 	0FCH,0F8H,0F8H,0F0H,0E0H,0C0H,080H,000H,000H,080H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,080H,0E0H,0F3H,0F3H,0F3H,0F3H,0F3H,0F3H,0E3H,0E3H,0C3H,083H,087H,07FH
	DB 	0FFH,0FFH,0FFH,0FFH,0FFH,001H,000H,0C0H,0FBH,0CFH,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,008H,0C1H,000H,070H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,020H,001H,001H,027H,0FFH,07FH
	DB 	01FH,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,001H,003H,003H,007H,00FH,03FH,07FH
	DB 	0FFH,0FFH,07FH,07FH,07FH,0FFH,0FFH,0FFH,0BFH,03FH,01FH,01EH,004H,04CH,018H,038H
	DB 	070H,0E2H,0C7H,09FH,0FFH,0FFH,08FH,007H,073H,0DBH,09BH,093H,037H,04FH,01FH,00FH
	DB 	00FH,01FH,03FH,07FH,0FFH,0FCH,0F0H,0C7H,01FH,03EH,0E0H,0C0H,080H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,080H,080H,080H,080H,080H,0C0H,0FFH,000H,000H
	DB 	07FH,0E0H,0C0H,0C0H,0C0H,0C0H,080H,081H,082H,086H,086H,081H,080H,0E0H,0FEH,0F8H
	DB 	080H,080H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,000H,000H,00FH,03FH,07FH,0FFH,0FFH,0F0H,000H,080H,0C1H,0C4H
	DB 	0E8H,0E4H,0F3H,0F9H,07FH,03FH,01FH,00FH,000H,001H,003H,000H,000H,000H,000H,000H
	DB 	000H,000H,000H,000H,001H,001H,00FH,01FH,03FH,07EH,07CH,079H,0E3H,0C3H,087H,087H
	DB 	027H,067H,013H,013H,023H,003H,003H,011H,071H,0D9H,0D9H,058H,0D8H,0C8H,0F8H,0F8H
	DB 	088H,0C8H,048H,0C8H,048H,018H,000H,041H,031H,099H,0C1H,0D3H,0E9H,0E6H,0F8H,0F8H
	DB 	0FFH,0E1H,0C0H,078H,0F8H,0F8H,0F8H,0F8H,0F8H,0FCH,0FCH,07CH,07CH,07CH,03CH,0BCH

MAOFRAME0 DB 16, 8
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,002H,000H,004H,000H,000H,000H,000H,040H,040H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,020H,0F8H,0F8H,0F8H,0FCH,03EH,00EH,000H,000H,006H,086H,000H
        DB 	000H,000H,000H,086H,004H,000H,000H,010H,010H,0E0H,0E0H,002H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,0C1H,0C1H,0C1H,003H,000H,000H,000H,000H,008H,001H,000H
        DB 	000H,000H,000H,001H,004H,004H,000H,000H,000H,001H,001H,000H,030H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,001H,001H,001H,000H,000H,000H,000H,000H,000H,000H,010H
        DB 	010H,010H,00DH,00CH,00CH,002H,002H,000H,000H,000H,000H,0E3H,0C0H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,002H,012H,0F6H
        DB 	014H,008H,008H,008H,008H,000H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,000H,000H,000H
        DB 	000H,000H,0E0H,000H,010H,018H,018H,018H,0F0H,0E6H,0EFH,01EH,018H,0F0H,0F0H,0E4H
        DB 	0E4H,0ECH,0E4H,004H,006H,002H,002H,003H,003H,0E0H,0E0H,0F9H,0FFH,0FFH,0FCH,0F0H
        DB 	000H,0F0H,0F8H,0F8H,0F8H,0F0H,0E0H,0E0H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	0E0H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,010H,090H,098H,08CH,0C2H,0E1H
        DB 	0F0H,0F8H,0F8H,0FEH,0FEH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FCH
        DB 	000H,000H,0FFH,0FEH,000H,000H,000H,000H,000H,001H,001H,003H,002H,006H,00CH,008H
        DB 	008H,019H,017H,007H,00FH,00FH,00FH,01FH,01FH,01FH,01FH,03FH,0DFH,04FH,027H,011H
        DB 	00CH,007H,001H,001H,000H,001H,003H,007H,00EH,018H,018H,070H,0C0H,0C0H,088H,0F8H
        DB 	0F8H,0F1H,0C0H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,080H,040H,0D8H
        DB 	0F4H,0F4H,0FCH,0F8H,0F8H,078H,0F8H,0F8H,0F8H,0F8H,0F8H,0F8H,0F8H,07CH,0F4H,0F4H
        DB 	0FEH,0FAH,0FDH,0FBH,0FFH,0FEH,0FCH,0FBH,0FEH,0FCH,0C8H,083H,023H,013H,053H,003H
        DB 	001H,081H,081H,001H,0C3H,083H,003H,007H,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,000H
        DB 	000H,080H,0FBH,08FH,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,008H,080H,000H,0F0H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,040H,000H,000H,000H,047H
        DB 	0FFH,0FFH,03FH,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,040H,0EFH,0BFH,0FFH
        DB 	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0F3H,077H,07FH,0FFH,0DFH,0FFH
        DB 	0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FEH,0FEH,03FH,0FFH,079H,0FEH,0FCH,03EH,03DH,0FCH
        DB 	07CH,066H,066H,046H,047H,0DFH,03FH,07FH,03EH,03FH,07FH,0FFH,0FFH,0FFH,0FFH,0F8H
        DB 	0C0H,01FH,07FH,0FDH,080H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,0FFH,000H,000H,0FEH
        DB 	080H,000H,000H,000H,000H,000H,000H,002H,004H,01CH,01CH,01CH,002H,002H,000H,080H
        DB 	0FDH,0E0H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

MAOFRAME1 DB 16, 8
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,002H,000H,004H,000H,000H,000H,000H,040H,040H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,020H,0F8H,0F8H,0F8H,0FCH,03EH,00EH,000H,000H,006H,086H,000H
        DB 	000H,000H,000H,086H,004H,000H,000H,010H,010H,0E0H,0E0H,002H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,0C1H,0C1H,0C1H,003H,000H,000H,000H,000H,008H,001H,000H
        DB 	000H,000H,000H,001H,004H,004H,000H,000H,000H,001H,001H,000H,030H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,001H,001H,001H,000H,000H,000H,000H,000H,000H,000H,010H
        DB 	010H,010H,00DH,00CH,00CH,002H,002H,000H,000H,000H,000H,0E3H,0C0H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,002H,012H,0F6H
        DB 	014H,008H,008H,008H,008H,000H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,000H,000H,000H
        DB 	000H,000H,0E0H,000H,010H,018H,018H,018H,0F0H,0E6H,0EFH,01EH,018H,0F0H,0F0H,0E4H
        DB 	0E4H,0ECH,0E4H,004H,006H,002H,002H,003H,003H,0E0H,0E0H,0F9H,0FFH,0FFH,0FCH,0F0H
        DB 	000H,0F0H,0F8H,0F8H,0F8H,0F0H,0E0H,0E0H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	0E0H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,080H,0C0H,0E0H,0E0H,0E0H,0E0H,080H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,010H,090H,098H,08CH,0C2H,0E1H
        DB 	0F0H,0F8H,0F8H,0FEH,0FEH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FCH
        DB 	000H,000H,0FFH,0FEH,000H,000H,000H,000H,000H,001H,001H,003H,002H,006H,00CH,008H
        DB 	008H,019H,017H,007H,00FH,00FH,00FH,01FH,01FH,01FH,01FH,03FH,0DFH,04FH,027H,011H
        DB 	00CH,007H,001H,001H,000H,001H,003H,007H,00EH,018H,018H,070H,0C0H,0C0H,088H,0F8H
        DB 	0F8H,0F1H,0C0H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,0C0H,0F0H,0F8H,078H,098H,098H,0D8H
        DB 	0D8H,0D8H,0DFH,0DEH,00FH,010H,03FH,03FH,06FH,078H,0E0H,0E0H,0E0H,0C0H,0C0H,080H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,0C0H,0F3H,0F3H,0F3H,0F3H,0F3H
        DB 	0F3H,0C3H,0C3H,0C3H,0C3H,083H,003H,007H,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,000H
        DB 	000H,080H,0FBH,08FH,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,008H,080H,000H,0F0H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,040H,000H,000H,000H,047H
        DB 	0FFH,0FFH,03FH,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,01CH,03FH,03BH,07BH,05BH,05BH,0DBH
        DB 	0DBH,0E3H,0E1H,0E0H,0E0H,0E0H,0C0H,0DEH,0DEH,0DEH,09CH,0FEH,0FFH,0FFH,0FFH,07FH
        DB 	067H,01BH,019H,038H,060H,0E0H,0C0H,084H,01FH,01FH,07FH,0FFH,0FFH,03FH,01FH,0C7H
        DB 	067H,067H,067H,047H,047H,0DFH,03FH,07FH,03EH,03FH,07FH,0FFH,0FFH,0FFH,0FFH,0F8H
        DB 	0C0H,01FH,07FH,0FDH,080H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,0FFH,000H,000H,0FEH
        DB 	080H,000H,000H,000H,000H,000H,000H,002H,004H,01CH,01CH,01CH,002H,002H,000H,080H
        DB 	0FDH,0E0H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

MAOFRAME2 DB 16, 8
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,0C0H,0E0H,0E0H,0C0H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,002H,000H,004H,000H,000H,000H,000H,040H,040H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,080H,080H,080H,0C0H,0E0H
        DB 	0FCH,0FFH,01FH,01FH,0FFH,0FEH,0F0H,0C0H,080H,080H,080H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,020H,0F8H,0F8H,0F8H,0FCH,03EH,00EH,000H,000H,006H,086H,000H
        DB 	000H,000H,000H,086H,004H,000H,000H,010H,010H,0E0H,0E0H,002H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,006H,00FH,00FH,00FH,01FH,01FH,01FH,03FH,039H,079H
        DB 	0F9H,0F0H,080H,080H,0F0H,0F9H,0F9H,039H,03FH,01FH,01FH,01FH,00FH,00FH,00FH,006H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,0C1H,0C1H,0C1H,003H,000H,000H,000H,000H,008H,001H,000H
        DB 	000H,000H,000H,001H,004H,004H,000H,000H,000H,001H,001H,000H,030H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,080H,080H,080H,080H,080H,080H,080H,000H,000H,000H,000H,000H
        DB 	007H,03FH,07FH,07FH,03FH,007H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,001H,001H,001H,000H,000H,000H,000H,000H,000H,000H,010H
        DB 	010H,010H,00DH,00CH,00CH,002H,002H,000H,000H,000H,000H,0E3H,0C0H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,03EH,0EFH,0FFH,0FFH,0FFH,0FFH,0FFH,0BFH,03EH,074H,0FCH,0F8H,070H
        DB 	0E0H,0E0H,0E0H,0E0H,0F8H,0BCH,0FCH,0FEH,0FEH,0FEH,0BEH,00EH,01EH,0FEH,0D8H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,002H,012H,0F6H
        DB 	014H,008H,008H,008H,008H,000H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,0E0H,000H,000H,000H
        DB 	000H,000H,0E0H,000H,010H,018H,018H,018H,0F0H,0E6H,0EFH,01EH,018H,0F0H,0F0H,0E4H
        DB 	0E4H,0ECH,0E4H,004H,006H,002H,002H,003H,003H,0E0H,0E0H,0F9H,0FFH,0FFH,0FCH,0F0H
        DB 	000H,0F0H,0F8H,0F8H,0F8H,0F0H,0E0H,0E0H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	0E0H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,007H,01FH,03FH,07FH,0FFH,0FFH,0FFH,0FCH,0F4H,0FBH,0DCH,019H
        DB 	0D9H,0ADH,0B9H,0EBH,06BH,073H,053H,07FH,075H,062H,06FH,0FBH,0F9H,0FFH,0FFH,0E3H
        DB 	080H,080H,080H,000H,000H,000H,000H,000H,000H,000H,010H,090H,098H,08CH,0C2H,0E1H
        DB 	0F0H,0F8H,0F8H,0FEH,0FEH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FCH
        DB 	000H,000H,0FFH,0FEH,000H,000H,000H,000H,000H,001H,001H,003H,002H,006H,00CH,008H
        DB 	008H,019H,017H,007H,00FH,00FH,00FH,01FH,01FH,01FH,01FH,03FH,0DFH,04FH,027H,011H
        DB 	00CH,007H,001H,001H,000H,001H,003H,007H,00EH,018H,018H,070H,0C0H,0C0H,088H,0F8H
        DB 	0F8H,0F1H,0C0H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,001H,003H,004H,00FH,01FH,017H,01FH,03FH
        DB 	07FH,0FFH,0FDH,0E9H,0F9H,0F7H,0FFH,0FEH,0EEH,0FEH,0FCH,0A9H,07FH,0FFH,0F9H,0FDH
        DB 	0FBH,0EBH,0FFH,0FFH,0FFH,0FCH,0FCH,0EBH,07EH,0DCH,0F8H,0F3H,073H,073H,0F3H,0F3H
        DB 	0F3H,0C3H,0C3H,0C3H,0C3H,083H,003H,007H,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,000H
        DB 	000H,080H,0FBH,08FH,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,008H,080H,000H,0F0H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,040H,000H,000H,000H,047H
        DB 	0FFH,0FFH,03FH,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,003H,00EH,00EH,01EH,03FH,07FH,079H,0FDH,0FEH,0FEH,0FEH,0F7H
        DB 	0FFH,0EFH,0DFH,077H,077H,0FFH,0DBH,0BFH,03FH,01FH,079H,0FFH,0FDH,03CH,01DH,0C5H
        DB 	067H,067H,067H,047H,047H,0DFH,03FH,07FH,03EH,03FH,07FH,0FFH,0FFH,0FFH,0FFH,0F8H
        DB 	0C0H,01FH,07FH,0FDH,080H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H
        DB 	000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,0FFH,000H,000H,0FEH
        DB 	080H,000H,000H,000H,000H,000H,000H,002H,004H,01CH,01CH,01CH,002H,002H,000H,080H
        DB 	0FDH,0E0H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H,000H

.STACK

MINHA_PILHA DW 128 DUP(?)

          END
