### 28/05/2019

- TEXT DB 13,0 - pula linha (13,0)
- TXT1 28 DUP " " - repete caracter 28 vezes
- REPE - repeat
- CMPSB - compare string bite
- JE - for igual
- JNE - não for igual

#### Desafio

Receber duas strings e comparar, informar se são iguais ou diferentes.

### 21/05/2019

Based relative: utiliza registradores BX, BP
Indexed relative: utiliza registradores SI, DI
IF: interrupt flag (deve estar aceso para atender interrupções)
Forçar interrupção: `int 8`

### 14/05/2019 

#### Controladora 8259

---

- NNI: Gerenciador de interrupções
- IRQ: Interrupt request
- PIQ: Pheripheral interrupt controller
- STI: Standart init
  
Para uma interrupção não 'interromper' a outra, basta adicionar:
CLI (no começo da interrupção) e STI (no fim da interrupção).

> CLI: clear interrupt

#### ID
- 60H = IRQ0
- 61H = IRQ1
- 62H = IRQ2...

Ao receber o IRQ o processador multiplicará por 4 em HEX.

-----

> Proteus versão 8.3
