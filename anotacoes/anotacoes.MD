### 21/05/2019

Based relative: utiliza registradores BX, BP
Indexed relative: utiliza registradores SI, DI
IF: interrupt flag (deve estar aceso para atender interrupções)

Forçar interrupção: `int 8`

# Controladora 8259

### 14/05/2019 

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
