###############################################################################
# Makefile for project 
###############################################################################

## General options
PROJECT = 
MCU = 8086
COMPILER = "MASM32"
TARGET = Debug
SHELL = C:\Windows\system32\cmd.exe

## Tools general options
ASMFLAGS=/c /Zd /Zi
LDFLAGS=/CODEVIEW

## Processing Tools
ASM=ml.exe
LD=link16.exe
#  C:/Users/tbboeing/Desktop/principios-arquitetura-computadores-ii/GRAFICO_8086/GRAFICO_8086/8086/Debug/Debug.exe: TOOL=LD
#     C:/Users/tbboeing/Desktop/principios-arquitetura-computadores-ii/GRAFICO_8086/GRAFICO_8086/8086/Debug/animacao.obj: TOOL=ASM
#        C:/Users/tbboeing/Desktop/principios-arquitetura-computadores-ii/GRAFICO_8086/GRAFICO_8086/8086/animacao.asm

# Build tree:
all:	Debug

Debug:	Debug.exe

Debug.exe:	animacao.obj 
	$(LD) $(LDFLAGS) animacao.obj,Debug.exe,nul.map,,,

animacao.obj:	../animacao.asm 
	$(ASM) $(ASMFLAGS) ../animacao.asm

# tidy - delete all temporary files which are not involved in the target generation
tidy:

# cleanup - delete all generated files
clean:	tidy
	rm -rf Debug.exe
	rm -rf animacao.obj
